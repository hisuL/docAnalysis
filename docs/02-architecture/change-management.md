---
version: 1.0.0
status: draft
change_log:
  - version: 1.0.0
    date: 2026-03-17
    changes: 新增架构层文档变更管理规则
---

# 变更管理

## 1. 目标

本文件用于定义项目进入中期后，架构层文档在面对新增需求、删减需求和边界修正时的处理规则。

核心原则：
- 架构层文档维护当前有效的架构边界
- 架构层文档不记录需求讨论过程本身
- 只有影响边界、归属、契约、主流程的变化，才进入架构层文档

## 2. 先判断是否需要更新架构层文档

收到新需求、需求删除或方案修正后，先判断下面 5 个问题：

1. 是否改变后端微服务数量
2. 是否改变某个微服务的主职责
3. 是否改变数据归属
4. 是否改变跨服务输入输出契约
5. 是否改变主成功路径或关键异常路径

判定规则：
- 如果 5 个问题都是否，则架构层文档不更新
- 如果只涉及第 2、3、4 项，通常更新系统边界文档
- 如果只涉及第 5 项，通常更新流程文档
- 如果涉及第 1 项，或多个问题同时为是，通常需要更新主架构文档

## 3. 变化类型与处理方式

### 3.1 不影响架构边界的变化

典型场景：
- 文案调整
- 页面展示调整
- 推荐问题数量调整
- 页面交互细节调整
- API 字段级别微调但不影响服务职责

处理方式：
- 不更新架构层文档
- 更新 PRD 或模块技术设计文档

原因：
- 这些变化没有改变系统边界

### 3.2 影响服务职责，但不改变服务拆分

典型场景：
- `conversation-orchestrator` 新增一个仍归自己负责的能力
- `document-ingestion` 增加新的状态查询能力
- 原有能力归属调整，但仍在现有服务内

处理方式：
- 优先更新 [system-boundaries.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/system-boundaries.md)
- 如果主架构结论摘要已过时，再同步更新 [architecture-design.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/architecture-design.md)

### 3.3 影响跨服务流程或异常路径

典型场景：
- 文档上传后增加人工确认步骤
- 摘要生成从同步改为异步
- 问答前新增审核态或准入判断
- 失败后的补偿路径发生变化

处理方式：
- 优先更新 [integration-flows.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/integration-flows.md)
- 如果系统关键约束随之变化，再同步更新 [architecture-design.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/architecture-design.md)

### 3.4 影响系统边界或服务拆分

典型场景：
- 新增独立后端微服务
- 合并两个已有服务
- 删除某个核心能力域
- 把原来属于一个服务的主数据迁移到另一个服务

处理方式：
- 先更新 [architecture-design.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/architecture-design.md)
- 再更新 [system-boundaries.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/system-boundaries.md)
- 最后更新 [integration-flows.md](/home/dministrator/codexWorkspace/ProjectSkill/docs/02-architecture/integration-flows.md)

原因：
- 这是架构层调整，必须先收敛主结论，再同步到子文档

## 4. 删除需求时的处理规则

如果产品删掉某个需求，不要直接只删一句话。

要逐项确认它影响的是：
- 范围声明
- 服务职责
- 数据归属
- 跨服务流程
- 下游技术设计

处理原则：
- 若删除项不影响系统边界，架构层文档可以不动
- 若删除项使某个服务职责收缩，更新 `system-boundaries.md`
- 若删除项使某条主流程消失，更新 `integration-flows.md`
- 若删除项导致整个能力域消失，必须更新主架构文档和 `system-boundaries.md`

## 5. 更新顺序

推荐按下面顺序处理：

1. 先判断变化是否进入架构层文档
2. 确定变化类型
3. 只更新最小受影响文档
4. 检查主文档摘要是否失效
5. 检查 `03` 阶段是否需要联动更新

默认不要整组重写所有 `02` 文档。

## 6. 破坏性变更处理

以下情况视为架构层的破坏性变更（breaking change）：
- 微服务数量变化
- 微服务主职责迁移
- 主数据归属变化
- 核心服务间输入输出契约变化
- 主流程入口或主流程前置条件变化

处理要求：
- 在受影响文档中添加 `<!-- BREAKING: 说明 -->`
- 更新对应文档 `change_log`
- 明确指出哪些模块技术设计文档需要重新检查

## 7. 与模块技术设计文档的联动规则

架构层文档更新后，要检查是否影响模块技术设计文档：

- 如果只是展示层、交互层变化，通常不影响架构层文档
- 如果架构层文档中的服务职责、数据归属、契约或流程改变，必须重新检查模块技术设计文档

至少检查：
- 是否需要调整模块划分
- 是否需要调整 API 设计
- 是否需要调整数据库设计
- 是否需要调整中间件/异步流程设计

## 8. 更新风格

更新架构层文档时：
- 保留当前有效结论，不写成长篇讨论记录
- 只保留对当前架构仍然有效的内容
- 对被删除的旧结论，不做“墓碑式保留”
- 通过 `change_log` 和 `BREAKING` 标记记录必要历史

## 9. 一个简单记忆法

可以用下面这句话快速判断：

`边界不变，不改架构层；职责变了，改边界；流程变了，改流程；骨架变了，改主文档。`
