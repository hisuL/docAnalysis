# Document Ingestion API 设计

## 1. 目标与范围

`document-ingestion` 对外只提供四类能力：
- 上传 PDF 并创建文档记录
- 查询文档处理状态
- 获取 PDF 预览与引用定位元数据
- 取消未完成的处理任务

本模块不负责问答、摘要生成、推荐问题和反馈记录。

## 2. 设计原则

- 单文档隔离：所有接口都以 `doc_id` 为主键，不暴露跨文档批量能力。
- 快速返回：上传接口只负责落原始文件和创建任务，重处理异步完成。
- 状态稳定：前端只依赖稳定状态和值得展示的错误摘要，不感知内部实现细节。
- 预览先行：原始 PDF 上传成功后即可预览，不要求等解析完成。
- 可取消：只有非终态文档允许取消，取消结果通过状态接口收敛。

## 3. 状态模型

### 3.1 文档状态

| 状态 | 含义 | 前端表现 | 是否允许问答 |
| --- | --- | --- | --- |
| `uploaded` | 原始文件已保存，等待 worker 开始处理 | 显示“上传完成” | No |
| `parsing` | 正在解析 PDF 为 Markdown 与页面索引 | 步骤条高亮“文档解析中” | No |
| `chunking` | 正在按标题或 token 规则切片 | 步骤条高亮“智能切片中” | No |
| `indexing` | 正在生成并写入 embedding | 步骤条高亮“向量索引构建中” | No |
| `ready` | 文档可检索，预览与问答都可使用 | 展示“文档就绪”横幅 | Yes |
| `failed` | 处理失败或超时 | 展示失败原因与重传入口 | No |
| `cancelling` | 已发起取消，等待 worker 收敛 | 显示“取消处理中” | No |
| `cancelled` | 处理已终止 | 回到可重新上传状态 | No |

### 3.2 失败原因枚举

| code | 含义 | 用户提示建议 |
| --- | --- | --- |
| `invalid_file_type` | 文件不是 PDF | 仅支持 PDF 格式文件 |
| `file_too_large` | 文件超过 100MB | 文件大小超过 100MB 限制 |
| `file_corrupted` | PDF 文件损坏 | 文件损坏，请重新上传 |
| `pdf_encrypted` | PDF 被加密，无法提取文本 | 文件已加密，无法提取文本内容 |
| `parse_timeout` | 解析链路超过 5 分钟 | 文档处理超时，请稍后重试 |
| `parse_error` | 解析器异常 | 文档解析失败 |
| `embedding_error` | 向量化失败 | 向量索引构建失败 |
| `cancelled_by_user` | 用户主动取消 | 已取消处理 |

## 4. API 列表

| 接口名称 | 方法 | 路径 | 说明 |
| --- | --- | --- | --- |
| 上传文档 | `POST` | `/api/v1/documents` | 上传 PDF，返回 `doc_id` 与初始状态 |
| 查询文档状态 | `GET` | `/api/v1/documents/{doc_id}` | 返回状态、进度、失败摘要和统计 |
| 获取预览元数据 | `GET` | `/api/v1/documents/{doc_id}/preview` | 返回 PDF 下载地址、页数和定位元数据 |
| 取消处理任务 | `POST` | `/api/v1/documents/{doc_id}/cancel` | 发起取消未完成处理任务 |

## 5. 接口详细设计

### 5.1 上传文档

- 方法：`POST /api/v1/documents`
- Content-Type：`multipart/form-data`

请求字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `file` | file | Yes | 单个 PDF 文件 |
| `client_request_id` | string | No | 幂等键，避免前端重复点击重复创建 |

处理规则：
- 入口先校验 MIME、扩展名和文件大小。
- 文件先写入 SeaweedFS，再创建 `documents` 与 `document_assets` 记录。
- 创建 `ingestion_jobs` 后立即返回，不同步等待解析完成。

成功响应示例：

```json
{
  "doc_id": "doc_01JPCY8JFK1VH8M8G6D2M7QAZH",
  "file_name": "XYZ_Datasheet_v2.0.pdf",
  "status": "uploaded",
  "status_message": "上传完成，等待解析",
  "file_size_bytes": 47395612,
  "page_count": null,
  "created_at": "2026-03-18T09:40:12Z"
}
```

错误响应：
- `400`：格式错误、缺少文件
- `413`：超过 100MB
- `409`：同一 `client_request_id` 幂等冲突

### 5.2 查询文档状态

