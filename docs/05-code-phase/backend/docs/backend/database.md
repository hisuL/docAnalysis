# 数据库设计规范

## 1. 数据库选型

### 1.1 核心数据库
- **PostgreSQL 15+**：关系数据存储
- **pgvector 扩展**：向量存储与检索

### 1.2 连接管理
- 使用连接池（asyncpg）
- 最大连接数：20
- 连接超时：30秒

## 2. 表设计规范

### 2.1 命名规范
- 表名：小写字母+下划线，复数形式：`documents`
- 字段名：小写字母+下划线：`created_at`
- 主键：统一使用 `id`
- 外键：`{关联表单数}_id`，如 `doc_id`

### 2.2 必备字段
每个表必须包含：
```sql
id BIGSERIAL PRIMARY KEY,
created_at TIMESTAMP NOT NULL DEFAULT NOW(),
updated_at TIMESTAMP NOT NULL DEFAULT NOW()
```

### 2.3 软删除
需要软删除的表添加：
```sql
deleted_at TIMESTAMP NULL
```

## 3. 数据类型规范

| 用途 | 类型 | 说明 |
|------|------|------|
| 主键 | BIGSERIAL | 自增长整型 |
| 外键 | BIGINT | 关联主键 |
| UUID | VARCHAR(64) | 业务ID |
| 短文本 | VARCHAR(255) | 名称、标题 |
| 长文本 | TEXT | 描述、内容 |
| 枚举 | VARCHAR(50) | 状态、类型 |
| 布尔 | BOOLEAN | 是否标记 |
| 时间 | TIMESTAMP | 时间戳 |
| JSON | JSONB | 结构化数据 |
| 向量 | VECTOR | 向量数据 |

## 4. 索引设计

### 4.1 索引类型
- **B-Tree**：默认索引，适用于等值和范围查询
- **Hash**：仅等值查询
- **GIN**：JSONB、数组、全文检索
- **IVFFlat**：向量相似度检索

### 4.2 索引命名
```
idx_{表名}_{字段名}
```

### 4.3 常用索引
```sql
-- 单列索引
CREATE INDEX idx_documents_status ON documents(status);

-- 复合索引
CREATE INDEX idx_documents_owner_created ON documents(owner_user_id, created_at DESC);

-- 唯一索引
CREATE UNIQUE INDEX idx_documents_doc_id ON documents(doc_id);

-- 部分索引
CREATE INDEX idx_documents_active ON documents(status) WHERE deleted_at IS NULL;

-- 向量索引
CREATE INDEX idx_chunks_embedding ON document_chunks
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

## 5. 约束设计

### 5.1 主键约束
```sql
id BIGSERIAL PRIMARY KEY
```

### 5.2 唯一约束
```sql
doc_id VARCHAR(64) UNIQUE NOT NULL
```

### 5.3 外键约束
```sql
doc_id BIGINT REFERENCES documents(id) ON DELETE CASCADE
```

### 5.4 检查约束
```sql
file_size BIGINT CHECK (file_size > 0 AND file_size <= 104857600)
```

## 6. 核心表设计

### 6.1 documents（文档表）
```sql
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    doc_id VARCHAR(64) UNIQUE NOT NULL,
    owner_user_id VARCHAR(64) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL CHECK (file_size > 0),
    storage_key VARCHAR(512) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documents_owner_created ON documents(owner_user_id, created_at DESC);
CREATE INDEX idx_documents_status ON documents(status);
```

### 6.2 document_chunks（文档块表）
```sql
CREATE TABLE document_chunks (
    id BIGSERIAL PRIMARY KEY,
    chunk_id VARCHAR(64) UNIQUE NOT NULL,
    doc_id BIGINT REFERENCES documents(id) ON DELETE CASCADE,
    version_no INT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    chunk_index INT NOT NULL,
    content TEXT NOT NULL,
    embedding VECTOR(1536),
    metadata JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chunks_doc_active ON document_chunks(doc_id, is_active, chunk_index);
CREATE INDEX idx_chunks_embedding ON document_chunks
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

### 6.3 chat_sessions（会话表）
```sql
CREATE TABLE chat_sessions (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(64) UNIQUE NOT NULL,
    doc_id BIGINT REFERENCES documents(id) ON DELETE CASCADE,
    owner_user_id VARCHAR(64) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_owner_created ON chat_sessions(owner_user_id, created_at DESC);
CREATE INDEX idx_sessions_doc ON chat_sessions(doc_id);
```

### 6.4 chat_messages（消息表）
```sql
CREATE TABLE chat_messages (
    id BIGSERIAL PRIMARY KEY,
    message_id VARCHAR(64) UNIQUE NOT NULL,
    session_id BIGINT REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_session_created ON chat_messages(session_id, created_at ASC);
```

## 7. 事务管理

### 7.1 事务隔离级别
默认使用 `READ COMMITTED`

### 7.2 事务边界
```python
async with session.begin():
    # 数据库操作
    pass
```

### 7.3 乐观锁
使用版本号实现：
```sql
UPDATE documents
SET status = 'processing', version = version + 1
WHERE id = ? AND version = ?
```

### 7.4 悲观锁
使用行锁：
```sql
SELECT * FROM documents WHERE id = ? FOR UPDATE
```

## 8. 数据迁移

### 8.1 迁移工具
使用 Alembic 管理数据库迁移

### 8.2 迁移文件命名
```
{timestamp}_{description}.py
```

### 8.3 迁移示例
```python
def upgrade():
    op.create_table(
        'documents',
        sa.Column('id', sa.BigInteger(), nullable=False),
        sa.Column('doc_id', sa.String(64), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('doc_id')
    )

def downgrade():
    op.drop_table('documents')
```

## 9. 性能优化

### 9.1 查询优化
- 避免 SELECT *
- 使用索引覆盖
- 避免 N+1 查询
- 使用 EXPLAIN ANALYZE 分析

### 9.2 批量操作
```python
# 批量插入
session.bulk_insert_mappings(Document, data_list)

# 批量更新
session.bulk_update_mappings(Document, data_list)
```

### 9.3 分页查询
```python
query = select(Document).limit(20).offset(0)
```

## 10. 数据安全

### 10.1 敏感数据加密
- 密码使用 bcrypt 加密
- Token 使用 AES 加密

### 10.2 SQL 注入防护
- 使用 ORM 参数化查询
- 禁止字符串拼接 SQL

### 10.3 备份策略
- 每日全量备份
- 每小时增量备份
- 保留 7 天备份
