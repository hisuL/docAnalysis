# document-ingestion Agent 工作说明

## 协同说明

- 本文件用于约束 `docs/03-1-backend-design/document-ingestion/` 的工作方式、目录边界和标准产物。
- 本目录的设计方式以当前项目实际交付链路为准，不强行套用旧的 `technical-design` skill 模板。

## 目录定位

`docs/03-1-backend-design/document-ingestion` 是 `document-ingestion` 模块的后端详细设计目录。

它的目标是：
- 消费 `docs/01-prd/` 和 `docs/02-architecture/` 已经稳定的输入
- 展开 `document-ingestion` 模块的 API、数据库和中间件通信详细设计
- 产出后续可落地到 YAPI、SQL、PingCode 的模块级设计成果

这里回答的是模块详细设计，不重做系统级架构设计。

## 输入依据

进入本目录工作前，默认先读取这些输入：
- [PRD.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/PRD.md)
  - 主需求输入，必须先读
- [research.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/research.md)
  - 技术调研与候选方案输入
- [ChatFile_interactive.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/01-prd/ChatFile_interactive.md)
  - 会影响后端接口与状态语义的交互输入
- [AGENTS.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/AGENTS.md)
  - 架构阶段入口，先读这里，再按其中导航展开需要的架构文档
- `docs/03-1-backend-design/integrations/`
  - 需要对接外部系统时，再读取对应指南

## 目录结构与文件职责

固定产物：
- `api-design.md`：API 设计过程文档，不承担 YAPI 最终索引职责。
- `api-index.md`：YAPI 导入索引，只放最终导入相关内容。
- `database-design.md`：数据库设计过程文档，回答为什么这样设计。
- `middleware-design.md`：中间件通信设计，写任务、消息、事件、队列、回调等设计细节。
- `story.md`：设计收敛后的用户故事列表，用于后续导入 PingCode。
- `sql/`：最终落地 SQL；一张表一个 `sql` 文件，只放可执行内容。

## 处理流程

Agent 处理 `document-ingestion` 模块详细设计需求时，默认按下面顺序执行：

1. 先读 `docs/01-prd/PRD.md`，确认功能范围、硬约束和验收标准。
2. 再读 `docs/01-prd/research.md` 和 `docs/01-prd/ChatFile_interactive.md`，补齐技术依据与交互约束。
3. 再读 [AGENTS.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/AGENTS.md)，按架构阶段导航展开当前任务所需的最小文档集。
4. 使用 skill `$technical-design` 产出技术设计文档和最终落地产物
5. 阅读 `docs/03-1-backend-design/integrations/` 下的 `yapi.md` 把 API 导入 YAPI， 
6. 阅读 `docs/03-1-backend-design/integrations/` 下的 `pingcode.md` 使用 `pingcode.md` 把故事导入 PingCode。

## 工作边界

本目录只负责 `document-ingestion` 模块的后端详细设计，重点包括：
- 模块级 API 设计
- 模块级数据库设计
- 模块级中间件通信设计
- 模块级故事整理与外部系统导入准备
- 最终 SQL 落地产物

本目录不负责：
- 重新定义系统级架构边界
- 非`document-ingestiom` 模块无关的设计
- 前端页面、组件、交互和样式设计
- 直接编写业务代码
- 代替 YAPI 成为接口最终展示系统
- 代替 PingCode 成为故事最终管理系统

## 更新原则

- 优先增量修改，不要默认整组重写当前模块目录。
- 先判断变更影响的是 API、数据库、中间件通信、故事，还是最终 SQL，再更新对应文件。
- 过程设计文档和最终落地产物必须保持一致，但不要在多个文件里维护重复真相源。
- 外部系统操作说明统一引用 `docs/03-1-backend-design/integrations/`，不要复制进本模块文档。

## 阅读导航

按任务读取最小必要文档：
- 需要继续 API 设计时，查看 [api-design.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/03-1-backend-design/document-ingestion/api-design.md)
- 需要整理 YAPI 导入索引时，查看 [api-index.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/03-1-backend-design/document-ingestion/api-index.md)
- 需要继续数据库设计时，查看 [database-design.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/03-1-backend-design/document-ingestion/database-design.md)
- 需要继续中间件通信设计时，查看 [middleware-design.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/03-1-backend-design/document-ingestion/middleware-design.md)
- 需要整理故事时，查看 [story.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/03-1-backend-design/document-ingestion/story.md)
- 需要使用外部系统时，查看 `docs/03-1-backend-design/integrations/` 下对应指南

## 禁止事项

不要在当前目录做以下事情：
- 把系统级架构重写回当前模块目录
- 在 `api-index.md` 中混入大量 API 设计过程说明
- 在 `sql/` 中放非表级的随意草稿 SQL
- 让一个 `sql` 文件同时定义多个表
- 把 YAPI 或 PingCode 的操作说明复制进本模块目录
- 把前端设计、测试方案或实现代码混入当前目录
- 
## YAPI配置

当前模块的YAPI配置
- (YAPI 项目 ID) `yapi_project_id`: 50 
- (YAPI 分类 ID) `yapi_cat_id`: 239
- (YAPI 项目 TOKEN) 'yapi_token': cc6dcd31dd920cc322828fe2c12c42eec08a01e4a8556f5ff763ab88347db3fb
- (YAPI 基础 URL，默认为 `http://192.168.210.90:3010`) `yapi_base_url`: http://192.168.210.90:3010

## PINGCODE配置
- (PingCode 项目 ID) `pingcode_project_id`: 69b7999b8aadfd4b9f26c141