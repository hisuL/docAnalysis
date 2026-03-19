# Backend Services

## Services

- `conversation-orchestrator`: 问答、会话管理、摘要生成
- `document-ingestion`: 文档上传、解析、切片、embedding

## Quick Start

```bash
# 安装依赖
cd conversation-orchestrator
pip install -e ".[dev]"

# 配置环境变量
cp .env.example .env

# 方式 1: 使用 uvicorn 直接运行
uvicorn conversation_orchestrator.main:app --reload

# 方式 2: 使用入口点命令
conversation-orchestrator
```

## Health Endpoints

- `/livez` - Liveness 探针（服务是否运行）
- `/readyz` - Readiness 探针（依赖是否就绪）
- `/health` - 传统健康检查端点
