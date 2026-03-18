-- 反馈表
-- 版本: 1.0.0
-- 日期: 2026-03-17

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
