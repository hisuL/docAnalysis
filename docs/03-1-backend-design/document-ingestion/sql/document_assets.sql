CREATE TABLE document_assets (
    id BIGSERIAL PRIMARY KEY,
    doc_id VARCHAR(32) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    asset_type VARCHAR(32) NOT NULL,
    storage_bucket VARCHAR(64) NOT NULL,
    storage_key VARCHAR(255) NOT NULL,
    content_sha256 VARCHAR(64) NOT NULL,
    byte_size BIGINT NOT NULL CHECK (byte_size >= 0),
    metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_document_assets_type CHECK (
        asset_type IN ('source_pdf', 'markdown', 'image_manifest')
    ),
    CONSTRAINT uk_document_assets_doc_type UNIQUE (doc_id, asset_type)
);

CREATE INDEX idx_document_assets_doc_id
    ON document_assets (doc_id);
