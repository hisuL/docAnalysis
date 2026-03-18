---
version: 1.0.0
status: draft
module: document-ingestion
module_dir: docs/03-1-backend-design/document-ingestion
stage_dir: docs/03-1-backend-design
role: backend
source_inputs:
  - docs/01-prd/PRD.md
  - docs/01-prd/research.md
  - docs/01-prd/ChatFile_interactive.md
  - docs/02-architecture/architecture-design.md
  - docs/02-architecture/system-boundaries.md
  - docs/02-architecture/integration-flows.md
  - docs/03-1-backend-design/document-ingestion/AGENTS.md
change_log:
  - version: 1.0.0
    date: 2026-03-18
    changes: initial version
---

# Design Plan

## 1. Module Scope / 模块范围
- module_id: `document-ingestion`
- module_dir: `docs/03-1-backend-design/document-ingestion`
- role: `backend`
- goal:
  - 为单 PDF 上传、解析、切片、向量化和预览定位提供稳定后端能力。
  - 产出后续可同步到 YAPI、SQL、PingCode 的模块级设计成果。
- out_of_scope:
  - 问答生成、会话管理、摘要与推荐问题生成
  - 系统级架构重定义
  - 前端页面和交互实现

## 2. Target Artifact Skeleton / 目标产物骨架
```text
docs/03-1-backend-design/document-ingestion/
  AGENTS.md
  _planning/
    design-plan.md
  api-design.md
  api-index.md
  database-design.md
  middleware-design.md
  story.md
  sql/
    documents.sql
    document_assets.sql
    ingestion_jobs.sql
    document_chunks.sql
```

## 3. Source Inputs / 输入材料
| Source | Type | Why It Matters |
| --- | --- | --- |
| `docs/01-prd/PRD.md` | product | 定义单文档、5 分钟超时、严格按 `doc_id` 隔离、上传到就绪状态流转等硬约束 |
| `docs/01-prd/research.md` | research | 提供 FastAPI、Haystack、SeaweedFS、PostgreSQL/pgvector、litellm 等技术方向 |
| `docs/01-prd/ChatFile_interactive.md` | interaction | 补充上传进度、处理步骤、取消处理、失败展示、预览并行加载等后端状态语义 |
| `docs/02-architecture/architecture-design.md` | architecture | 明确本模块是独立后端服务边界，负责上传、状态查询、预览元数据、取消处理 |
| `docs/02-architecture/system-boundaries.md` | architecture | 明确本模块拥有原始 PDF、处理状态、解析产物、chunk 元数据、embeddings 等主数据 |
| `docs/02-architecture/integration-flows.md` | architecture | 明确上传异步处理、ready 前禁止问答、处理失败和超时路径 |
| `docs/03-1-backend-design/document-ingestion/AGENTS.md` | local-rule | 约束当前目录产物职责、固定文件集合、YAPI/PingCode 配置和工作边界 |

## 4. Artifact File Map / 文件映射
| File | Type | Responsibility | Must Create If Missing | Must Fill If Empty | Truth Source | In Scope |
| --- | --- | --- | --- | --- | --- | --- |
| `api-design.md` | design-doc | 定义上传、状态查询、预览元数据、取消处理 API 契约与状态语义 | Yes | Yes | PRD + architecture + interaction | Yes |
| `api-index.md` | sync-artifact | 提供 YAPI 导入所需的稳定接口结果索引 | Yes | Yes | `api-design.md` | Yes |
| `database-design.md` | design-doc | 定义文档、产物、任务、切片等主数据模型与一致性规则 | Yes | Yes | PRD + architecture + research | Yes |
| `middleware-design.md` | design-doc | 定义上传后异步处理、状态事件、取消机制、外部依赖调用 | Yes | Yes | integration flows + research | Yes |
| `story.md` | sync-artifact | 收敛模块级用户故事，供后续导入 PingCode | Yes | Yes | 全部过程设计文档 | Yes |
| `sql/documents.sql` | executable-artifact | 创建文档主表，承载文档状态、基础信息和预览就绪标记 | Yes | Yes | `database-design.md` | Yes |
| `sql/document_assets.sql` | executable-artifact | 创建文档衍生产物表，记录原始 PDF、Markdown、图片索引等对象存储引用 | Yes | Yes | `database-design.md` | Yes |
| `sql/ingestion_jobs.sql` | executable-artifact | 创建处理任务表，支持异步执行、重试、取消和超时控制 | Yes | Yes | `database-design.md` + `middleware-design.md` | Yes |
| `sql/document_chunks.sql` | executable-artifact | 创建切片与向量表，承载检索所需文本、元数据和 embedding | Yes | Yes | `database-design.md` | Yes |

