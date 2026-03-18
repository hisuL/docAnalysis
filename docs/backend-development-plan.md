# ChatFile 后端开发技术方案

## 1. 项目概述

### 1.1 项目定位
ChatFile 是一个极简的 RAG（检索增强生成）应用，核心流程为：**上传PDF → 自动解析切片 → 多轮对话问答**

### 1.2 核心目标
- 用户上传单个PDF（≤100MB），系统自动完成解析、切片、向量化
- 支持基于当前文档的多轮对话，每个回答都能溯源到原文
- 首字延迟≤3秒，文档处理5分钟内完成
- 严格限定检索范围在当前文档，禁止跨文档召回

### 1.3 目标用户
IC设计/验证工程师、FAE，需要快速从Datasheet中查找参数

---

## 2. 技术架构

### 2.1 后端框架与服务拆分
- **框架选型**：FastAPI（Python异步框架，适合流式输出和异步任务）
- **服务架构**：双服务架构
  - `knowledge-base-service`：文档知识服务（文档上传、解析、切片、向量化、索引）
  - `qa-service`：问答服务（检索、生成、会话、引用装配、反馈）

### 2.2 核心技术栈

| 组件 | 选型 | 用途 |
|------|------|------|
| **RAG编排** | Haystack | 组件化编排解析、检索、生成流程 |
| **向量存储** | pgvector | 向量检索与doc_id过滤 |
| **模型接入** | LiteLLM | 统一屏蔽LLM/Embedding服务差异 |
| **文件存储** | S3兼容对象存储 | 原始PDF和解析产物 |
| **消息队列** | RabbitMQ/Kafka | 异步处理流水线触发 |
| **数据库** | PostgreSQL | 主数据、状态、会话存储 |

### 2.3 系统架构图

```
┌─────────────┐
│   前端应用   │
└──────┬──────┘
       │ HTTP/SSE
       ▼
┌─────────────────────────────────────┐
│          API Gateway                │
│    (身份认证、路由、限流)            │
└──────┬──────────────────┬───────────┘
       │                  │
       ▼                  ▼
┌──────────────┐   ┌──────────────┐
│ knowledge-   │   │  qa-service  │
│ base-service │   │              │
└──────┬───────┘   └──────┬───────┘
       │                  │
       ├──────────────────┤
       │                  │
       ▼                  ▼
┌─────────────────────────────────────┐
│         PostgreSQL + pgvector       │
└─────────────────────────────────────┘
       │                  │
       ▼                  ▼
┌──────────────┐   ┌──────────────┐
│ 对象存储(S3) │   │  消息队列    │
└──────────────┘   └──────────────┘
```

---

## 3. 模块设计

### 3.1 模块1：document-ingestion（文档上传）

**职责**：单文档上传闭环

**核心功能**：
- NI2三段式上传流程：`init` → `file` → `commit`
- 生成唯一`doc_id`和上传令牌
- 文档状态机：`initialized` → `uploaded` → `processing` → `ready/failed`
- 支持取消、重试、更换文档

**关键API**：
```
POST   /api/v1/documents/init              # 初始化上传会话
PUT    /api/v1/documents/{doc_id}/file     # 上传PDF文件
POST   /api/v1/documents/{doc_id}/commit   # 提交进入处理流水线
GET    /api/v1/documents/{doc_id}          # 查询文档状态
POST   /api/v1/documents/{doc_id}/cancel   # 取消上传/处理
POST   /api/v1/documents/{doc_id}/retry    # 失败重试
```

**数据表**：
- `documents`：文档主记录、状态、文件引用
- `document_upload_sessions`：上传会话、令牌、进度

---

### 3.2 模块2：document-processing-pipeline（文档处理）

**职责**：异步处理流水线（解析→切片→向量化→索引）

**核心流程**：
1. **Parse阶段**：PDF→Markdown（使用Docling或类似解析器）
2. **Chunk阶段**：按Markdown标题优先切分，token兜底（512+50overlap）
3. **Embed-Index阶段**：生成embedding，批量写入pgvector

**关键特性**：
- 单文档总超时5分钟
- 支持阶段级重试和版本化重建
- 预览状态可先于索引就绪
- 活跃版本切换原子性保证

