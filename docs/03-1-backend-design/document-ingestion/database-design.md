# Document Ingestion 数据库设计

## 1. 目标

数据库层负责承载 `document-ingestion` 的四类主数据：
- 文档主记录与状态机
- 文档衍生产物与对象存储引用
- 异步处理任务
- 切片文本、引用元数据与向量

设计目标是让上传、处理、取消、预览和下游检索可以围绕同一个 `doc_id` 稳定工作。

## 2. 设计原则

- 单文档为根：所有业务表都围绕 `doc_id` 组织。
- 主数据和执行数据分离：`documents` 承载用户可见状态，`ingestion_jobs` 承载 worker 执行细节。
- 结果可追溯：原始 PDF、Markdown、图片索引和 chunk 元数据都可按 `doc_id` 找回。
- 面向检索：`document_chunks` 直接承载 pgvector 列，避免额外 join 才能检索。
- 终态稳定：`ready`、`failed`、`cancelled` 都是终态，便于对外呈现。

## 3. 实体关系

```text
documents (1) ---- (n) document_assets
documents (1) ---- (n) ingestion_jobs
documents (1) ---- (n) document_chunks
```

说明：
- 一个文档可以有多个资产记录，例如原始 PDF、Markdown、图片索引。
- 一个文档可能会有多次处理任务，但同一时间只允许一个 `active` 任务。
- 一个文档会拆成多个切片，每个切片都带页码和章节路径。

## 4. 表设计

### 4.1 `documents`

职责：
- 记录用户看到的文档基础信息和状态。
- 提供状态查询接口的主要数据来源。

关键字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | varchar(32) | 文档主键，建议 ULID |
| `file_name` | varchar(255) | 原始文件名 |
| `content_type` | varchar(64) | 固定为 `application/pdf` |
| `file_size_bytes` | bigint | 文件大小 |
| `status` | varchar(32) | 文档状态枚举 |
| `status_message` | varchar(128) | 前端稳定展示文案 |
| `page_count` | integer | 成功解析后页数 |
| `chunk_count` | integer | 成功切片后数量 |
| `progress_percent` | integer | 处理进度 |
| `error_code` | varchar(64) | 失败码 |
| `error_message` | varchar(255) | 失败摘要 |
| `preview_ready` | boolean | 原始 PDF 是否可预览 |
| `cancel_requested_at` | timestamptz | 用户发起取消时间 |
| `ready_at` | timestamptz | 可检索时间 |
| `created_at` | timestamptz | 创建时间 |
| `updated_at` | timestamptz | 更新时间 |

约束：
- `status` 仅允许设计文档中定义的八个状态。
- `progress_percent` 取值 0-100。
- `ready_at` 只在 `ready` 状态有值。

索引建议：
- `idx_documents_status_updated_at(status, updated_at desc)` 用于轮询和后台治理。
- `uk_documents_file_name_created_at` 不需要，避免同名文件被误判重复。

### 4.2 `document_assets`

职责：
- 记录原始 PDF、Markdown、图片索引等对象存储引用。
- 让预览、排障和二次处理都能按类型找到对应产物。

关键字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigserial | 主键 |
| `doc_id` | varchar(32) | 关联 `documents.id` |
| `asset_type` | varchar(32) | `source_pdf` / `markdown` / `image_manifest` |
| `storage_bucket` | varchar(64) | SeaweedFS bucket |
| `storage_key` | varchar(255) | 对象键 |
| `content_sha256` | varchar(64) | 内容摘要 |
| `byte_size` | bigint | 对象大小 |
| `metadata_json` | jsonb | 页数、图片数量、提取参数等 |
| `created_at` | timestamptz | 创建时间 |

约束：
- `doc_id + asset_type` 唯一，确保单文档单类型只有一个最新资产记录。

### 4.3 `ingestion_jobs`

职责：
- 描述一次完整的异步处理执行。
- 支持 worker 锁定、重试、取消和超时回收。

