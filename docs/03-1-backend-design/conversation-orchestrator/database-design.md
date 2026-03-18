# Conversation Orchestrator 数据库设计

## 1. 文档说明

**服务名称**: conversation-orchestrator
**Schema**: conversation
**数据库**: PostgreSQL 15+

## 2. 表设计

### 2.1 sessions 表

**用途**: 存储会话信息

```sql
CREATE TABLE conversation.sessions (
    id VARCHAR(64) PRIMARY KEY,
    doc_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_doc_id ON conversation.sessions(doc_id);
CREATE INDEX idx_sessions_updated_at ON conversation.sessions(updated_at DESC);
```

### 2.2 conversations 表

**用途**: 存储对话历史

```sql
CREATE TABLE conversation.conversations (
    id VARCHAR(64) PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL REFERENCES conversation.sessions(id) ON DELETE CASCADE,
    doc_id VARCHAR(64) NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    citations JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_conversations_session_id ON conversation.conversations(session_id);
CREATE INDEX idx_conversations_created_at ON conversation.conversations(created_at DESC);
```

**citations 字段格式**:
```json
[
  {
    "chunk_id": "chunk_001",
    "page_num": 5,
    "text": "引用文本片段",
    "relevance": 0.92
  }
]
```

### 2.3 summaries 表

**用途**: 存储文档摘要和推荐问题

```sql
CREATE TABLE conversation.summaries (
    id BIGSERIAL PRIMARY KEY,
    doc_id VARCHAR(64) NOT NULL UNIQUE,
    summary TEXT NOT NULL,
    suggested_questions JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_summaries_doc_id ON conversation.summaries(doc_id);
```

### 2.4 feedbacks 表

**用途**: 存储用户反馈

```sql
CREATE TABLE conversation.feedbacks (
    id VARCHAR(64) PRIMARY KEY,
    message_id VARCHAR(64) NOT NULL,
    session_id VARCHAR(64) NOT NULL REFERENCES conversation.sessions(id) ON DELETE CASCADE,
    feedback_type VARCHAR(10) NOT NULL,
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_feedback_type CHECK (feedback_type IN ('good', 'bad'))
);

CREATE INDEX idx_feedbacks_message_id ON conversation.feedbacks(message_id);
CREATE INDEX idx_feedbacks_session_id ON conversation.feedbacks(session_id);
```

## 3. 常用查询

### 3.1 向量检索（doc_id 隔离）

```sql
SELECT
    c.id,
    c.text,
    c.page_num,
    1 - (e.embedding <=> $1::vector) as similarity
FROM ingestion.chunks c
JOIN ingestion.embeddings e ON c.id = e.chunk_id
WHERE c.doc_id = $2
  AND 1 - (e.embedding <=> $1::vector) > 0.7
ORDER BY e.embedding <=> $1::vector
LIMIT 5;
```

### 3.2 获取会话历史

```sql
SELECT question, answer, citations
FROM conversation.conversations
WHERE session_id = $1
ORDER BY created_at DESC
LIMIT 3;
```

### 3.3 保存对话

```sql
INSERT INTO conversation.conversations (id, session_id, doc_id, question, answer, citations)
VALUES ($1, $2, $3, $4, $5, $6);
```