## 5. Constraints Summary / 约束摘要
### 5.1 Product Constraints / 产品约束
- 仅支持单个文本型 PDF，文件大小不超过 100MB。
- 上传后状态需支持 `上传中 -> 解析中 -> 切片中 -> 就绪` 的用户可感知流转。
- 单文档处理总时限 5 分钟，超时必须失败。
- 预览区可在处理期间提前加载原始 PDF。
- 需要支持取消上传后的处理任务。

### 5.2 Architecture Constraints / 架构约束
- `document-ingestion` 只负责上传、文档处理、状态管理、预览元数据和取消处理。
- 问答、摘要、推荐问题和反馈属于 `conversation-orchestrator`，本模块不拥有其主数据。
- 输出给下游的边界是当前 `doc_id` 下的稳定 chunk、embedding 和引用定位元数据。

### 5.3 Dependency Constraints / 依赖约束
- 对象存储使用 SeaweedFS，采用 S3 兼容协议。
- 关系库和向量库存储统一使用 PostgreSQL + pgvector。
- RAG 处理链路依赖 Haystack 组织解析、切片和 embedding 流程。
- embedding 模型通过 litellm 访问本地模型服务。

### 5.4 Delivery Constraints / 交付约束
- `api-index.md` 必须是 YAPI 导入索引，不混入过程设计。
- `story.md` 必须按 PingCode 导入模板输出。
- `sql/*.sql` 一张表一个文件，只保留可执行 DDL。

## 6. Design Decisions / 设计决策
| Topic | Recommendation | Why | Affected Files |
| --- | --- | --- | --- |
| 上传模型 | 使用单次 multipart 上传 API，由服务端写入 SeaweedFS 后立即创建文档记录 | MVP 最简单，避免前端直传与预签名复杂度 | `api-design.md`, `database-design.md`, `sql/documents.sql`, `sql/document_assets.sql` |
| 处理编排 | 采用服务内 API + Worker 形态，基于 `ingestion_jobs` 表轮询执行 | 架构层已约束 worker 属于内部执行形态，且无需新增 MQ 基础设施 | `middleware-design.md`, `database-design.md`, `sql/ingestion_jobs.sql` |
| 文档状态 | 统一为 `uploaded / parsing / chunking / indexing / ready / failed / cancelling / cancelled` | 可映射前端步骤条，同时覆盖取消和异常路径 | `api-design.md`, `database-design.md`, `middleware-design.md`, `sql/documents.sql` |
| 产物存储 | 原始 PDF、Markdown、图片索引统一记录在 `document_assets` | 降低 `documents` 表冗余，并给预览与追溯留扩展位 | `database-design.md`, `sql/document_assets.sql` |
| 切片模型 | 优先按 Markdown Header 切片，失败时回退到 512 tokens + 50 overlap | 直接对应 PRD 约束，且利于引用按章节溯源 | `middleware-design.md`, `database-design.md`, `sql/document_chunks.sql` |
| 取消策略 | 只允许取消非终态文档，worker 在阶段边界检查取消标记 | 保证取消可见且实现复杂度可控 | `api-design.md`, `middleware-design.md`, `sql/ingestion_jobs.sql` |

## 7. Dependencies And Handoffs / 依赖与交接
| Dependency | Direction | Owner | Purpose | Impacted Files |
| --- | --- | --- | --- | --- |
| SeaweedFS | outbound | `document-ingestion` | 存储原始 PDF、Markdown 和图片资源 | `database-design.md`, `middleware-design.md`, `sql/document_assets.sql` |
| PostgreSQL/pgvector | outbound | `document-ingestion` | 存储文档主数据、任务、切片和向量 | `database-design.md`, `sql/*.sql` |
| litellm embedding | outbound | `document-ingestion` | 生成 chunk embedding | `middleware-design.md`, `database-design.md` |
| `conversation-orchestrator` | downstream consumer | `conversation-orchestrator` | 消费 `ready` 文档的 chunk 与引用元数据 | `api-design.md`, `database-design.md` |
| YAPI | sync target | 设计阶段外部系统 | 导入稳定 API 索引 | `api-index.md` |
| PingCode | sync target | 设计阶段外部系统 | 导入故事清单 | `story.md` |

## 8. Sync Artifact Prerequisites / 同步产物前置条件
- `api-index.md`:
  - 只有上传、状态查询、预览、取消四类接口的路径、方法、版本和职责稳定后才生成。
- `story.md`:
  - 只有 API、数据库和中间件边界稳定后才生成，避免故事反复拆分。