**内部接口**（仅供qa-service调用）：
```
GET    /internal/v1/documents/{doc_id}/processing-result    # 查询处理摘要
GET    /internal/v1/documents/{doc_id}/chunks                # 查询活跃chunk
POST   /internal/v1/documents/{doc_id}/rebuild               # 受控重建
```

**数据表**：
- `document_processing_jobs`：任务记录、阶段、错误
- `document_parse_artifacts`：解析产物（Markdown）
- `document_chunks`：chunk元数据、引用定位、活跃版本标记
- `document_processing_results`：对外处理结果摘要

---

### 3.3 模块3：document-qa（问答交互）

**职责**：单文档问答闭环

**核心功能**：
- 创建聊天会话（绑定doc_id）
- 流式问答（SSE输出）
- 维护最近10轮上下文
- 引用装配、摘要推荐、反馈记录

**关键API**：
```
POST   /api/v1/chat-sessions                              # 创建会话
GET    /api/v1/chat-sessions/{session_id}                 # 查询会话
GET    /api/v1/chat-sessions/{session_id}/messages        # 历史消息
POST   /api/v1/chat-sessions/{session_id}/messages:stream # 流式问答(SSE)
POST   /api/v1/chat-sessions/{session_id}/stop            # 停止生成
GET    /api/v1/messages/{message_id}/citations            # 引用来源视图
GET    /api/v1/documents/{doc_id}/overview                # 摘要+推荐问题
POST   /api/v1/messages/{message_id}/feedback             # 提交反馈
```

**数据表**：
- `chat_sessions`：会话与doc_id绑定
- `chat_messages`：用户和assistant消息
- `chat_generation_runs`：生成运行状态、检索摘要、锚点索引
- `message_citation_views`：引用来源视图（页码、章节、高亮定位）
- `document_overviews`：文档摘要与推荐问题
- `message_feedbacks`：用户反馈

---

## 4. 数据库设计

### 4.1 核心设计原则
1. **单一事实来源**：每个模块主拥有的数据只在该模块写入
2. **版本化管理**：chunk支持多版本，只有一个活跃版本
3. **最终一致性**：摘要、推荐问题、反馈允许异步更新
4. **跨服务边界**：`doc_id`、`chunk_id`、`session_id`为稳定标识

### 4.2 关键表设计

| 表 | 所有者 | 关键字段 |
|----|-------|---------|
| `documents` | ingestion | doc_id, status, storage_key |
| `document_chunks` | processing | chunk_id, doc_id, version_no, is_active |
| `chat_sessions` | qa | session_id, doc_id |
| `chat_generation_runs` | qa | run_id, citation_anchor_map |

### 4.3 索引策略
- `documents(owner_user_id, created_at desc)` - 用户文档列表
- `document_chunks(doc_id, is_active, chunk_index)` - 活跃chunk查询
- `chat_messages(session_id, created_at asc)` - 历史消息恢复
- `chat_generation_runs(session_id, run_status)` - 运行状态查询

---

## 5. API设计规范

### 5.1 接口分层
- **前端接口** (`/api/v1/...`)：网关透传身份上下文
- **内部接口** (`/internal/v1/...`)：仅服务间调用，静态token鉴权

### 5.2 统一响应格式
```json
{
  "code": 0,
  "msg": "success",
  "data": {}
}
```

### 5.3 错误码体系
- `DOC_4xx`：文档模块错误
- `PROC_4xx`：处理模块错误
- `QA_4xx`：问答模块错误

### 5.4 幂等性设计
- `commit`：使用`client_request_id + doc_id`
- `retry`：使用`doc_id + 失败版本号`
- `feedback`：使用`message_id + owner_user_id` upsert

---

## 6. 关键技术难点与解决方案

### 6.1 PDF解析质量与chunk质量
**问题**：解析质量直接影响后续检索和回答准确性

**方案**：
- 采用Docling等成熟解析器
- 保留解析器适配层，便于后续切换
- 解析失败时进入失败态，支持重试
- 记录解析产物便于排查

### 6.2 并发场景下的状态一致性
**问题**：文档处理中被取消、重试等并发操作

**方案**：
- 单文档只允许一个活跃任务
- 每阶段启动前检查`cancel_requested_at`
- 使用乐观锁或行锁抢占任务
- 版本号隔离不同处理版本

### 6.3 流式输出与引用锚点同步
**问题**：引用锚点需要与token流式输出同步

