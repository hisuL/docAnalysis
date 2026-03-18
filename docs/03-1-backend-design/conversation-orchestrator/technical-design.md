# Conversation Orchestrator 技术设计文档

## 1. 文档说明

**服务名称**: conversation-orchestrator
**版本**: 1.0.0
**更新日期**: 2026-03-17

## 2. 技术栈

- **Web 框架**: FastAPI 0.109+
- **异步运行时**: uvicorn + asyncio
- **ORM**: SQLAlchemy 2.0 (async)
- **数据库**: PostgreSQL 15+ with pgvector
- **模型接入**: litellm
- **任务队列**: Celery + Redis

## 3. 核心模块设计

### 3.1 检索模块 (Retrieval Service)

**职责**: 在指定 doc_id 范围内检索相关 chunk

**关键实现**:

```python
from typing import List, Dict
import asyncpg
from litellm import aembedding

class RetrievalService:
    def __init__(self, db_pool: asyncpg.Pool):
        self.db_pool = db_pool

    async def retrieve_chunks(
        self,
        doc_id: str,
        query: str,
        top_k: int = 5,
        threshold: float = 0.7
    ) -> List[Dict]:
        """检索相关 chunk（严格 doc_id 隔离）"""

        # 1. 生成查询向量
        response = await aembedding(
            model="text-embedding-3-small",
            input=query
        )
        query_embedding = response["data"][0]["embedding"]

        # 2. 向量检索（必须包含 doc_id 过滤）
        async with self.db_pool.acquire() as conn:
            chunks = await conn.fetch("""
                SELECT
                    c.id,
                    c.text,
                    c.page_num,
                    1 - (e.embedding <=> $1::vector) as similarity
                FROM ingestion.chunks c
                JOIN ingestion.embeddings e ON c.id = e.chunk_id
                WHERE c.doc_id = $2
                  AND 1 - (e.embedding <=> $1::vector) > $3
                ORDER BY e.embedding <=> $1::vector
                LIMIT $4
            """, query_embedding, doc_id, threshold, top_k)

        return [dict(chunk) for chunk in chunks]
```

### 3.2 问答模块 (QA Service)

**职责**: 基于检索结果生成回答

```python
from litellm import acompletion
from typing import AsyncGenerator

class QAService:
    def __init__(self, retrieval_service: RetrievalService):
        self.retrieval = retrieval_service

    async def answer_question(
        self,
        doc_id: str,
        question: str,
        history: List[Dict] = None
    ) -> AsyncGenerator:
        """生成流式回答"""

        # 1. 检索相关 chunk
        chunks = await self.retrieval.retrieve_chunks(doc_id, question)

        if not chunks:
            yield {"type": "error", "code": 2005, "msg": "抱歉，我在文档中没有找到相关内容"}
            return

        # 2. 构建 prompt
        context = "\n\n".join([f"[{i+1}] {c['text']}" for i, c in enumerate(chunks)])
        messages = self._build_messages(question, context, history)

        # 3. 流式生成回答
        stream = await acompletion(model="gpt-4", messages=messages, stream=True)

        async for chunk in stream:
            if chunk.choices[0].delta.content:
                yield {"type": "token", "content": chunk.choices[0].delta.content}

        # 4. 返回引用
        citations = [{"chunk_id": c["id"], "page_num": c["page_num"]} for c in chunks]
        yield {"type": "citations", "content": citations}
        yield {"type": "done"}
```

### 3.3 会话模块 (Session Service)

```python
class SessionService:
    async def save_conversation(
        self,
        session_id: str,
        doc_id: str,
        question: str,
        answer: str,
        citations: List[Dict]
    ) -> str:
        """保存对话"""
        message_id = f"msg_{int(time.time())}_{random.randint(1000, 9999)}"

        async with self.db_pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO conversation.conversations
                (id, session_id, doc_id, question, answer, citations)
                VALUES ($1, $2, $3, $4, $5, $6)
            """, message_id, session_id, doc_id, question, answer, json.dumps(citations))

        return message_id
```

## 4. API 路由设计

```python
from fastapi import APIRouter
from fastapi.responses import StreamingResponse

router = APIRouter(prefix="/api/v1/conversations")

@router.post("/ask")
async def ask_question(request: AskRequest):
    """发起问答"""

    async def generate():
        async for chunk in qa_service.answer_question(
            request.doc_id,
            request.question
        ):
            yield f"data: {json.dumps(chunk)}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")
```

## 5. 性能要求

根据 PRD 验收标准：

- **首字延迟**: ≤ 3 秒（本地环境）
- **流式响应**: 打字机效果逐字展示
- **多轮对话**: 保留最近 10 轮对话历史

## 6. 配置管理

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # 数据库
    DATABASE_URL: str
    DB_POOL_SIZE: int = 20

    # Redis
    REDIS_URL: str

    # 模型
    LITELLM_MODEL: str = "gpt-4"
    EMBEDDING_MODEL: str = "text-embedding-3-small"

    # 检索参数
    RETRIEVAL_TOP_K: int = 5
    RELEVANCE_THRESHOLD: float = 0.7

    # 会话参数
    MAX_HISTORY_ROUNDS: int = 10  # 保留最近 10 轮对话

    class Config:
        env_file = ".env"
```
