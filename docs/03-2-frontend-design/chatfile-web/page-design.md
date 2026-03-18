---
version: 1.0.0
status: draft
module: chatfile-web
role: frontend
dependencies:
  - document-ingestion
  - conversation-orchestrator
change_log:
  - version: 1.0.0
    date: 2026-03-17
    changes: 初始页面设计，覆盖上传、工作台、问答与预览联动
---

> `chatfile-web` 的页面设计文档。用于说明 `/chat` 路由下的主视图、流程、状态回路和接口触点，编码前应先读本文确认页面级行为。

# 页面设计

## 1. 范围

- 页面目标:
  - 为单文档上传、处理、问答、引用预览提供完整工作台体验。
- 角色与权限:
  - 当前版本无登录权限体系，默认所有访客都是可上传、可问答的匿名使用者。
- 对应用户旅程:
  - 上传 PDF -> 等待处理 -> 浏览欢迎态 -> 提问 -> 查看引用 -> 提交反馈
- frontend surfaces:
  - 上传引导区
  - 工作台布局
  - 对话区
  - PDF 预览区
  - 全局反馈层

## 2. Routes

| Route | Entry | Permission | Description | Plan Ref | Architecture Ref |
| --- | --- | --- | --- | --- | --- |
| `/chat` | 默认入口 / 上传完成后保留当前路由 | anonymous | 单文档问答工作台，按文档状态切换空态、处理中和 ready 工作台 | `D-03`, `F-01`~`F-10` | `integration-flows 2,3,4` |

## 3. 布局与区域

页面采用单路由、多状态视图方案。

首屏信息层级：
- TopBar
  - 展示产品名、当前文档名、页数、文件大小和帮助入口。
- Main Stage
  - 无文档时展示上传引导。
  - 上传或处理中展示进度卡片与步骤流。
  - `ready` 后切换为左右分栏工作台。
- Bottom Composer
  - 仅在工作台或欢迎态可见；文档未 ready 时保持禁用态。

`ready` 工作台区域：
- 左侧对话区
  - 欢迎态、消息流、系统状态提示、新消息浮层。
- 中间分隔条
  - 支持拖拽调整宽度。
- 右侧 PDF 预览区
  - 文档预览、目录、页码导航、缩放、高亮。
- 底部输入区
  - 更换文档入口、输入框、发送/停止按钮。

响应式策略：
- 桌面端维持 40/60 初始比例，可拖拽。
- 窄屏下优先保证问答可用，预览区可折叠为窄条，但引用触发时必须自动展开。

## 4. 用户流程

主流程：
1. 用户进入 `/chat`，无文档时看到上传引导区。
2. 用户拖拽或点击选择 PDF，前端先做格式和大小校验。
3. 上传成功后进入 `uploading`，随后根据状态查询转为 `processing`。
4. `processing` 中展示四段步骤条，可同时提前加载 PDF 预览基础内容。
5. 文档变为 `ready` 后展示 ready 横幅，页面切入工作台。
6. 若会话为空，左栏先展示摘要与推荐问题。
7. 用户发送问题后进入检索、生成、完成或失败路径。
8. AI 回答完成后展示引用来源和反馈操作。
9. 用户点击引用，右侧跳页并高亮。
10. 用户可继续追问、更换文档或提交反馈。

分支流程：
- 用户取消上传或取消处理，页面回到空态。
- 用户在处理中直接关闭或离开页面，再次进入后若存在 `doc_id`，按状态恢复。
- 用户点击推荐问题时，跳过手动输入，直接发送首轮消息。

失败回路：
- 上传失败：停留上传区，展示错误卡片和重试入口。
- 处理失败：展示失败原因、查看详情、重新上传。
- 流式失败：保留已有内容，提供重试或重新生成。
- 拒答：显示“文档中未找到相关信息”消息，不展示引用块。

architecture touchpoints:
- `document-ingestion` 负责上传、状态和预览元数据。
- `conversation-orchestrator` 负责问答流、历史、欢迎态与反馈。

## 5. 接口交互

| Stage | API | Trigger | Failure Handling |
| --- | --- | --- | --- |
| 文件上传 | `document-ingestion` 上传接口 | 用户选择合法 PDF | toast + inline error；允许取消与重传 |
| 状态轮询 | `document-ingestion` 状态接口 | 上传返回 `doc_id` 后立即开始，直到 `ready/failed` | 超时提示、失败卡片、重试/重传 |
| 预览元数据 | `document-ingestion` 预览接口 | 上传成功后或 `ready` 后 | 右栏降级为加载失败态，但不阻塞对话 |
| 历史消息 | `GET /api/v1/conversations/{session_id}/history` | 页面进入 ready 且存在 `session_id` | 历史区域为空，保留继续对话能力 |
| 问答流 | `POST /api/v1/conversations/ask` | 用户发送问题，`stream=true` | 失败气泡、停止生成、断流重试 |
| 欢迎态 | `GET /api/v1/conversations/documents/{doc_id}/summary` | 文档 ready 且无消息 | 摘要骨架屏 + 隐藏推荐问题 |
| 反馈提交 | `POST /api/v1/conversations/feedback` | 用户点击点赞/点踩并提交 | 失败静默重试或 toast 提示 |

## 6. 页面状态

- `empty`
  - 无文档时展示上传引导；文档 `ready` 且无会话时展示欢迎态。
- `processing`
  - 覆盖上传中与处理中，显示进度、步骤条、取消和失败反馈。
- `ready`
  - 切入左右分栏工作台，输入区解锁。
- `streaming`
  - 消息进入 `retrieving / generating`，保留 stop 能力。
- `failed/degraded`
  - 上传、处理、预览、问答任一步失败时按区域就近呈现；预览和欢迎态失败不阻断主问答链路。

## 7. 降级与边界

- 当前无鉴权，不单独设计权限页。
- 欢迎接口失败不阻塞问答。
- 预览失败不阻塞问答。
- 引用精细高亮缺失时退化到页级滚动与页内强调。
- 问答流中断时保留已生成内容。
- 设计阶段的协作规则统一参考 `docs/03-2-frontend-design/integrations/`；API 设计以 `03-1` 后端文档为准。

## 8. 覆盖检查

- [x] planner 中的交互要求已覆盖
- [x] planner 中的关键决策已映射
- [x] architecture handoff 中的前端归属已映射
- [x] architecture gaps 中禁止假设的点未被越权补写
- [x] loading / empty / error / success 已覆盖
- [x] 边界场景已覆盖