- `sql/*.sql`:
  - 只有数据库设计确定状态机、主键、唯一约束和向量字段后才生成。

## 9. Sync Artifact Template Requirements / 同步产物模板约束
来源规则：`/home/dministrator/.codex/skills/technical-design-writer/references/sync-artifact-rules.md`

- `api-index.md`:
  - template_path: `/home/dministrator/.codex/skills/technical-design-writer/references/api-index-template.md`
  - title: `# API Index`
  - required_columns:
    - `接口名称`
    - `当前版本`
    - `接口描述（不超过 30 字）`
    - `YAPI 接口地址`
    - `YAPI mock地址`
  - extra_sections_allowed: `No`
- `story.md`:
  - template_path: `/home/dministrator/.codex/skills/technical-design-writer/references/story-template.md`
  - title: `# 用户故事`
  - required_columns:
    - `故事编号`
    - `PingCode 工作项编号`
    - `故事名称`
    - `故事说明`
    - `验收标准`
  - extra_sections_allowed: `No`

## 10. Update Plan / 更新计划
- first: 创建 `_planning/`、`api-design.md`、`database-design.md`、`middleware-design.md`，沉淀真相源。
- then: 基于稳定设计生成 `api-index.md` 和 `story.md`。
- last: 依据数据库设计输出 `sql/*.sql`，并做跨文件一致性检查。

## 11. Risks And Open Questions / 风险与待确认问题
| Type | Detail | Blocking | Owner |
| --- | --- | --- | --- |
| risk | embedding 维度与具体模型实现有关，DDL 中需先约定固定维度，否则迁移会受影响 | No | backend |
| risk | PDF 高亮定位依赖解析产物中的页内 offset 或 bbox，若解析库输出不稳定需退化为页级定位 | No | backend |
| risk | 仅依赖数据库轮询执行任务时，高并发吞吐有限，但满足 MVP | No | backend |
| open_question | 前端是否需要单独的上传进度回调 API，当前方案默认由 HTTP 上传进度 + 状态轮询组合实现 | No | frontend/backend |
| open_question | 图片提取后的实际渲染是否需要返回 bbox 列表，当前先保留图片索引 JSON 扩展位 | No | frontend/backend |

## 12. Coverage Checklist / 覆盖检查清单
- [x] 已识别目标模块目录
- [x] 已推导目标产物骨架
- [x] 已区分设计文档、同步产物、执行产物
- [x] 已明确缺失文件是否必须创建
- [x] 已明确空文件是否必须补全
- [x] 已记录一致性约束
- [x] 已记录同步产物更新前置条件
- [x] 已记录同步产物模板路径、标题与表头顺序

## 13. Writer Handoff / 交给 Writer 的内容
- writer_must_create_if_missing:
  - `api-design.md`
  - `api-index.md`
  - `database-design.md`
  - `middleware-design.md`
  - `story.md`
  - `sql/`
  - `sql/documents.sql`
  - `sql/document_assets.sql`
  - `sql/ingestion_jobs.sql`
  - `sql/document_chunks.sql`
- writer_must_fill_if_empty:
  - `api-design.md`
  - `api-index.md`
  - `database-design.md`
  - `middleware-design.md`
  - `story.md`
  - `sql/documents.sql`
  - `sql/document_assets.sql`
  - `sql/ingestion_jobs.sql`
  - `sql/document_chunks.sql`
- writer_must_update:
  - `docs/03-1-backend-design/document-ingestion/AGENTS.md` 之外的本模块固定产物
- writer_must_not_touch:
  - `AGENTS.md`
  - `docs/03-1-backend-design/integrations/`
- writer_update_order:
  - `api-design.md`
  - `database-design.md`
  - `middleware-design.md`
  - `api-index.md`
  - `story.md`
  - `sql/*.sql`
- writer_artifact_consistency_rules:
  - `api-index.md` 仅收录 `api-design.md` 中稳定接口
  - `story.md` 仅收录与当前模块直接相关的故事
  - `sql/*.sql` 必须与 `database-design.md` 的表结构、索引、状态枚举一致
  - `middleware-design.md` 的任务和事件命名必须与 `api-design.md` 的状态流转一致
- writer_sync_artifacts_after_design:
  - `api-index.md`
  - `story.md`
- sync_artifact_template_requirements:
  - `api-index.md` -> `# API Index` / 固定五列表头 / `extra_sections_allowed=No`
  - `story.md` -> `# 用户故事` / 固定五列表头 / `extra_sections_allowed=No`
- writer_open_questions:
  - embedding 维度默认按 `vector(1024)` 设计，实际模型确定后若不一致需做迁移
