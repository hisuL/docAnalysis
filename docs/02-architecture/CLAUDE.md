# 架构文档记忆文件

## 目录定位

- `docs/02-architecture` 是架构设计阶段目录。
- 该阶段负责读取 `docs/01-prd`，产出系统级架构设计。
- 后端和前端的详细设计不属于当前目录，分别在后续阶段处理。

## 输入输出

- 输入：
  - `PRD.md`：功能范围、目标、约束、优先级
  - `research.md`：调研结论、方案取舍、外部经验
  - `ChatFile_interactive.md`：交互流程、状态变化、用户操作链路
  - `images/`：仅在文字不足时补充确认流程和界面关系
- 输出：
  - `architecture-design.md`：系统级架构结论
  - `system-boundaries.md`：范围边界、业务域、服务职责、主数据归属、契约边界
  - `integration-flows.md`：跨服务主流程与异常路径
- `change-management.md` 不是需求输出物，而是增量需求处理规范。

## 阅读顺序

- 先读 `architecture-design.md`，拿到总体结论和阅读地图。
- 再按需读 `system-boundaries.md`、`integration-flows.md`。
- 增量需求先看 `change-management.md`，再决定是否更新架构文档。

## 阶段边界

- 当前阶段只写系统范围、边界、职责、依赖关系和关键流程。
- 不要提前写后端模块技术设计。
- 不要提前写前端模块技术设计。
- 后端详细设计去 `docs/03-1-backend-design/`。
- 前端详细设计去 `docs/03-2-frontend-design/`。

## 强约束

- 不写 endpoint 级 API 定义。
- 不写 request/response 字段表。
- 不写数据库表结构、字段、索引。
- 不写前端页面布局、组件树、props/state 设计。
- 不写实现级伪代码、迁移脚本和部署命令。

## 更新策略

- 优先更新最小受影响文档，不要默认整组重写。
- 全局范围、核心约束或服务拆分变化时，再更新 `architecture-design.md`。
- 业务边界、服务职责、数据归属、契约变化优先更新 `system-boundaries.md`。
- 流程和异常路径变化优先更新 `integration-flows.md`。
