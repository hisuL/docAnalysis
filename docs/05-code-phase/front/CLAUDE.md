# CLAUDE.md

> `docs/05-code-phase/front/` 的前端编码阶段入口文档。这里保留稳定流程和参考索引；`frontend/CLAUDE.md` 负责日常运行时规则。

## 当前规则入口
- 仓库全局规则：`/CLAUDE.md`
- 前端运行时规则：`/frontend/CLAUDE.md`
- 专题自动加载规则：`/.claude/rules/`

## 输入读取策略

遵循渐进式披露：
- 先确认当前工作项和最小上下文，再开始实现
- 不在编码阶段入口一次性读完整套设计、接口、协作和规范文档
- 只有在当前任务确实需要时，再补读专题文档

### 核心必读

- PingCode 中当前已领取的工作项，或其他已明确的当前任务来源
- `/frontend/PLANS.md`
  - 如存在，仅作为当前执行快照
- `/frontend/CLAUDE.md`

### 按需补读

- 当前工作项边界、页面流程或状态不清时：
  - `docs/03-2-frontend-design/` 中对应模块文档
- 需要补任务拆分、同步、缺陷或版本流转时：
  - `../integrations/pingcode-frontend.md`
- 需要接口契约、Mock 或联调信息时：
  - `../integrations/yapi-frontend.md`
- 需要请求层、代码落点或实现约束时：
  - `./docs/FRONTEND.md`
  - `./docs/frontend/api.md`
  - `./docs/ARCHITECTURE.md`
- 发现契约或语义不兼容变化时：
  - `./docs/breaking-change.md`

## 默认工作流
1. 先确认当前工作项。
2. 如存在，再读取 `/frontend/PLANS.md` 了解当前执行快照。
3. 若当前任务边界不清，再回看 `03-2` 对应模块文档。
4. 若领取到的是用户故事或过粗需求，先拆成适合编码阶段推进的能力闭环工作项，再开始实现。
5. 只有在任务涉及接口、Mock、联调、任务同步或 breaking change 时，才补读对应专题文档。

## PingCode 取单约束
- 必须优先使用本地 `skills/pingcode-front/SKILL.md`
- 默认只关注负责人是 `赵帅更` 的任务，或任务类型是“前端”的任务，或标题包含“前端”的任务
- 用户故事不能直接当成编码待办，必须先拆分工作项
- 拆分出的工作项继续指派给 `赵帅更`
- 拆分出的工作项类别统一设置为“前端开发”
- 拆分出的工作项标题统一加前缀 `[前端]`
- 拆分粒度优先保持“能力闭环”，不按实现动作穷举拆成大量小任务

## 设计文档优先级
- 前端页面、组件、状态设计：`docs/03-2-frontend-design/`
- 后端接口、错误码、状态机：`docs/03-1-backend-design/`
- 编码阶段实现约束：`docs/05-code-phase/front/docs/`
- 若 03 文档缺失，不猜测设计意图，先补文档或记录阻塞
- 05 阶段默认消费 03-2 的设计输出；若 03-2 发生影响任务边界、流程或状态的变更，应同步检查本阶段文档是否需要更新
- 编码阶段的接口路径、字段、错误码、示例和 Mock 以 YAPI 为主读取源；`03-1` / `03-2` 负责提供业务语义、状态机和设计边界

## 本目录文档地图
- `/frontend/PLANS.md`：当前执行快照
- `./docs/ARCHITECTURE.md`：代码落点、分层规则、03 与 05 的对齐方式
- `./docs/FRONTEND.md`：前端开发总纲
- `./docs/frontend/api.md`：API 请求层规范
- `../integrations/pingcode-frontend.md`：PingCode 工作流和取单规则
- `../integrations/yapi-frontend.md`：YAPI 和 Mock 的使用边界
- `./docs/breaking-change.md`：breaking change 升级流程

## 记录与协作
- 发现范围不清、设计冲突、breaking change、规范缺失时，记录到 `CHANGELOG.md`
- 若 03-2 文档变更影响当前编码任务、API 消费方式或验收边界，应优先同步本阶段相关文档，再继续批量实现
- 更新规则时，优先补充专题文档或 `.claude/rules/`，不要把 `frontend/CLAUDE.md` 膨胀成大手册
