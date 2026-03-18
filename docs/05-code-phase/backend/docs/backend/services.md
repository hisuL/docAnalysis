# 服务层设计规范

## 1. 服务层职责

服务层是业务逻辑的核心，负责：
- 实现业务规则
- 管理事务边界
- 调用外部服务
- 处理异常和错误
- 数据转换和校验

## 2. 服务分层

```
Controller (API层)
    ↓
Service (业务逻辑层)
    ↓
Repository (数据访问层)
    ↓
Model (数据模型层)
```

## 3. 服务设计原则

### 3.1 单一职责
每个服务类只负责一个业务领域：
```python
class DocumentIngestionService:
    """文档上传服务"""
    pass

class DocumentProcessingService:
    """文档处理服务"""
    pass
```

### 3.2 依赖注入
通过构造函数注入依赖：
```python
class DocumentService:
    def __init__(
        self,
        session: AsyncSession,
        storage: StorageService,
        mq: MessageQueue
    ):
        self.session = session
        self.storage = storage
        self.mq = mq
```

### 3.3 接口抽象
定义服务接口，便于测试和替换：
```python
from abc import ABC, abstractmethod

class StorageService(ABC):
    @abstractmethod
    async def upload(self, key: str, data: bytes) -> str:
        pass
```

## 4. 事务管理

### 4.1 事务边界
服务方法是事务边界：
```python
async def create_document(
    self,
    data: DocumentCreate
) -> Document:
    async with self.session.begin():
        doc = Document(**data.dict())
        self.session.add(doc)
        await self.session.flush()
        return doc
```

### 4.2 跨服务事务
避免分布式事务，使用最终一致性：
```python
async def commit_document(self, doc_id: str):
    # 1. 更新文档状态
    async with self.session.begin():
        doc = await self.get_document(doc_id)
        doc.status = "processing"

    # 2. 发送消息队列（异步）
    await self.mq.publish("document.committed", {"doc_id": doc_id})
```

## 5. 异常处理

### 5.1 自定义异常
```python
class DocumentNotFoundError(BusinessException):
    def __init__(self, doc_id: str):
        super().__init__(
            code="DOC_404",
            message=f"Document {doc_id} not found"
        )

class DocumentStatusError(BusinessException):
    def __init__(self, doc_id: str, status: str):
        super().__init__(
            code="DOC_409",
            message=f"Document {doc_id} status is {status}"
        )
```

### 5.2 异常处理
```python
async def get_document(self, doc_id: str) -> Document:
    doc = await self.session.get(Document, doc_id)
    if not doc:
        raise DocumentNotFoundError(doc_id)
    return doc
```

## 6. 数据转换

### 6.1 DTO 转 Model
```python
def create_document(self, data: DocumentCreate) -> Document:
    return Document(
        doc_id=generate_doc_id(),
        filename=data.filename,
        file_size=data.file_size,
        status="initialized"
    )
```

### 6.2 Model 转 DTO
```python
def to_response(self, doc: Document) -> DocumentResponse:
    return DocumentResponse(
        doc_id=doc.doc_id,
        filename=doc.filename,
        status=doc.status,
        created_at=doc.created_at
    )
```

## 7. 外部服务调用

### 7.1 对象存储
```python
class S3StorageService:
    async def upload(self, key: str, data: bytes) -> str:
        try:
            await self.client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=data
            )
            return f"s3://{self.bucket}/{key}"
        except Exception as e:
            logger.error(f"Upload failed: {e}")
            raise StorageError("Upload failed")
```

### 7.2 消息队列
```python
class RabbitMQService:
    async def publish(self, event: str, data: dict):
        try:
            await self.channel.basic_publish(
                exchange="",
                routing_key=event,
                body=json.dumps(data)
            )
        except Exception as e:
            logger.error(f"Publish failed: {e}")
            raise MQError("Publish failed")
```

### 7.3 LLM 调用
```python
class LLMService:
    async def generate(
        self,
        messages: List[dict],
        stream: bool = False
    ):
        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                stream=stream
            )
            return response
        except Exception as e:
            logger.error(f"LLM call failed: {e}")
            raise LLMError("Generation failed")
```

## 8. 并发控制

### 8.1 乐观锁
```python
async def update_document_status(
    self,
    doc_id: str,
    status: str
) -> Document:
    async with self.session.begin():
        stmt = (
            update(Document)
            .where(Document.doc_id == doc_id)
            .where(Document.version == version)
            .values(status=status, version=version + 1)
        )
        result = await self.session.execute(stmt)
        if result.rowcount == 0:
            raise DocumentVersionError(doc_id)
```

### 8.2 悲观锁
```python
async def acquire_processing_lock(self, doc_id: str):
    async with self.session.begin():
        stmt = (
            select(Document)
            .where(Document.doc_id == doc_id)
            .with_for_update()
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()
```

## 9. 缓存策略

### 9.1 缓存装饰器
```python
from functools import wraps

def cache(ttl: int = 300):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            key = f"{func.__name__}:{args}:{kwargs}"
            cached = await redis.get(key)
            if cached:
                return json.loads(cached)

            result = await func(*args, **kwargs)
            await redis.setex(key, ttl, json.dumps(result))
            return result
        return wrapper
    return decorator
```

### 9.2 缓存失效
```python
async def update_document(self, doc_id: str, data: dict):
    async with self.session.begin():
        # 更新数据库
        await self.session.execute(...)

    # 清除缓存
    await redis.delete(f"document:{doc_id}")
```

## 10. 日志记录

### 10.1 结构化日志
```python
import structlog

logger = structlog.get_logger()

async def create_document(self, data: DocumentCreate):
    logger.info(
        "document_create_start",
        filename=data.filename,
        file_size=data.file_size
    )

    doc = await self._create(data)

    logger.info(
        "document_create_success",
        doc_id=doc.doc_id
    )

    return doc
```

### 10.2 错误日志
```python
try:
    result = await self.process()
except Exception as e:
    logger.error(
        "process_failed",
        error=str(e),
        exc_info=True
    )
    raise
```

## 11. 测试规范

### 11.1 单元测试
```python
import pytest
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_create_document():
    # Arrange
    session = AsyncMock()
    storage = AsyncMock()
    service = DocumentService(session, storage)

    data = DocumentCreate(
        filename="test.pdf",
        file_size=1024
    )

    # Act
    result = await service.create_document(data)

    # Assert
    assert result.doc_id is not None
    assert result.status == "initialized"
```

### 11.2 集成测试
```python
@pytest.mark.asyncio
async def test_document_flow(db_session):
    service = DocumentService(db_session)

    # 创建文档
    doc = await service.create_document(data)

    # 上传文件
    await service.upload_file(doc.doc_id, file_data)

    # 提交处理
    await service.commit_document(doc.doc_id)

    # 验证状态
    doc = await service.get_document(doc.doc_id)
    assert doc.status == "processing"
```

## 12. 性能优化

### 12.1 批量操作
```python
async def create_chunks_batch(
    self,
    chunks: List[ChunkCreate]
):
    async with self.session.begin():
        chunk_models = [
            DocumentChunk(**chunk.dict())
            for chunk in chunks
        ]
        self.session.add_all(chunk_models)
```

### 12.2 异步并发
```python
import asyncio

async def process_multiple_documents(
    self,
    doc_ids: List[str]
):
    tasks = [
        self.process_document(doc_id)
        for doc_id in doc_ids
    ]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return results
```
