---
version: 1.0.0
status: draft
modules:
  - document-ingestion
  - conversation-orchestrator
change_log:
  - version: 1.0.0
    date: 2026-03-17
    changes: 新增跨服务流程文档，承载关键成功路径和异常路径
---

# 集成流程

## 1. 目标

本文件只描述跨服务协作流程，不进入服务内部代码或组件设计。

## 2. 流程一：文档上传到可问答

```mermaid
sequenceDiagram
    participant Client as Web Client
    participant Ingestion as document-ingestion
    participant Storage as SeaweedFS
    participant DB as PostgreSQL/pgvector
    participant Model as litellm/Embedding

    Client->>Ingestion: 上传 PDF 与基础元数据
    Ingestion->>Storage: 保存原始 PDF
    Ingestion->>DB: 创建文档记录(status=uploaded)
    Ingestion->>Ingestion: 触发解析、切片、向量化内部任务
    Ingestion-->>Client: 返回 doc_id 与处理中状态

    Ingestion->>Storage: 读取原始 PDF
    Ingestion->>DB: 更新解析产物与处理中状态
    Ingestion->>Ingestion: 执行标题优先 + token fallback 切片
    Ingestion->>Model: 批量生成 embeddings
    Ingestion->>DB: 写入 chunk、embedding 与 ready 状态
    Ingestion-->>Client: 返回 ready 状态与预览元数据
```

关键点：
- 上传返回要快，重处理在服务内部异步完成
- `ready` 前不允许进入问答主路径
- 引用定位元数据必须在 `ready` 前准备完毕

## 3. 流程二：单文档问答

```mermaid
sequenceDiagram
    participant Client as Web Client
    participant Conversation as conversation-orchestrator
    participant DB as PostgreSQL/pgvector
    participant LLM as litellm/LLM

    Client->>Conversation: 发送问题(doc_id, message, recent_history)
    Conversation->>DB: 在 doc_id 范围内检索 Top-K chunks
    Conversation->>Conversation: 做相关性阈值判断与引用装配
    Conversation->>LLM: 注入上下文生成回答
    LLM-->>Conversation: 流式返回 tokens
    Conversation-->>Client: 流式回答与引用锚点
```

关键点：
- 必须严格按 `doc_id` 检索
- 低相关必须拒答
- 回答必须带引用锚点

## 4. 关键异常路径

### 4.1 上传失败

- 无效文件在 `document-ingestion` 入口直接拦截
- 不进入后续处理链路

### 4.2 文档处理失败

- 解析、切片、embedding 任一环节失败时，文档状态置为 `failed`
- 对外只返回稳定失败摘要，不暴露内部实现细节

### 4.3 处理超时

- 单文档处理链路统一以 5 分钟为超时上限
- 超时后进入 `failed`

### 4.4 问答拒答

- 当检索相关性不足时，`conversation-orchestrator` 直接拒答
- 不允许模型自由发挥

### 4.5 模型服务异常

- 模型不可用时返回失败提示
- 不允许绕过检索或无引用回答
