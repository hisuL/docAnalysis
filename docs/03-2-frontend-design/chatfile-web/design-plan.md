---
version: 1.0.0
status: draft
module: chatfile-web
role: frontend
source_inputs:
  - docs/01-prd/PRD.md
  - docs/01-prd/ChatFile_interactive.md
  - docs/02-architecture/CLAUDE.md
  - docs/02-architecture/architecture-design.md
  - docs/02-architecture/system-boundaries.md
  - docs/02-architecture/integration-flows.md
  - docs/03-1-backend-design/
  - docs/03-2-frontend-design/integrations/pingcode.md
change_log:
  - version: 1.0.0
    date: 2026-03-17
    changes: 初始前端设计计划，覆盖 chatfile-web 模块
---

> `chatfile-web` 模块的前端设计计划文档。用于沉淀范围、约束、决策和任务拆分原则，供后续页面设计、组件设计与工作项拆解统一引用。

# 技术设计计划

## 1. 范围

- module_id: `chatfile-web`
- role: `frontend`
- goal:
  - 为单文档上传、处理、问答、引用跳转场景产出可直接指导编码的前端详细设计。
- out_of_scope:
  - 重定义后端服务边界
  - 数据库、索引、embedding 等后端实现
  - 多文档知识库、权限体系、OCR

## 2. 输入来源

| Source | Type | Why It Matters |
| --- | --- | --- |
| `docs/01-prd/PRD.md` | 产品需求 | 定义单 PDF、5 分钟处理、引用溯源、摘要推荐、反馈等 P0/P1 范围 |
| `docs/01-prd/ChatFile_interactive.md` | 交互需求 | 定义左右分栏、上传流转、流式对话、PDF 高亮、反馈和异常交互 |
| `docs/02-architecture/CLAUDE.md` | 阶段规则 | 限定 03-2 只做前端详细设计，不越界写系统架构 |
| `docs/02-architecture/architecture-design.md` | 架构主文档 | 明确前端只消费 `document-ingestion` 与 `conversation-orchestrator` 两类能力 |
| `docs/02-architecture/system-boundaries.md` | 服务边界 | 明确文档处理与对话编排职责边界，避免前端越权假设 |
| `docs/02-architecture/integration-flows.md` | 集成流程 | 定义上传到 ready、问答与拒答、失败路径 |
| `docs/03-1-backend-design/` 中对应模块 API 文档 | 后端 API 设计 | 提供 03-2 设计阶段使用的接口职责、语义、状态机与边界说明 |
| `docs/03-2-frontend-design/module-sizing.md` | 模块分级规则 | 用于判断 `chatfile-web` 属于大模块，需要完整文档集合 |
| `docs/03-2-frontend-design/integrations/pingcode.md` | 设计阶段协作规范 | 约束用户故事拆分、PingCode 同步粒度、设计变更后的任务同步边界 |
| `frontend/PLANS.md` | 执行快照 | 如存在，可辅助了解当前编码阶段上下文，但不是 03-2 的唯一任务输入 |

## 3. 约束摘要

### 3.1 Product Constraints

- 单次只围绕一份 PDF 对话，不支持跨文档召回。
- 上传文件为单个 PDF，大小上限 100MB。
- 文档处理链路超时上限 5 分钟。
- 文档未 ready 前，问答输入必须禁用。
- 回答必须带引用锚点；低相关时必须拒答。
- 支持最近 10 轮多轮上下文。

### 3.2 Architecture Constraints

- 前端只能作为 `document-ingestion` 和 `conversation-orchestrator` 的消费方。
- 文档处理状态主数据归 `document-ingestion`。
- 会话、摘要、推荐问题、反馈主数据归 `conversation-orchestrator`。
- 前端不得自行发明跨文档、重排序、权限态等架构外能力。

### 3.3 Dependency Constraints

- 上传、处理状态、取消处理依赖 `document-ingestion`。
- 流式问答、历史消息、欢迎态、反馈依赖 `conversation-orchestrator`。
- 当前 03-1 中对话相关详细接口文档尚未补齐，因此对话类接口只能形成前端契约草案。

### 3.4 Delivery Constraints

- 03-2 文档需收敛在 `docs/03-2-frontend-design/`。
- 若模块拆分，需按模块目录组织。
- 模块文档产出需遵守 `module-sizing.md`，不默认复制完整四件套。
- 用户故事要先拆任务，再同步 PingCode。
- 设计阶段的外部系统协作规则统一参考 `docs/03-2-frontend-design/integrations/` 下文档；API 设计只参考 `03-1` 后端设计文档。
- 若编码阶段维护了 `frontend/PLANS.md`，应将其视为执行快照，而不是 03-2 任务拆分的唯一来源。

## 4. 模块摘要

- module_id: `chatfile-web`
- module_name: ChatFile 单文档问答 Web 工作台
- owner_domain:
  - 前端消费 `document-ingestion` 与 `conversation-orchestrator`
- delivery_scope:
  - 上传入口与处理状态
  - 左右分栏工作台
  - 流式问答
  - PDF 预览与引用联动
  - 欢迎态与反馈
- key_dependencies:
  - `document-ingestion`：上传、状态查询、预览元数据
  - `conversation-orchestrator`：问答流、历史、欢迎态、反馈
- writer_must_not_assume:
  - SSE 事件体字段细节
  - 欢迎态与反馈接口最终字段结构
  - PDF 高亮定位的精确坐标协议

## 5. 决策记录

