# ARCHITECTURE.md

## 1. 文档目的

本文档定义后端系统的服务边界、模块划分、依赖方向和核心架构约束。让开发者和 AI 在改动代码前快速知道：服务如何拆分、模块如何划分、依赖如何流动、新功能落在哪一层。

## 2. 项目概览

- 项目名称：ChatFile
- 业务目标：极简 RAG 应用，上传PDF → 自动解析切片 → 多轮对话问答
- 当前阶段：开发阶段
- 核心技术栈：FastAPI · Python 3.11+ · PostgreSQL + pgvector · Haystack · LiteLLM · RabbitMQ

## 3. 架构原则

- **服务拆分**：按业务领域拆分服务，不按技术层拆分
- **单向依赖**：依赖方向单向流动，低层不依赖高层
- **契约先行**：服务间通过明确的 API 契约通信
- **数据隔离**：每个服务主拥有自己的数据表
- **异步解耦**：长时间处理任务通过消息队列异步执行

## 4. 服务架构

### 4.1 服务拆分

```
┌─────────────────────────────────────┐
│          API Gateway                │
│    (身份认证、路由、限流)            │
└──────┬──────────────────┬───────────┘
       │                  │
       ▼                  ▼
┌──────────────┐   ┌──────────────┐
│ knowledge-   │   │  qa-service  │
│ base-service │   │              │
│              │   │              │
│ 文档上传     │   │ 会话管理     │
│ 文档处理     │   │ 流式问答     │
│ 向量索引     │   │ 引用装配     │
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

### 4.2 服务职责

| 服务 | 职责 | 核心模块 |
|------|------|---------|
| **knowledge-base-service** | 文档知识管理 | document-ingestion, document-processing-pipeline |
| **qa-service** | 问答交互 | document-qa |

## 5. 目录结构

### knowledge-base-service
```
knowledge-base-service/
├── app/
│   ├── main.py              # 应用入口
│   ├── config.py            # 配置管理
│   └── dependencies.py      # 依赖注入
├── api/
│   ├── v1/
│   │   ├── documents.py     # 文档上传接口
│   │   └── internal.py      # 内部接口
│   └── middleware/          # 中间件
├── services/
│   ├── ingestion/           # 文档上传服务
│   ├── processing/          # 文档处理服务
│   └── storage/             # 存储服务
├── models/                  # 数据模型（SQLAlchemy）
├── schemas/                 # DTO定义（Pydantic）
├── core/
│   ├── database.py          # 数据库连接
│   ├── mq.py                # 消息队列
│   └── exceptions.py        # 自定义异常
├── workers/                 # 异步任务处理
└── tests/                   # 测试
```

### qa-service
```
qa-service/
├── app/
│   ├── main.py              # 应用入口
│   ├── config.py            # 配置管理
│   └── dependencies.py      # 依赖注入
├── api/
│   ├── v1/
│   │   ├── chat.py          # 聊天接口
│   │   └── messages.py      # 消息接口
│   └── middleware/          # 中间件
├── services/
│   ├── chat/                # 会话管理服务
│   ├── retrieval/           # 检索服务
│   ├── generation/          # 生成服务
│   └── citation/            # 引用装配服务
├── models/                  # 数据模型（SQLAlchemy）
├── schemas/                 # DTO定义（Pydantic）
├── core/
│   ├── database.py          # 数据库连接
│   ├── llm.py               # LLM客户端
│   └── exceptions.py        # 自定义异常
└── tests/                   # 测试
```

## 6. 分层规则

### 6.1 依赖方向

```
api -> services -> models -> core
```

约束：
- `core` 不能依赖 `services`
- `models` 不能依赖 `services`
- `services` 间避免循环依赖
- `api` 只负责路由和参数校验，不写业务逻辑

### 6.2 模块边界

- `api/`：路由定义、请求响应处理、参数校验
- `services/`：业务逻辑实现、事务管理
- `models/`：数据库模型定义（SQLAlchemy ORM）
- `schemas/`：DTO定义（Pydantic）、数据校验
- `core/`：基础设施（数据库、消息队列、配置）
- `workers/`：异步任务处理（消息队列消费者）

## 7. 数据边界

### 7.1 数据所有权

| 表 | 所有者服务 | 写权限 | 读权限 |
|----|-----------|--------|--------|
| `documents` | knowledge-base | 独占 | 共享 |
| `document_chunks` | knowledge-base | 独占 | 共享 |
| `chat_sessions` | qa | 独占 | 独占 |
| `chat_messages` | qa | 独占 | 独占 |

### 7.2 跨服务访问

- **推荐**：通过内部 API 访问（HTTP）
- **禁止**：直接跨服务写数据库
- **允许**：跨服务只读查询（性能优化场景）

## 8. 接口分层

### 8.1 前端接口（/api/v1/...）
- 网关透传身份上下文
- 统一响应格式
- 统一错误处理

### 8.2 内部接口（/internal/v1/...）
- 仅服务间调用
- 静态 token 鉴权
- 不对外暴露

## 9. 状态管理

### 9.1 文档状态机

```
initialized -> uploaded -> processing -> ready
                              ↓
                           failed
```

### 9.2 处理任务状态

```
pending -> running -> completed
              ↓
           failed
```

### 9.3 会话状态

```
active -> archived
```

## 10. 核心约束

### 10.1 事务边界
- 单个 API 请求内的数据库操作必须在同一事务中
- 跨服务操作不使用分布式事务，采用最终一致性
- 长时间处理任务不占用事务连接

### 10.2 并发控制
- 文档处理：单文档只允许一个活跃任务
- 版本切换：使用乐观锁或行锁
- 会话并发：允许同一会话多个请求并发

### 10.3 性能要求
- 首字延迟 ≤ 3秒
- 文档处理 ≤ 5分钟
- API 响应时间 P95 ≤ 500ms

## 11. 扩展点

### 11.1 解析器适配
- 预留解析器适配层
- 支持切换不同的 PDF 解析器

### 11.2 向量存储
- 预留向量存储适配层
- 支持切换不同的向量数据库

### 11.3 LLM 接入
- 使用 LiteLLM 统一接口
- 支持切换不同的 LLM 服务

## 12. 监控与可观测性

### 12.1 日志规范
- 使用结构化日志（JSON 格式）
- 关键操作记录 trace_id
- 敏感信息脱敏

### 12.2 指标监控
- 文档处理耗时（P50/P95/P99）
- 首字延迟
- API 响应时间
- 错误率
- 队列堆积量

### 12.3 告警规则
- 处理超时告警
- 错误率超阈值告警
- 队列堆积告警
