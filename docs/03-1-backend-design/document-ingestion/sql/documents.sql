CREATE TABLE documents (
    id VARCHAR(32) PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(64) NOT NULL,
    file_size_bytes BIGINT NOT NULL CHECK (file_size_bytes > 0),
    status VARCHAR(32) NOT NULL,
    status_message VARCHAR(128) NOT NULL,
    page_count INTEGER,
    chunk_count INTEGER,
    progress_percent INTEGER NOT NULL DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
    error_code VARCHAR(64),
    error_message VARCHAR(255),
    preview_ready BOOLEAN NOT NULL DEFAULT FALSE,
    cancel_requested_at TIMESTAMPTZ,
    ready_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_documents_status CHECK (
        status IN (
            'uploaded',
            'parsing',
            'chunking',
            'indexing',
            'ready',
            'failed',
            'cancelling',
            'cancelled'
        )
    )
);

CREATE INDEX idx_documents_status_updated_at
    ON documents (status, updated_at DESC);
