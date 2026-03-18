# Document Ingestion 中间件通信设计

## 1. 目标

本模块的“中间件通信”重点不是新增独立 MQ 服务，而是定义上传后到可检索之间的异步处理编排、阶段事件、取消机制和外部依赖调用约定。

MVP 方案采用：
- FastAPI 对外 API 面
- 服务内 worker 执行面
- PostgreSQL `ingestion_jobs` 作为任务队列与状态协调介质
- SeaweedFS、litellm、Haystack 作为外部依赖

## 2. 为什么不引入独立消息队列

- 当前只有单条核心链路：上传后异步处理。
- 架构层已明确 worker 属于服务内部执行形态，不额外拆微服务。
- 使用数据库任务表即可满足 5 分钟内单文档处理、取消和重试需求。
- 减少基础设施数量，符合 MVP 落地目标。

因此，本版把“消息”定义为数据库状态事件和内部阶段命令，而不是外部 MQ Topic。

## 3. 核心处理流水线

```text
HTTP Upload API
  -> persist source_pdf asset
  -> create documents(status=uploaded)
  -> create ingestion_jobs(status=pending)
  -> worker claim job
  -> parsing
  -> chunking
  -> indexing
  -> finalizing ready
```

每个阶段都必须：
- 更新 `documents.status`
- 更新 `ingestion_jobs.current_stage`
- 检查 `cancel_requested`
- 记录阶段耗时和错误

## 4. 内部命令与事件

### 4.1 命令

| 命令名 | 触发方 | 消费方 | 作用 |
| --- | --- | --- | --- |
| `document.ingestion.requested` | 上传 API | worker | 表示有新文档需要处理 |
| `document.ingestion.cancel.requested` | 取消 API | worker | 表示需要在安全阶段边界取消当前文档 |
| `document.ingestion.retry.requested` | 后台治理任务 | worker | 用于失败后人工或自动重试 |

### 4.2 事件

| 事件名 | 产生时机 | 主要字段 | 作用 |
| --- | --- | --- | --- |
| `document.uploaded` | 原始 PDF 写入完成 | `doc_id`, `asset_key` | 标识文档已进入处理链路 |
| `document.parsing.started` | worker 开始解析 | `doc_id`, `job_id` | 进入解析阶段 |
| `document.parsing.completed` | Markdown 和页数已生成 | `doc_id`, `page_count` | 进入切片前置条件满足 |
| `document.chunking.completed` | chunk 已写入暂存结果 | `doc_id`, `chunk_count` | 进入向量化阶段 |
| `document.indexing.completed` | embedding 已写入 | `doc_id`, `chunk_count` | 可进入 ready |
| `document.ready` | 文档全部稳定 | `doc_id`, `ready_at` | 下游可检索 |
| `document.failed` | 任一阶段失败 | `doc_id`, `stage`, `error_code` | 前端和治理任务感知失败 |
| `document.cancelled` | 取消收敛完成 | `doc_id`, `stage` | 前端感知终止 |

说明：
- 这些事件当前落在数据库状态迁移和应用日志中，不要求接入外部事件总线。
- 若后续要接 observability 或异步通知，可直接把这些事件映射到 MQ 或 CDC。

## 5. Worker 执行模型

### 5.1 任务认领

- worker 通过 `SELECT ... FOR UPDATE SKIP LOCKED` 抢占 `pending` 任务。
- 抢到后写入 `locked_by`、`locked_at`，并将任务置为 `running`。
- 同时将 `documents.status` 从 `uploaded` 推进到 `parsing`。

### 5.2 阶段边界

| 阶段 | 输入 | 输出 | 失败处理 |
| --- | --- | --- | --- |
| `parsing` | 原始 PDF | Markdown、页数、图片索引 | 更新 `failed` 并落错误码 |
| `chunking` | Markdown | chunk 文本、页码、标题路径、锚点 | 清理未完成 chunk 后失败 |
| `indexing` | chunk 文本 | embedding 向量 | 标记失败，保留排障信息 |
| `finalizing` | chunk + embedding | `ready` 状态与统计回填 | 若更新失败整体回滚到 `failed` |

### 5.3 取消机制

- API 层收到取消请求后，将 `ingestion_jobs.cancel_requested=true`。
- worker 在阶段切换点和批处理循环中检查取消标记。
- 若已请求取消：
  - 停止后续阶段调用
  - 清理未完成中间结果
  - 将 `documents.status` 置为 `cancelled`
  - 将 `ingestion_jobs.status` 置为 `cancelled`

### 5.4 超时机制

- `deadline_at = created_at + 5 minutes`
- worker 每次进入新阶段前校验当前时间是否超时。
- 超时后统一写 `parse_timeout`，并收敛为 `failed`。

## 6. 外部依赖调用设计

### 6.1 SeaweedFS

用途：
- 写入原始 PDF
- 可选写入 Markdown 和图片索引 JSON

约束：
- 对象 key 采用 `documents/{doc_id}/...` 结构，避免同名冲突。
- 上传成功后才允许创建文档主记录。
- 读取时通过应用层生成短期预签名 URL。

### 6.2 Haystack

用途：
- 组织解析、清洗、切片和 embedding 流程。

约束：
- 解析阶段需要保留 Markdown 标题层级信息。
- 切片阶段优先使用 Markdown 标题切分，失败时回退 token 策略。
- 必须过滤空切片、纯页眉页脚切片。

### 6.3 litellm embedding

用途：
- 对 chunk 批量向量化。

约束：
- 批量大小应可配置，避免长文档一次请求过大。
- 失败时按批次重试，不允许跳过部分 chunk 直接进入 `ready`。

## 7. 对下游的交付边界

`conversation-orchestrator` 依赖本模块的最终稳定结果：
- `documents.status = ready`
- `document_chunks` 中完整的 `chunk_text`
- `title_path`、`page_num`、`anchor_id`、`anchor_excerpt`
- `embedding`

下游不应感知：
- 解析器选型细节
- worker 重试细节
- 图片提取中间结果

## 8. 日志与观测建议

每个任务至少记录以下日志字段：
- `trace_id`
- `doc_id`
- `job_id`
- `stage`
- `attempt`
- `elapsed_ms`
- `error_code`

核心指标建议：
- 文档处理总耗时
- 各阶段耗时分布
- 成功率 / 失败率 / 取消率
- 平均 chunk 数
- embedding 批处理失败率

## 9. 演进路径

若后续吞吐明显上升，可在不改外部 API 的前提下演进为：
- `ingestion_jobs` 继续作为真相源
- 新增 Redis / MQ 作为分发层
- worker 水平扩展

当前版本先保持数据库任务队列方案，成本最低且足够支撑单文档 MVP。