**方案**：
- 先输出token占位符`[1]`
- 后续通过`citation_anchor`事件补发具体chunk_id
- 前端先展示占位符，完成后可点击跳转

### 6.4 向量检索的doc_id隔离
**问题**：必须严格限定检索范围在当前文档

**方案**：
- pgvector查询时强制`WHERE doc_id = ?`过滤
- 不依赖向量相似度自动隔离
- 检索失败时直接返回无答案，不做降级

### 6.5 首字延迟控制
**问题**：首字延迟需≤3秒

**方案**：
- 检索和生成在请求上下文内同步完成
- 不引入后台异步任务
- 使用流式输出，首token尽快返回
- 监控首字延迟指标

### 6.6 活跃版本切换的原子性
**问题**：chunk版本切换时需保证一致性

**方案**：
- 新版本chunk写入完成前，旧版本保持活跃
- 仅在embed-index全部成功后执行批量更新
- 失败时不删除中间数据，支持重试
- 使用事务保证切换原子性

---

## 7. 开发规范

### 7.1 工作流纪律（参考CLAUDE.md）
1. **接单与建分支**：获取 PingCode 任务后，必须先创建格式为 `feat/REQ-{ID}` 或 `fix/BUG-{ID}` 的工作分支
2. **契约先行**：在编写具体 Controller 逻辑前，必须先定义好 DTO 和接口路径，并同步至 YAPI
3. **本地自测**：提交代码前，必须在本地运行单元测试，核心业务逻辑单测覆盖率必须 > 95%
4. **规范提交**：Commit Message 必须遵循 Angular 规范（如：`feat(order): 新增订单分页查询接口`）
5. **触发流水线**：代码 Push 并创建 PR 后，触发冒烟与全量测试

### 7.2 编码红线
- **RESTful API 规范**：所有的 API 必须返回统一的响应结构体
- **数据库与事务**：所有涉及 `INSERT`, `UPDATE`, `DELETE` 的操作，必须在 Service 层添加事务注解
- **严禁**在代码中直接拼接 SQL，必须使用预编译的 ORM 框架防止 SQL 注入
- **异常处理**：严禁"吞没"异常，必须使用日志框架记录带堆栈信息的 ERROR 日志

---

## 8. 部署与运维

### 8.1 服务部署
- `knowledge-base-service`：可独立扩容，处理CPU密集任务
- `qa-service`：可独立扩容，处理并发问答请求
- 共享PostgreSQL、pgvector、对象存储、消息队列

### 8.2 监控指标
- 文档处理耗时（P50/P95/P99）
- 首字延迟
- 无答案命中率
- LLM超时率
- 向量检索耗时
- 消息队列堆积量

### 8.3 故障处理
- 孤儿文件清理任务
- 死信队列监控
- 处理超时告警
- 检索失败降级（返回无答案）

---

## 9. 开发里程碑

### 阶段1：基础设施搭建（Week 1）
- 项目脚手架搭建
- 数据库表结构设计与创建
- 对象存储、消息队列配置
- CI/CD流水线配置

### 阶段2：文档上传模块（Week 2）
- 实现NI2三段式上传流程
- 文档状态机管理
- 取消、重试功能

### 阶段3：文档处理流水线（Week 3-4）
- PDF解析集成
- Chunk切分逻辑
- 向量化与索引
- 异步任务处理

### 阶段4：问答模块（Week 5-6）
- 会话管理
- 流式问答实现
- 引用装配
- 反馈收集

### 阶段5：联调与优化（Week 7）
- 前后端联调
- 性能优化
- 监控告警配置
- 文档完善

---

## 10. 风险与应对

| 风险 | 影响 | 应对措施 |
|------|------|---------|
| PDF解析质量不稳定 | 影响问答准确性 | 预留解析器适配层，支持切换 |
| 向量检索性能瓶颈 | 首字延迟超标 | pgvector索引优化，考虑引入缓存 |
| LLM服务不稳定 | 问答失败率高 | 超时重试、降级策略 |
| 文档处理超时 | 用户体验差 | 分阶段处理，支持预览 |
| 并发冲突 | 数据不一致 | 乐观锁、行锁、版本号隔离 |

---

**文档版本**：v1.0
**最后更新**：2026-03-16
**负责人**：后端开发团队
