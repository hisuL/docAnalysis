CREATE TABLE ingestion_jobs (
    id VARCHAR(32) PRIMARY KEY,
    doc_id VARCHAR(32) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    job_type VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    current_stage VARCHAR(32) NOT NULL,
    attempt INTEGER NOT NULL DEFAULT 0 CHECK (attempt >= 0),
    max_attempts INTEGER NOT NULL DEFAULT 3 CHECK (max_attempts > 0),
    cancel_requested BOOLEAN NOT NULL DEFAULT FALSE,
    locked_by VARCHAR(64),
    locked_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    deadline_at TIMESTAMPTZ NOT NULL,
    last_error_code VARCHAR(64),
    last_error_message TEXT,
    stage_payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_ingestion_jobs_type CHECK (job_type = 'ingest_document'),
    CONSTRAINT chk_ingestion_jobs_status CHECK (
        status IN (
            'pending',
            'running',
            'succeeded',
            'failed',
            'cancel_requested',
            'cancelled'
        )
    ),
    CONSTRAINT chk_ingestion_jobs_stage CHECK (
        current_stage IN (
            'upload_ack',
            'parsing',
            'chunking',
            'indexing',
            'finalizing'
        )
    )
);

CREATE UNIQUE INDEX uk_ingestion_jobs_active_doc
    ON ingestion_jobs (doc_id)
    WHERE status IN ('pending', 'running', 'cancel_requested');

CREATE INDEX idx_ingestion_jobs_polling
    ON ingestion_jobs (status, deadline_at, created_at);
