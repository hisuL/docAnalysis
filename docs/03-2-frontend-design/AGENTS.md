# 03-2-Frontend-Design Agent 工作说明

## 协同说明

- Claude Code 侧的同级入口文档为 `CLAUDE.md`。
- 本文件只做阶段摘要和阅读导航；完整规则、边界和流程以 `CLAUDE.md` 为准。

## 目录定位

`docs/03-2-frontend-design` 是前端详细设计阶段目录。

它的唯一目标是：
- 读取 `docs/01-prd/` 与 `docs/02-architecture/` 中与前端相关的输入
- 结合 `docs/03-1-backend-design/` 中对应模块的 API 设计文档完成前端详细设计
- 按前端模块产出详细设计计划与正式设计文档
- 将用户故事拆为前端可执行任务
- 按 03-2 阶段协作规范，把任务同步到外部系统
- 如有需要，再把当前执行快照同步到 `PLANS.md`

## 当前文档地图

- `CLAUDE.md`
  - 阶段入口、边界、输入输出、处理流程、命名约定
- `module-sizing.md`
  - 模块分级、文档产出矩阵、裁剪原则
- `integrations/pingcode.md`
  - 03-2 阶段如何把设计结果同步到 PingCode
- `{module}/design-plan.md`
  - 模块级写入计划
- `{module}/page-design.md`
  - 页面设计，按模块复杂度按需产出
- `{module}/component-design.md`
  - 组件设计，仅在复杂模块中单独产出
- `{module}/work-item-breakdown.md`
  - 用户故事、任务拆解与同步草案

## 阅读导航

1. 先读 `CLAUDE.md`
2. 只读取当前任务所需的核心输入，不在入口一次性读完整套文档
3. 再读 `module-sizing.md` 判断该模块需要哪些文档
4. 然后进入目标模块目录
5. 需要设计阶段外部协作时，再看 `integrations/` 下对应文档
