CREATE TABLE document_chunks (
    id VARCHAR(40) PRIMARY KEY,
    doc_id VARCHAR(32) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_seq INTEGER NOT NULL CHECK (chunk_seq > 0),
    page_num INTEGER NOT NULL CHECK (page_num > 0),
    page_num_end INTEGER NOT NULL CHECK (page_num_end >= page_num),
    title_path JSONB NOT NULL DEFAULT '[]'::jsonb,
    chunk_text TEXT NOT NULL CHECK (length(trim(chunk_text)) > 0),
    token_count INTEGER NOT NULL CHECK (token_count > 0),
    chunk_strategy VARCHAR(32) NOT NULL,
    anchor_id VARCHAR(40) NOT NULL,
    anchor_excerpt VARCHAR(255) NOT NULL,
    anchor_bbox_json JSONB,
    embedding VECTOR(1024) NOT NULL,
    embedding_model VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_document_chunks_doc_seq UNIQUE (doc_id, chunk_seq),
    CONSTRAINT uk_document_chunks_doc_anchor UNIQUE (doc_id, anchor_id),
    CONSTRAINT chk_document_chunks_strategy CHECK (
        chunk_strategy IN ('markdown_header', 'token_fallback')
    )
);

CREATE INDEX idx_document_chunks_doc_page
    ON document_chunks (doc_id, page_num, chunk_seq);

CREATE INDEX idx_document_chunks_doc_anchor
    ON document_chunks (doc_id, anchor_id);
