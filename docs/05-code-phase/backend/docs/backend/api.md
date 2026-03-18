# API 设计规范

## 1. 接口分层

### 1.1 前端接口（/api/v1/...）
- 面向前端应用
- 网关透传身份上下文
- 统一响应格式
- 统一错误处理

### 1.2 内部接口（/internal/v1/...）
- 仅服务间调用
- 静态 token 鉴权
- 不对外暴露

## 2. 路径设计

### 2.1 命名规范
- 使用小写字母和中划线：`/chat-sessions`
- 使用复数形式：`/documents`（不是 `/document`）
- 资源嵌套不超过2层：`/sessions/{id}/messages`

### 2.2 版本管理
- 路径包含版本号：`/api/v1/`
- 破坏性变更时升级版本：`/api/v2/`

## 3. HTTP 方法语义

| 方法 | 语义 | 幂等性 | 示例 |
|------|------|--------|------|
| GET | 查询资源 | 是 | `GET /documents/{id}` |
| POST | 创建资源或执行操作 | 否 | `POST /documents/init` |
| PUT | 完整更新资源 | 是 | `PUT /documents/{id}/file` |
| PATCH | 部分更新资源 | 否 | `PATCH /documents/{id}` |
| DELETE | 删除资源 | 是 | `DELETE /documents/{id}` |

## 4. 请求设计

### 4.1 路径参数
用于标识资源：
```
GET /api/v1/documents/{doc_id}
```

### 4.2 查询参数
用于过滤、分页、排序：
```
GET /api/v1/documents?status=ready&page=1&limit=20
```

### 4.3 请求体
使用 JSON 格式：
```json
{
  "filename": "datasheet.pdf",
  "file_size": 1024000
}
```

## 5. 响应设计

### 5.1 统一响应格式
```json
{
  "code": 0,
  "msg": "success",
  "data": {}
}
```

### 5.2 成功响应
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "doc_id": "doc_123",
    "status": "ready"
  }
}
```

### 5.3 错误响应
```json
{
  "code": "DOC_404",
  "msg": "Document not found",
  "data": null
}
```

### 5.4 分页响应
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

## 6. 流式响应（SSE）

### 6.1 Content-Type
```
Content-Type: text/event-stream
```

### 6.2 事件格式
```
event: message_start
data: {"run_id": "run_123", "message_id": "msg_456"}

event: token
data: {"delta": "Hello"}

event: citation_anchor
data: {"anchor_index": 1, "chunk_id": "chunk_789"}

event: message_complete
data: {"run_status": "completed"}
```

## 7. 错误码设计

### 7.1 错误码格式
`{MODULE}_{HTTP_STATUS}`

### 7.2 模块前缀
- `DOC_`：文档模块
- `PROC_`：处理模块
- `QA_`：问答模块

### 7.3 常用错误码
| 错误码 | 说明 |
|--------|------|
| `DOC_400` | 文档请求参数错误 |
| `DOC_404` | 文档不存在 |
| `DOC_409` | 文档状态冲突 |
| `PROC_500` | 处理失败 |
| `PROC_504` | 处理超时 |
| `QA_403` | 会话无权限 |
| `QA_429` | 请求过于频繁 |

## 8. 幂等性设计

### 8.1 幂等性要求
- `GET`、`PUT`、`DELETE` 必须幂等
- `POST` 根据业务场景设计幂等

### 8.2 幂等键
使用 `client_request_id` 实现幂等：
```json
{
  "client_request_id": "req_123",
  "doc_id": "doc_456"
}
```

## 9. 认证与鉴权

### 9.1 前端接口认证
```
Authorization: Bearer {access_token}
```

### 9.2 内部接口认证
```
X-Internal-Token: {static_token}
```

### 9.3 权限校验
- 文档所有权校验
- 会话所有权校验

## 10. 限流与熔断

### 10.1 限流策略
- 用户级限流：100 req/min
- IP 级限流：1000 req/min

### 10.2 限流响应
```json
{
  "code": "QA_429",
  "msg": "Too many requests",
  "data": {
    "retry_after": 60
  }
}
```

## 11. 接口文档

### 11.1 OpenAPI 规范
使用 FastAPI 自动生成 OpenAPI 文档：
```
http://localhost:8000/docs
```

### 11.2 YAPI 同步
所有接口定义必须同步到 YAPI 平台。

## 12. 接口示例

### 12.1 初始化上传
```
POST /api/v1/documents/init

Request:
{
  "filename": "datasheet.pdf",
  "file_size": 1024000
}

Response:
{
  "code": 0,
  "msg": "success",
  "data": {
    "doc_id": "doc_123",
    "upload_token": "token_456",
    "upload_url": "https://s3.example.com/upload"
  }
}
```

### 12.2 流式问答
```
POST /api/v1/chat-sessions/{session_id}/messages:stream

Request:
{
  "content": "What is the operating voltage?"
}

Response (SSE):
event: message_start
data: {"run_id": "run_123", "message_id": "msg_456"}

event: token
data: {"delta": "The"}

event: token
data: {"delta": " operating"}

event: citation_anchor
data: {"anchor_index": 1, "chunk_id": "chunk_789"}

event: message_complete
data: {"run_status": "completed"}
```
