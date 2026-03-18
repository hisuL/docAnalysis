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
    changes: 初始组件设计，覆盖上传、工作台、对话和预览组件
---

> `chatfile-web` 的组件设计文档。用于定义主要组件职责、状态归属、交互模式和边界处理，编码时可据此判断组件落点和协作边界。

# 组件设计

## 1. 组件地图

| Component | Responsibility | Parent | Key State / Notes |
| --- | --- | --- | --- |
| `ChatWorkspacePage` | 承载空态、处理中、工作台三类页面状态 | route root | 持有文档上下文和页面主状态 |
| `UploadDropzoneCard` | 文件选择、拖拽上传、前置校验 | `ChatWorkspacePage` | 处理 `dragActive` 与校验错误 |
| `DocumentProcessingPanel` | 上传进度、处理步骤、取消和失败反馈 | `ChatWorkspacePage` | 映射 `uploading -> processing -> ready/failed` |
| `WorkspaceSplitLayout` | 左右分栏、拖拽、折叠和引用触发展开 | `ChatWorkspacePage` | 管理 `splitRatio` 与预览折叠 |
| `ConversationPane` | 欢迎态、消息流、生成状态和异常反馈 | `WorkspaceSplitLayout` | 管理欢迎态切换和滚动策略 |
| `AiMessageBubble` | AI 消息正文、引用、复制、反馈、拒答态 | `MessageList` | 承担回答后的增强交互 |
| `ComposerBar` | 输入、发送、停止、更换文档、快捷键 | `ChatWorkspacePage` | 管理草稿、限长、stop 状态 |
| `PdfPreviewPane` | PDF 预览、目录、缩放、页码与高亮 | `WorkspaceSplitLayout` | 管理当前页、缩放、高亮引用 |
| `GlobalFeedbackLayer` | toast、错误提示和确认反馈 | page-level shared | 页面级共享反馈层 |

## 2. 关键组件边界

### `ChatWorkspacePage`

- Purpose:
  - 统一管理文档状态驱动的页面级切换。
- Local state:
  - 当前文档标识
  - 页面主状态：`empty | uploading | processing | ready | failed`
- Events:
  - 文件选定
  - 上传成功
  - 状态轮询完成
  - 更换文档
- Error feedback:
  - 上传失败和处理失败均由页面级错误卡片承载。

### `WorkspaceSplitLayout`

- Purpose:
  - 统一左右栏布局行为，不让预览折叠和引用展开分散到业务组件。
- Local state:
  - `splitRatio`
  - `isPreviewCollapsed`
- Events:
  - drag start/move/end
  - toggle preview
  - open preview by citation
- Boundary:
  - 最小宽度限制 30%，窄屏下允许自动折叠但引用触发必须可展开

### `ConversationPane`

- Purpose:
  - 汇总欢迎态、消息流、生成状态和异常反馈。
- Local state:
  - `showWelcome`
  - `showNewMessageHint`
- Events:
  - send question
  - stop generation
  - retry message
  - citation click
- Error feedback:
  - 检索失败、生成失败、断流提示

### `AiMessageBubble`

- Purpose:
  - 承担 AI 消息正文、引用、复制、反馈、拒答等复合交互。
- Local state:
  - 引用块展开态
  - 反馈面板展开态
- Events:
  - citation click
  - copy
  - thumbs up/down
  - submit feedback
- Error feedback:
  - 反馈提交失败静默重试，必要时 toast

### `ComposerBar`

- Purpose:
  - 聚合输入、发送、停止和更换文档操作。
- Local state:
  - 草稿文本
  - 字数超限态
- Events:
  - input
  - send
  - stop
  - open upload chooser
  - keyboard shortcuts
- Error feedback:
  - 字数红字提示、禁用态按钮

### `PdfPreviewPane`

- Purpose:
  - 提供文档可视化、导航与引用联动。
- Local state:
  - 当前页
  - 缩放比例
  - 目录开关
  - 当前高亮引用
- Events:
  - page change
  - zoom change
  - toc select
  - citation highlight
- Error feedback:
  - 预览加载失败时允许重试，不阻断对话

## 3. 状态管理策略

- 本地状态
  - 输入草稿
  - 拖拽高亮
  - 反馈面板开关
  - 预览区折叠和缩放
- 全局状态
  - 当前文档上下文
  - 文档处理状态
  - 当前会话消息列表
  - 全局 toast 队列
- 服务端状态
  - 文档处理阶段和失败原因
  - 历史消息
  - 欢迎摘要与推荐问题
  - 反馈提交结果

状态组织原则：
- 上传与处理状态归为一个文档生命周期状态机。
- 对话流单独维护 `retrieving / generating / completed / interrupted / failed`。
- 预览聚焦状态和会话引用点击通过事件桥接，不复制业务主数据。

## 4. 关键交互模式

- 上传前校验：
  - `UploadDropzoneCard` 先校验 MIME、后缀、大小和空文件，再上抛合法文件
- 布局交互：
  - `WorkspaceSplitLayout` 维护分栏比例，并在引用跳转时自动展开右栏
- 流式生成：
  - `ConversationPane` 先插入用户消息，再渲染生成中 AI 消息
- 引用联动：
  - `AiMessageBubble` 触发引用事件，`PdfPreviewPane` 负责跳页与高亮
- 键盘优先：
  - `ComposerBar` 消费 `Enter`、`Shift+Enter`、`Esc`、`Ctrl+K`

## 5. 可访问性与边界场景

- 键盘操作
  - `Ctrl+K` 聚焦输入框
  - `Enter` 发送
  - `Shift+Enter` 换行
  - `Esc` 停止生成或关闭反馈面板
- 焦点管理
  - 文档 ready 后输入框自动获焦
  - 提交反馈后焦点回到消息操作区
  - 预览区折叠/展开后不打断当前输入焦点
- 异常输入
  - 纯空格禁止发送
  - 过长文本显示超限提示
  - 粘贴超长内容时截断并提示
- 超长文本
  - 推荐问题、消息正文、引用标题需要支持换行和折叠
- 加载与失败
  - 骨架屏、失败卡片、toast 必须可被屏幕阅读器感知
- 预览边界
  - PDF 加载失败不影响对话
  - 高亮坐标缺失时至少滚动到页码

## 6. 待确认问题

- 流式事件体最终字段是否含消息 ID、引用增量和状态码。
- 欢迎态是否与历史消息接口合并返回。
- 反馈接口是否允许撤销或覆盖已有反馈。
- 预览高亮所依赖的定位元数据是页内文本索引还是坐标框数组。

## 7. 覆盖检查

- [x] planner 中的交互要求已覆盖
- [x] planner 中的关键决策已映射
- [x] architecture handoff 中的前端归属已映射
- [x] architecture gaps 中禁止假设的点未被越权补写
- [x] loading / empty / error / success 已覆盖
- [x] 边界场景已覆盖