关键字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | varchar(32) | 任务主键 |
| `doc_id` | varchar(32) | 关联文档 |
| `job_type` | varchar(32) | 当前固定为 `ingest_document` |
| `status` | varchar(32) | `pending/running/succeeded/failed/cancel_requested/cancelled` |
| `current_stage` | varchar(32) | `upload_ack/parsing/chunking/indexing/finalizing` |
| `attempt` | integer | 当前重试次数 |
| `max_attempts` | integer | 默认 3 |
| `cancel_requested` | boolean | 是否已请求取消 |
| `locked_by` | varchar(64) | worker 实例标识 |
| `locked_at` | timestamptz | 锁定时间 |
| `started_at` | timestamptz | 开始时间 |
| `finished_at` | timestamptz | 完成时间 |
| `deadline_at` | timestamptz | 超时时间，创建后固定为 `created_at + 5 min` |
| `last_error_code` | varchar(64) | 最近错误码 |
| `last_error_message` | text | 最近错误详情 |
| `stage_payload_json` | jsonb | 当前阶段参数和统计 |
| `created_at` | timestamptz | 创建时间 |
| `updated_at` | timestamptz | 更新时间 |

约束：
- 同一 `doc_id` 同时只允许一个 `pending/running/cancel_requested` 任务。
- `deadline_at` 不能为空，用于统一超时治理。

### 4.4 `document_chunks`

职责：
- 存储切片文本、章节路径、页码和向量。
- 作为 `conversation-orchestrator` 检索的只读真相源。

关键字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | varchar(40) | chunk 主键 |
| `doc_id` | varchar(32) | 文档主键 |
| `chunk_seq` | integer | 文档内顺序号 |
| `page_num` | integer | 起始页码 |
| `page_num_end` | integer | 结束页码，默认与起始页相同 |
| `title_path` | jsonb | 标题路径数组 |
| `chunk_text` | text | 检索正文 |
| `token_count` | integer | token 数 |
| `chunk_strategy` | varchar(32) | `markdown_header` / `token_fallback` |
| `anchor_id` | varchar(40) | 引用锚点 ID |
| `anchor_excerpt` | varchar(255) | 预览摘要 |
| `anchor_bbox_json` | jsonb | 高亮框，当前可为空 |
| `embedding` | vector(1024) | embedding 向量 |
| `embedding_model` | varchar(64) | 使用的 embedding 模型 |
| `created_at` | timestamptz | 创建时间 |

约束：
- `doc_id + chunk_seq` 唯一。
- `token_count > 0`。
- `chunk_text` 不允许空串。

索引建议：
- `idx_document_chunks_doc_page(doc_id, page_num, chunk_seq)`
- `idx_document_chunks_doc_anchor(doc_id, anchor_id)`
- `ivfflat` 或 `hnsw` 向量索引，按 `embedding` 构建。

## 5. 状态与数据一致性规则

- 创建文档时先写 `documents`，再写 `document_assets(source_pdf)` 与 `ingestion_jobs`。
- 进入 `ready` 前必须保证：
  - `document_assets` 至少存在 `source_pdf` 和 `markdown`
  - `document_chunks` 已批量写入完成
  - `documents.chunk_count` 与 `document_chunks` 实际数量一致
- 任一阶段失败时：
  - `documents.status = failed`
  - `documents.error_code/error_message` 更新
  - `ingestion_jobs.status = failed`
- 用户取消时：
  - `documents.status` 先置为 `cancelling`
  - worker 收敛后改为 `cancelled`
  - 若已落入 `document_chunks` 的中间数据，可在同事务或补偿任务中按 `doc_id` 清理

## 6. 分表与扩展考虑

- 当前仅单模块、单文档场景，不需要按租户或业务线分表。
- 若未来支持多文档或大规模吞吐，可考虑：
  - `document_chunks` 按 `doc_id hash` 分区
  - `documents` 增加业务租户字段
  - 将 `embedding` 拆到独立向量表

## 7. 与外部依赖的映射

- SeaweedFS 对象地址不直接暴露，数据库只记录 bucket/key，由应用层换取预签名 URL。
- `conversation-orchestrator` 只读取 `document_chunks` 与 `documents.ready` 状态，不回写本模块主数据。
- 图片占位符和图片索引先存为 `image_manifest` 资产，供未来高亮或富预览增强。