- 方法：`GET /api/v1/documents/{doc_id}`

响应字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `doc_id` | string | 文档主键 |
| `file_name` | string | 原始文件名 |
| `status` | string | 当前处理状态 |
| `status_message` | string | 面向前端展示的状态文案 |
| `progress_percent` | integer | 0-100，便于步骤条与进度条显示 |
| `page_count` | integer/null | 成功解析后返回页数 |
| `chunk_count` | integer/null | 切片完成后返回切片数量 |
| `elapsed_seconds` | integer | 从创建到当前的耗时 |
| `error_code` | string/null | 失败码 |
| `error_message` | string/null | 稳定失败摘要 |
| `can_cancel` | boolean | 是否允许取消 |
| `preview_ready` | boolean | 原始 PDF 是否可预览 |
| `updated_at` | datetime | 最后更新时间 |

响应示例：

```json
{
  "doc_id": "doc_01JPCY8JFK1VH8M8G6D2M7QAZH",
  "file_name": "XYZ_Datasheet_v2.0.pdf",
  "status": "chunking",
  "status_message": "智能切片中",
  "progress_percent": 62,
  "page_count": 128,
  "chunk_count": null,
  "elapsed_seconds": 54,
  "error_code": null,
  "error_message": null,
  "can_cancel": true,
  "preview_ready": true,
  "updated_at": "2026-03-18T09:41:06Z"
}
```

### 5.3 获取预览元数据

- 方法：`GET /api/v1/documents/{doc_id}/preview`

用途：
- 支持右侧 PDF 预览区提前加载原始 PDF。
- 支持问答引用跳转时按页码与段落锚点定位。

响应字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `doc_id` | string | 文档主键 |
| `pdf_url` | string | SeaweedFS 预签名读取地址 |
| `file_name` | string | 原始文件名 |
| `page_count` | integer/null | 页数 |
| `preview_status` | string | `available` / `unavailable` |
| `anchors` | array | 已解析的页面锚点列表 |

`anchors` 元素示例：

```json
{
  "anchor_id": "anc_00125",
  "page_num": 37,
  "title_path": ["Electrical Characteristics", "Absolute Maximum Ratings"],
  "text_excerpt": "VDD voltage should not exceed 3.6V",
  "bbox": null
}
```

设计说明：
- 解析未完成前允许返回 `pdf_url`，但 `anchors` 可为空数组。
- `bbox` 在当前版本可为空，前端至少可按页级跳转。

### 5.4 取消处理任务

- 方法：`POST /api/v1/documents/{doc_id}/cancel`

处理规则：
- 仅 `uploaded/parsing/chunking/indexing` 允许取消。
- 调用后立即把 `documents.status` 改为 `cancelling`，并给对应 job 打取消标记。
- worker 在阶段边界检查到取消标记后终止执行并收敛为 `cancelled`。

成功响应示例：

```json
{
  "doc_id": "doc_01JPCY8JFK1VH8M8G6D2M7QAZH",
  "status": "cancelling",
  "status_message": "取消处理中"
}
```

错误响应：
- `409`：当前已是终态，不能取消
- `404`：文档不存在

## 6. 对外契约约束

- `conversation-orchestrator` 不直接调用本模块 HTTP API 拉取 chunks，统一复用数据库只读边界或内部仓储层。
- 对前端暴露的 `status_message` 只使用稳定文案，不回传内部栈信息。
- `doc_id` 使用 ULID/雪花类全局唯一 ID，便于排序与日志追踪。

## 7. 幂等与一致性

- 上传接口通过 `client_request_id` 防止前端重试重复创建文档。
- 状态推进必须单向前进，只有取消流程允许从处理中转入 `cancelling/cancelled`。
- `ready` 只能在 chunk 与 embedding 全部成功写入后落库。
- `failed` 与 `cancelled` 属于终态，不允许再次流转到处理中。

## 8. 安全与校验

- 仅允许 `application/pdf` 与 `.pdf` 后缀同时满足的文件进入处理链路。
- 读取预览地址采用短时效预签名 URL，避免对象存储桶被直接暴露。
- 文件名只用于展示，不作为对象存储主键。

## 9. 监控字段建议

为支持后续排障，状态接口背后应保留以下内部指标：
- `parse_started_at`
- `parse_finished_at`
- `embedding_started_at`
- `embedding_finished_at`
- `last_error_stage`
- `retry_count`

这些字段不必全部直接暴露给前端，但应作为数据库与日志的一部分。
