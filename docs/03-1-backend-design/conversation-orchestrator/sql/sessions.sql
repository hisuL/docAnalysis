-- 会话表
-- 版本: 1.0.0
-- 日期: 2026-03-17

CREATE TABLE conversation.sessions (
    id VARCHAR(64) PRIMARY KEY,
    doc_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_doc_id ON conversation.sessions(doc_id);
CREATE INDEX idx_sessions_updated_at ON conversation.sessions(updated_at DESC);
