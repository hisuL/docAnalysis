---
version: 1.1.2
status: draft
modules:
  - document-ingestion
  - conversation-orchestrator
change_log:
  - version: 1.1.3
    date: 2026-03-17
    changes: 合并 business-context 与 service-boundaries，改为统一引用 system-boundaries
  - version: 1.1.2
    date: 2026-03-17
    changes: 弱化过程性说明，强化主架构文档的结论表达
  - version: 1.1.1
    date: 2026-03-17
    changes: 移除 service-handoffs，架构层文档不再承载分模块交接信息
  - version: 1.1.0
    date: 2026-03-17
    changes: 按 AI 地图阅读方式重构架构文档，拆分业务上下文、服务边界、集成流程和交接卡
  - version: 1.0.0
    date: 2026-03-16
    changes: 初始版本
---

# ChatFile 架构设计

## 1. 文档定位

本文件是架构层主文档，用于给出系统范围、关键约束和后端微服务拆分结论。

本文件重点回答三类问题：
- 后端按什么 API 视角拆分微服务
- 每个微服务的边界、数据归属和对外契约是什么
- 关键跨服务流程如何协作

微服务内部实现、数据库细节和前端设计不在本文件中展开。

## 2. 相关文档导航

如需展开查看，可结合以下文档阅读：

1. 当前文档：查看系统范围、核心约束和服务拆分结论
2. [system-boundaries.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/system-boundaries.md)：查看范围边界、业务域、服务职责与主数据归属
3. [integration-flows.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/integration-flows.md)：查看关键跨服务流程和异常路径

## 3. 背景与目标

ChatFile 是一个面向单文档问答场景的 Web 应用，目标是在单份 PDF 范围内完成上传、解析、检索、多轮对话和引用跳转。

本轮架构聚焦 P0 与部分 P1 的稳定落地，覆盖：
- 单 PDF 上传
- 文档解析、切片、向量化
- 单文档问答
- 引用跳页
- 摘要、推荐问题、反馈

本轮明确不覆盖：
- 用户登录与权限体系
- 多文档知识库管理
- 文件版本控制
- OCR
- Rerank、知识图谱、运营报表、安全防御体系

## 4. 输入依据与关键约束

### 4.1 输入材料

- [PRD.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/PRD.md)
  - 定义单文档范围、5 分钟处理上限、按 `doc_id` 检索、低相关拒答、引用跳页等核心约束。
- [research.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/research.md)
  - 提供 FastAPI、Haystack、SeaweedFS、PostgreSQL/pgvector、litellm 等候选技术。
- [ChatFile_interactive.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/ChatFile_interactive.md)
  - 影响后端状态语义、引用契约和摘要推荐触发时机，但不在本阶段展开前端设计。

### 4.2 关键约束

- 单文档范围内回答，不允许跨文档召回。
- 首版只支持文本型 PDF，不支持扫描件 OCR。
- 文档处理链路需在 5 分钟内完成超时控制。
- 问答必须带引用锚点，点击后能定位到 PDF 页码。
- 当检索相关性不足时，系统必须拒答，不允许编造。
- 后端架构优先服务 MVP 落地，避免过度拆分微服务。

## 5. 架构结论

### 5.1 业务域保持粗粒度

本轮只保留两个后端业务域：
- 文档处理域：负责上传后文档进入可检索状态前的全链路处理
- 对话编排域：负责问答、引用装配、会话、摘要和反馈

这样划分的原因是：
- 文档处理与问答编排的主数据归属清晰
- 两条主链路的 API 责任边界清晰
- 可以避免在 MVP 阶段引入过细的服务拆分

前端不在本阶段做领域划分，前端相关设计留到后续技术设计阶段处理。

### 5.2 后端微服务按 API 视角划分

本轮后端只定义两个对外服务边界：
- `document-ingestion`
  - 对外负责上传、状态查询、预览元数据、取消处理
- `conversation-orchestrator`
  - 对外负责问答、会话、摘要、推荐问题、反馈

采用这种拆分的原因是：
- 上传和文档处理是一条独立的 API 能力链路
- 问答和会话编排是另一条独立的 API 能力链路
- 两者之间通过 `doc_id` 范围内的稳定数据契约协作

其中异步 worker 属于服务内部执行形态，不单独定义为对外微服务边界；否则会把内部执行机制误当成系统边界。

### 5.3 前端在本阶段的定位

前端在架构层只作为外部调用方存在：
- 调用 `document-ingestion` 完成上传和状态查询
- 调用 `conversation-orchestrator` 完成问答和反馈

这样处理的原因是前端在当前阶段主要消费稳定 API 契约，而不是决定后端服务边界。

## 6. 阅读后的预期结论

读完架构层文档后，应能直接确定：
- 后端只有哪些微服务
- 每个微服务对外暴露什么能力
- 微服务之间如何协作
- 哪些数据归哪个服务拥有
- 下一阶段技术设计该按哪个服务边界展开

如果要继续做实现级设计，应基于当前主文档、[system-boundaries.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/system-boundaries.md) 和 [integration-flows.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/integration-flows.md) 进入 `03` 阶段，再在分模块技术设计中补交接信息。
