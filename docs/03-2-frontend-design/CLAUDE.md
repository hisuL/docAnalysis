# CLAUDE.md

> `docs/03-2-frontend-design/` 的前端详细设计阶段入口文档。这里只保留稳定规则、阶段边界和标准产物；模块细节落在各模块目录。

## 当前规则入口

- 仓库全局规则：`/CLAUDE.md`
- 03-2 阶段入口：当前文件
- 模块分级与产出矩阵：`docs/03-2-frontend-design/module-sizing.md`
- 03-2 阶段协作文档：`docs/03-2-frontend-design/integrations/`

## 目录定位

`docs/03-2-frontend-design/` 只负责前端详细设计，回答：
- 前端模块怎么拆
- 页面、组件、状态和交互怎么设计
- 前端如何消费 02 阶段定义好的系统能力
- 用户故事如何拆成前端任务并衔接后续执行

这里不负责：
- 重写系统级架构边界
- 后端表结构、字段级 API 定稿和实现细节
- 前端编码规范、目录结构和工程实现细节

## 前置条件

- 已有 `docs/02-architecture/` 的稳定架构结论
- 已有 `docs/01-prd/` 中足以支撑前端设计的需求与交互输入

## 输入读取策略

遵循渐进式披露：
- 阶段启动时只读取最小必需输入
- 进入具体模块后，再按任务场景补读细节文档
- 不在阶段入口一次性灌入所有 PRD、架构和协作文档

### 核心必读

- `docs/01-prd/PRD.md`
- `docs/02-architecture/CLAUDE.md`
- `docs/03-1-backend-design/` 中对应模块的 API 设计文档
- `docs/03-2-frontend-design/module-sizing.md`

### 按需补读

- 需要交互细节时：
  - `docs/01-prd/ChatFile_interactive.md`
- 需要系统能力、边界或流程时：
  - `docs/02-architecture/architecture-design.md`
  - `docs/02-architecture/system-boundaries.md`
  - `docs/02-architecture/integration-flows.md`
- 需要同步任务到外部系统时：
  - `docs/03-2-frontend-design/integrations/pingcode.md`
- 需要了解编码阶段当前执行上下文时：
  - `frontend/PLANS.md`

### 模块内继续发现

- 进入模块目录后，优先通过 `{module}/design-plan.md` 继续发现该模块的专属输入和待补读文档
- 不要求在阶段入口提前读完所有模块细节文档

## 标准输出

核心输出：
- `{module}/design-plan.md`
- `{module}/work-item-breakdown.md`

按复杂度补充：
- `{module}/page-design.md`
- `{module}/component-design.md`

## 默认工作流

1. 先读取当前阶段的核心必读输入，确认模块边界和最小上下文。
2. 结合 `module-sizing.md` 判断模块属于小 / 中 / 大哪一档。
3. 先写 `{module}/design-plan.md`，明确范围、决策、风险和文档产出选择。
4. 仅在需要时按场景补读交互、架构流程或协作文档。
5. 仅为该模块确实需要的部分产出 `{module}/page-design.md` 与 `{module}/component-design.md`。
6. 产出 `{module}/work-item-breakdown.md`。
7. 按 03-2 阶段协作文档处理 PingCode 任务同步。
8. 若需要执行快照，可按需更新 `frontend/PLANS.md`，但不把它当作长期唯一任务源。

## 文档地图

- `module-sizing.md`
  - 模块分级、文档产出矩阵、裁剪原则
- `{module}/design-plan.md`
  - 设计计划、约束、决策点、风险、产出选择和 handoff
- `{module}/page-design.md`
  - 路由、区域划分、主流程、状态流转、API 触点
- `{module}/component-design.md`
  - 组件职责、状态策略、交互模式、边界与可访问性
- `{module}/work-item-breakdown.md`
  - 用户故事、任务拆解、PingCode 同步草案

## 强约束

- 03-2 的最小组织单元是前端模块，不是零散页面描述或临时任务名。
- 正式设计文档遵循“先计划，再正式文档”。
- 模块文档数量应与模块复杂度匹配，不默认要求每个模块都产出四份完整文档。
- 公共规则、通用状态要求、协作规范优先上移到阶段级文档，不在每个模块中重复展开。
- 用户故事不能直接作为编码待办，必须先拆为前端可执行任务。
- PingCode 工作项服务于管理、协作、验收和跟踪，不等于 AI Agent 的最细执行步骤。
- 03-2 输出到 PingCode 的任务拆分，默认保持“能力闭环粒度”，不按实现步骤粒度穷举拆单。
- AI Agent 认领工作项后，可以基于代码现状、依赖和风险自行生成内部执行步骤，不要求把内部步骤全部回写 PingCode。
- 只有影响跨角色协作、依赖阻塞、缺陷跟踪、版本风险或验收边界的事项，才需要显式进入 PingCode。
- 涉及设计阶段的外部系统协作时，统一参考 `docs/03-2-frontend-design/integrations/` 下文档。
- 如果 03-1 接口设计缺失，03-2 只能写前端契约草案，并显式标记不是后端最终定稿。

## 模块文档最低要求

### `design-plan.md`

