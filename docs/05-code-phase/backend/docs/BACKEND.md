# BACKEND.md

## 1. 文档目的

本文档是后端开发规范的总纲，定义技术选型、开发流程、编码规范和质量标准。

## 2. 技术栈

### 2.1 核心框架
- **Web框架**：FastAPI 0.104+
- **Python版本**：3.11+
- **异步运行时**：uvicorn + asyncio

### 2.2 数据存储
- **关系数据库**：PostgreSQL 15+
- **向量存储**：pgvector 扩展
- **对象存储**：S3 兼容存储（MinIO/AWS S3）
- **消息队列**：RabbitMQ 或 Kafka

### 2.3 核心依赖
- **ORM**：SQLAlchemy 2.0+
- **数据校验**：Pydantic 2.0+
- **RAG编排**：Haystack
- **LLM接入**：LiteLLM
- **数据库迁移**：Alembic
- **测试框架**：pytest + pytest-asyncio

## 3. 项目结构

```
backend/
├── knowledge-base-service/    # 文档知识服务
├── qa-service/                # 问答服务
├── shared/                    # 共享代码
│   ├── models/                # 共享数据模型
│   ├── schemas/               # 共享DTO
│   └── utils/                 # 工具函数
├── migrations/                # 数据库迁移
├── tests/                     # 测试
└── scripts/                   # 脚本工具
```

## 4. API 设计规范

### 4.1 路径规范
- 使用小写字母和中划线：`/api/v1/chat-sessions`
- 版本号前缀：`/api/v1/`
- 内部接口：`/internal/v1/`

### 4.2 HTTP 方法
- `GET`：查询资源
- `POST`：创建资源或执行操作
- `PUT`：完整更新资源
- `PATCH`：部分更新资源
- `DELETE`：删除资源

### 4.3 统一响应格式
```python
{
  "code": 0,        # 0表示成功，非0表示错误
  "msg": "success", # 消息描述
  "data": {}        # 响应数据
}
```

### 4.4 错误码规范
- `DOC_4xx`：文档模块错误
- `PROC_4xx`：处理模块错误
- `QA_4xx`：问答模块错误

示例：
- `DOC_404`：文档不存在
- `PROC_500`：处理失败
- `QA_403`：会话无权限

## 5. 数据模型规范

### 5.1 模型定义
使用 SQLAlchemy 2.0 声明式语法：

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from datetime import datetime

class Base(DeclarativeBase):
    pass

class Document(Base):
    __tablename__ = "documents"

    id: Mapped[int] = mapped_column(primary_key=True)
    doc_id: Mapped[str] = mapped_column(unique=True, index=True)
    status: Mapped[str] = mapped_column(index=True)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
```

### 5.2 DTO 定义
使用 Pydantic 定义请求和响应模型：

```python
from pydantic import BaseModel, Field

class DocumentInitRequest(BaseModel):
    filename: str = Field(..., max_length=255)
    file_size: int = Field(..., gt=0, le=100*1024*1024)

class DocumentInitResponse(BaseModel):
    doc_id: str
    upload_token: str
    upload_url: str
```

## 6. 服务层规范

### 6.1 服务职责
- 实现业务逻辑
- 管理事务边界
- 调用外部服务
- 处理异常

### 6.2 事务管理
```python
from sqlalchemy.ext.asyncio import AsyncSession

async def create_document(
    session: AsyncSession,
    data: DocumentCreate
) -> Document:
    async with session.begin():
        doc = Document(**data.dict())
        session.add(doc)
        await session.flush()
        return doc
```

### 6.3 异常处理
```python
from app.core.exceptions import BusinessException

class DocumentNotFoundError(BusinessException):
    def __init__(self, doc_id: str):
        super().__init__(
            code="DOC_404",
            message=f"Document {doc_id} not found"
        )
```

## 7. 异步任务规范

### 7.1 消息队列
- 使用消息队列处理长时间任务
- 任务幂等性设计
- 失败重试机制

### 7.2 Worker 实现
```python
async def process_document_worker():
    async for message in consume_queue("document.ingestion.committed"):
        try:
            await process_document(message.doc_id)
            await message.ack()
        except Exception as e:
            logger.error(f"Process failed: {e}")
            await message.nack(requeue=True)
```

## 8. 测试规范

### 8.1 单元测试
- 测试业务逻辑
- Mock 外部依赖
- 覆盖率 > 95%

```python
import pytest
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_create_document():
    session = AsyncMock()
    service = DocumentService(session)

    result = await service.create_document(data)

    assert result.doc_id is not None
```

### 8.2 集成测试
- 测试完整流程
- 使用测试数据库
- 清理测试数据

## 9. 日志规范

### 9.1 日志级别
- `DEBUG`：调试信息
- `INFO`：关键操作
- `WARNING`：警告信息
- `ERROR`：错误信息

### 9.2 结构化日志
```python
import structlog

logger = structlog.get_logger()

logger.info(
    "document_created",
    doc_id=doc.doc_id,
    user_id=user.id,
    trace_id=trace_id
)
```

## 10. 安全规范

### 10.1 输入校验
- 使用 Pydantic 校验所有输入
- 文件大小限制
- 文件类型校验

### 10.2 SQL 注入防护
- 使用 ORM 参数化查询
- 禁止字符串拼接 SQL

### 10.3 敏感信息
- 密码加密存储
- Token 不记录日志
- 配置文件不提交

## 11. 性能优化

### 11.1 数据库优化
- 添加适当索引
- 避免 N+1 查询
- 使用连接池

### 11.2 缓存策略
- 热点数据缓存
- 缓存失效策略
- 缓存穿透防护

### 11.3 异步优化
- 使用异步 I/O
- 并发控制
- 超时设置

## 12. 部署规范

### 12.1 环境配置
- 使用环境变量
- 配置分离
- 敏感信息加密

### 12.2 健康检查
```python
@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

### 12.3 优雅关闭
- 处理 SIGTERM 信号
- 等待请求完成
- 释放资源连接
