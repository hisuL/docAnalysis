# Backend Services

## Services

- `conversation-orchestrator`: 问答、会话管理、摘要生成
- `document-ingestion`: 文档上传、解析、切片、embedding

## Quick Start

```bash
cd conversation-orchestrator
pip install -e ".[dev]"
cp .env.example .env
uvicorn main:app --reload
```