| Decision ID | Topic | Options | Recommendation | Why |
| --- | --- | --- | --- | --- |
| D-01 | 模块边界 | 按页面拆 / 按能力模块拆 | 以 `chatfile-web` 作为 03-2 单模块落文档 | 当前业务高度围绕单工作台闭环，拆太细会割裂交互链路 |
| D-02 | 文档组织 | 直接写正式文档 / 先计划后文档 | 先写 `design-plan.md` 再写正式设计 | 对齐官方技术设计建议，避免长链路遗漏 |
| D-03 | 页面组织 | 上传页与工作台分文档 / 单文档统一 | 在单页面设计中按状态切换描述两个主视图 | 上传、处理中、ready 共享同一路由与信息上下文 |
| D-04 | 对话接口约束 | 等待 03-1 完整后再写 / 先出前端契约草案 | 先写前端契约草案并显式标注非后端定稿 | 不阻塞 03-2 和任务拆解，同时避免越权定稿 |
| D-05 | 任务拆解粒度 | 按通用阶段拆 / 按前端能力拆 | 按可独立验收的前端能力闭环拆分，并为 AI Agent 保留执行期自主拆解空间 | 同时满足管理可追踪性和 AI 执行灵活性 |
| D-06 | `PLANS.md` 使用方式 | 作为长期任务主入口 / 作为执行快照 | 仅在编码阶段需要当前执行上下文时更新 `PLANS.md`，不要求长期完整映射全部拆分结果 | 降低维护成本，避免与 PingCode 重复维护 |
| D-07 | 文档产出级别 | 只输出最小集合 / 输出完整集合 | 将 `chatfile-web` 归类为大模块，保留完整四件套 | 工作台型页面、多区域协同、状态和组件边界都较复杂 |

## 6. 关键交互摘要

- 上传链路：
  - `empty -> validating -> uploading -> processing -> ready/failed`
  - 支持格式/大小校验、取消处理、失败重传
- 工作台链路：
  - `ready` 后切入左右分栏，桌面端默认 40/60，窄屏允许折叠预览
- 对话链路：
  - `idle -> retrieving -> generating -> completed/interrupted/failed`
  - 支持 stop、中断后保留上下文、拒答降级
- 引用链路：
  - 点击引用后自动展开预览、跳页并高亮；高亮坐标缺失时退化到页级定位
- 欢迎与反馈：
  - 文档 `ready` 且无会话时展示摘要与推荐问题
  - AI 消息完成后支持点赞/点踩与补充反馈

## 7. 风险与待确认问题

| Type | Detail | Blocking | Owner |
| --- | --- | --- | --- |
| risk | 对话相关 03-1 文档缺失，可能导致前端契约与后端最终实现偏差 | no | 后端设计 / 前端联调 |
| risk | PDF 引用高亮若缺少精确坐标，可能只能先退化到页级高亮 | no | 前后端联调 |
| risk | 上传状态若只有粗粒度字段，步骤条细节需要前端映射规则 | no | 前后端联调 |
| risk | 若设计阶段未按 03-2 集成文档同步 PingCode 或记录契约待确认项，后续编码阶段可能误读任务边界 | no | 前端协作流程 |
| question | 文档处理状态 API 是否提供剩余时间估算字段 | no | 后端 |
| question | `welcome` 接口是否返回推荐问题 ID、仅文案，还是附带行为参数 | no | 后端 |
| question | 反馈接口是否允许取消反馈或重复覆盖 | no | 后端 |

## 8. 模块复杂度判断

- complexity: `large`
- reason:
  - 单路由下存在上传、处理、ready 工作台等多主状态
  - 左右分栏、对话流、PDF 预览和反馈存在复合交互
  - 组件职责和状态边界较多，适合单独沉淀 `component-design.md`
  - 后续可能需要多人或多 Agent 并行协作

selected_outputs:
- `design-plan.md`
- `page-design.md`
- `component-design.md`
- `work-item-breakdown.md`

## 9. 文档产出说明

- `page-design.md`
  - 负责主视图、主流程、状态回路和接口触点
- `component-design.md`
  - 负责关键组件职责、状态归属和跨区域交互边界
- `work-item-breakdown.md`
  - 负责把设计收敛成 PingCode 可管理的能力闭环任务

## 10. 覆盖检查清单

- [x] 模块交接卡摘要已整理
- [x] 架构交接缺口已显式记录
- [x] 依赖契约最低粒度已补齐
- [x] PRD 约束已映射
- [x] 引用文档约束已映射
- [x] 前端交互要求已逐条记录
- [x] loading / empty / error / success 已覆盖
- [x] 权限态和边界态已覆盖
- [x] 跨模块依赖已标注
- [x] 未决问题已列出

## 11. 写作交接

- writer_must_cover:
  - 上传空态、上传中、处理中、ready、failed 五类主状态
  - 工作台分栏、拖拽、折叠与引用触发展开
  - 流式问答、停止生成、拒答与异常回路
  - 欢迎态与反馈机制
  - 键盘快捷键、输入约束与边界态
- writer_must_not_assume:
  - 对话接口字段级细节
  - 后端未定义的引用坐标协议
  - 多文档、权限、OCR、Rerank 等范围外能力
- writer_open_questions:
  - `welcome`、`feedback`、流式事件体的最终契约
  - 高亮定位元数据的字段结构
- writer_architecture_gaps_to_respect:
  - 对话服务 03-1 缺失时只能输出前端契约草案，不得写成后端最终 API 定稿
