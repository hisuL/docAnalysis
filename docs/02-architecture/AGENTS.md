# 02-Architecture Agent 工作说明

## 协同说明

- Claude Code 侧的同级记忆文件为 `CLAUDE.md`。
- 本文件与 `CLAUDE.md` 需要保持一致的阶段边界；目录职责调整时优先同步两者。

## 目录定位

`docs/02-architecture` 是架构设计 Agent 的工作目录。

它的唯一目标是：
- 读取 `docs/01-prd` 中与当前需求相关的 PRD、调研材料和配图
- 基于 PRD 提炼系统范围、业务边界、服务边界、协作流程和关键约束
- 产出架构设计文档，供下一阶段的前后端详细设计继续展开

这里回答的是“系统应该如何在架构层拆分和协作”，不是“具体模块怎么实现”。

## 输入与输出

输入文档不是“可选参考”，而是带明确功能的需求依据：
- [PRD.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/PRD.md)
  - 作用：定义产品目标、范围、核心能力、优先级、约束和验收口径
  - Agent 必须从这里提取“做什么、不做什么、有什么硬约束”
- [research.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/research.md)
  - 作用：补充竞品、方案调研、实现方向和外部经验
  - Agent 必须从这里提取“为什么这样设计、有哪些备选方案和取舍”
- [ChatFile_interactive.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/ChatFile_interactive.md)
  - 作用：补充用户操作链路、交互步骤、页面行为和状态变化
  - Agent 必须从这里提取“关键用户流程、状态流转、前后端交互触点”
- `docs/01-prd/images/`
  - 作用：补充原型图、流程图、界面截图等视觉信息
  - Agent 只有在文字描述不足以确认流程或状态时才读取图片，不要跳过文字直接猜图

输出文档也有明确功能分工：
- [architecture-design.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/architecture-design.md)
  - 功能：给出本轮系统级架构结论
  - 必须回答：系统范围、关键约束、服务拆分结论、阶段性架构总览
- [system-boundaries.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/system-boundaries.md)
  - 功能：统一定义范围边界、业务域、服务职责、主数据归属和服务协作边界
  - 必须回答：系统做什么、不做什么、服务怎么拆、每个服务负责什么、不负责什么、服务间如何衔接
- [integration-flows.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/integration-flows.md)
  - 功能：定义跨服务主流程和关键异常路径
  - 必须回答：核心链路怎么跑、失败怎么处理、跨服务协作顺序是什么

以下文件不是本次需求的“输出物”，而是 Agent 处理增量需求时必须遵守的工作规范：
- [change-management.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/change-management.md)
  - 功能：规定“一个新需求会不会影响当前架构，以及影响后该怎么改文档”
  - 用途：当需求变更、删减或修正时，先按这里判断是否需要更新架构文档，以及更新哪个文档

## 处理流程

Agent 处理一个需求时，默认按下面顺序执行：

1. 先读 `PRD.md`，确认范围、目标、约束和优先级。
2. 再读 `research.md`，确认设计取舍、外部经验和可复用结论。
3. 再读 `ChatFile_interactive.md`，确认关键用户流程、状态变化和交互触点。
4. 仅在文字不足以确认流程、状态或页面关系时，再查看 `docs/01-prd/images/`。
5. 如果是增量需求，不要直接改架构文档；先读 `change-management.md` 判断是否需要改、该改哪份。
6. 只有确认变化进入架构层后，才更新 `architecture-design.md`、`system-boundaries.md`、`integration-flows.md` 中最小受影响的文档。

## 工作边界

本目录只负责架构设计阶段，重点包括：
- 系统范围和范围外事项
- 核心业务域划分
- 后端服务边界与职责归属
- 跨服务主流程与关键异常路径
- 会影响后续实现的关键架构约束

本目录不负责：
- 后端模块级技术设计
- 前端模块级技术设计
- 数据库表字段设计
- API 字段级 request/response 定义
- 类、函数、目录结构、编码方案
- 页面、组件、交互和样式设计

## 阶段衔接规则

- `docs/02-architecture` 结束后，才进入后续详细设计阶段。
- 后端详细设计放在 `docs/03-1-backend-design/`。
- 前端详细设计放在 `docs/03-2-frontend-design/`。
- 不要把 `backend` 或 `frontend` 子目录继续放在当前目录下，避免把阶段边界混在一起。

## 阅读导航

按任务读取最小必要文档：
- 需要先看总体范围、关键约束和阅读地图时，查看 [architecture-design.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/architecture-design.md)
- 需要判断范围边界、业务域、服务职责、数据归属和服务协作边界时，查看 [system-boundaries.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/system-boundaries.md)
- 需要判断跨服务流程和异常路径时，查看 [integration-flows.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/integration-flows.md)
- 需要判断增量需求是否进入架构层，以及应该更新哪个文档时，查看 [change-management.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/change-management.md)

## 更新原则

- 优先更新最小受影响文档，不要默认整组重写
- 全局范围、核心约束或服务拆分变化时，更新 `architecture-design.md`
- 业务边界、服务职责、数据归属或契约边界变化时，优先更新 `system-boundaries.md`
- 流程和异常路径变化时，优先更新 `integration-flows.md`

## 禁止事项

不要在当前目录产出以下内容：
- SQL、DDL、迁移脚本
- 表结构、字段字典、索引设计
- OpenAPI 字段明细或错误码枚举
- 服务内部模块拆分、类图、伪代码
- 前端页面树、组件树、状态管理方案
- 任何本应属于 `docs/03-1-backend-design/` 或 `docs/03-2-frontend-design/` 的详细设计
