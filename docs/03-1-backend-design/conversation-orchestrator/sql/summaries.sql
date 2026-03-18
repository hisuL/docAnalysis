-- 文档摘要表
-- 版本: 1.0.0
-- 日期: 2026-03-17

CREATE TABLE conversation.summaries (
    id BIGSERIAL PRIMARY KEY,
    doc_id VARCHAR(64) NOT NULL UNIQUE,
    summary TEXT NOT NULL,
    suggested_questions JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_summaries_doc_id ON conversation.summaries(doc_id);
