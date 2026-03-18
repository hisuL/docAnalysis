-- 对话历史表
-- 版本: 1.0.0
-- 日期: 2026-03-17

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