至少包含：
- 范围
- 输入来源
- 约束摘要
- 架构交接摘要
- 决策记录
- 风险与待确认问题
- 模块复杂度判断
- 文档产出选择
- 写作提纲
- 覆盖检查清单
- 写作交接

### `page-design.md`

仅在模块存在明确页面主流程、布局区域、状态回路或 API 触点时产出。

至少覆盖：
- 路由与入口
- 布局与区域划分
- 主流程与失败回路
- API 交互触点
- loading / empty / error / success / disabled
- 动效、反馈与异常策略

### `component-design.md`

仅在组件职责边界、状态归属或并行协作复杂到需要单独展开时产出。

至少覆盖：
- 组件地图与职责
- 状态管理策略
- 交互模式
- 键盘与可访问性
- 边界输入与失败处理
- 外部协作入口引用

### `work-item-breakdown.md`

至少覆盖：
- 用户故事
- 每个故事下的前端任务
- 每个任务对应的能力闭环范围
- 前置依赖
- 验收点
- PingCode 同步草案

任务拆分规则：
- 每个工作项应对应一个可独立验收的前端能力闭环，而不是单个实现动作。
- 一个工作项内允许同时覆盖页面、组件、状态、接口接入、测试和异常处理。
- 不按“加按钮 / 接接口 / 补样式 / 补 loading / 补测试”这类实现步骤单独拆 PingCode 任务，除非它本身已形成独立协作边界。
- AI Agent 在执行阶段可自行二次拆解内部步骤，但内部步骤默认不沉淀为长期管理任务。
- `PLANS.md` 如存在，只作为当前执行快照或过场记录，不作为 03-2 必须长期维护的正式拆解产物。

## 公共内容上移原则

- 通用协作规则：写入 `integrations/`
- 模块分级与产出规则：写入 `module-sizing.md`
- 通用文档写法和阶段边界：写入当前 `CLAUDE.md`
- 模块文档只保留本模块特有的范围、流程、状态、风险、待确认项和任务拆分结果

## PingCode 与 API 设计边界

- PingCode：
  - 设计阶段的任务拆解与同步规则统一参考 `docs/03-2-frontend-design/integrations/pingcode.md`
- API 设计：
  - 03-2 设计阶段只参考 `docs/03-1-backend-design/` 中对应模块的 API 设计文档
  - 设计阶段不要求访问 YAPI 或其他外部 API 系统
- 03-2 只记录设计上“需要哪些外部能力”“当前已确认哪些契约”“哪些点仍待确认”

## 下游影响与同步触发

- `design-plan.md` 发生范围、依赖或决策变化时：
  - 检查 `work-item-breakdown.md` 是否需要同步调整
  - 检查后续编码阶段的任务快照或实现约束是否需要更新
- `page-design.md` 发生主流程、状态机或页面入口变化时：
  - 检查后续阶段的页面实现约束、测试路径和验收口径是否需要更新
- `component-design.md` 发生组件职责、状态归属或交互边界变化时：
  - 检查后续阶段的组件落点、状态管理和测试约束是否需要更新
- `work-item-breakdown.md` 发生任务边界、依赖或验收标准变化时：
  - 同步检查 PingCode 工作项是否需要更新
  - 如编码阶段依赖 `PLANS.md` 执行快照，再按需同步
- 接口依赖或契约假设变化时：
  - 检查 03-1 后端设计和后续阶段 API 对齐文档是否需要同步

## `PLANS.md` 使用规则

- `PLANS.md` 是执行快照，不是长期唯一任务源。
- 仅在需要给编码阶段提供当前执行上下文时更新。
- `当前任务` 只放已领取且马上要执行的任务。
- `进行中` 记录已开始但未完成事项。
- `待办` 仅保留近期可能进入执行的事项，不要求完整复制 PingCode。
- `已完成` 只记录已验证结果。
- 文档引用优先指向 03-2 正式设计文档。

## 命名与组织约定

- 阶段入口统一使用 `CLAUDE.md`
- 阶段摘要卡片统一使用 `AGENTS.md`
- 分级规则统一写入 `module-sizing.md`
- 模块统一使用：
  - `design-plan.md`
  - `work-item-breakdown.md`
- 模块可按复杂度补充：
  - `page-design.md`
  - `component-design.md`
- 如果后续新增模块，在 `docs/03-2-frontend-design/` 下按模块并列建目录，沿用同样结构
- 目录名使用稳定模块名，不直接使用临时工作项标题

## 异常处理

- PingCode 无法访问或授权失败时，先完成本地文档，并在 `work-item-breakdown.md` 记录待同步清单；若编码阶段需要执行快照，再补 `PLANS.md`
- 设计阶段不引入 YAPI 作为主读取源；若编码阶段发现契约冲突，应在 05 阶段记录并推动 03-1 / 03-2 回写
- 若发现 02 阶段边界不足以支持前端设计，应先回补 02，而不是在 03-2 自行扩写系统边界

## 禁止事项

- 不在 03-2 重写系统级架构结论
- 不在 03-2 编写数据库设计、字段级 API 定稿和编码细则
- 不直接依赖 05 阶段文档作为 03-2 的核心输入来源
