# Conversation Orchestrator API 接口文档

## 1. 文档说明

**服务名称**: conversation-orchestrator
**Base URL**: `http://api.chatfile.com/api/v1/conversations`
**版本**: 1.0.0

## 2. 通用规范

### 2.1 统一响应格式

```json
{
  "code": 0,
  "msg": "success",
  "data": {}
}
```

### 2.2 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 2001 | 文档未就绪 |
| 2002 | 检索失败 |
| 2003 | 模型调用失败 |
| 2004 | 会话不存在 |
| 2005 | 相关性不足，无法回答 |
| 9001 | 参数错误 |
| 9002 | 系统异常 |

## 3. 接口列表

### 3.1 发起问答

**接口**: `POST /api/v1/conversations/ask`

**描述**: 基于文档发起问答，支持流式返回

**请求参数**:
```json
{
  "doc_id": "doc_1234567890",
  "question": "产品的主要功能是什么？",
  "session_id": "session_abc123",
  "stream": true
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| doc_id | string | 是 | 文档 ID |
| question | string | 是 | 用户问题 |
| session_id | string | 否 | 会话 ID，用于多轮对话 |
| stream | boolean | 否 | 是否流式返回，默认 true |

**响应示例（非流式）**:
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "message_id": "msg_xyz789",
    "answer": "根据文档内容，产品的主要功能包括...",
    "citations": [
      {
        "chunk_id": "chunk_001",
        "page_num": 5,
        "text": "产品的主要功能包括...",
        "relevance": 0.92
      }
    ],
    "created_at": "2026-03-17T10:40:00Z"
  }
}
```

**响应示例（流式 SSE）**:
```
data: {"type": "token", "content": "根据"}

data: {"type": "token", "content": "文档"}

data: {"type": "citations", "content": [{"chunk_id": "chunk_001", "page_num": 5}]}

data: {"type": "done"}
```

**拒答示例**:
```json
{
  "code": 2005,
  "msg": "抱歉，我在文档中没有找到相关内容",
  "data": null
}
```

### 3.2 获取会话历史

**接口**: `GET /api/v1/conversations/{session_id}/history`

**路径参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| session_id | string | 是 | 会话 ID |

**查询参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认 1 |
| page_size | int | 否 | 每页数量，默认 20 |

**响应示例**:
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "items": [
      {
        "message_id": "msg_001",
        "question": "产品的主要功能是什么？",
        "answer": "根据文档内容...",
        "citations": [...],
        "created_at": "2026-03-17T10:40:00Z"
      }
    ],
    "total": 5,
    "page": 1,
    "page_size": 20
  }
}
```

### 3.3 获取文档摘要

**接口**: `GET /api/v1/conversations/documents/{doc_id}/summary`

**路径参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| doc_id | string | 是 | 文档 ID |

**响应示例**:
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "doc_id": "doc_1234567890",
    "summary": "本文档介绍了产品的核心功能...",
    "suggested_questions": [
      "产品的主要功能是什么？",
      "如何开始使用该产品？",
      "有哪些使用注意事项？"
    ],
    "generated_at": "2026-03-17T10:35:00Z"
  }
}
```

### 3.4 提交反馈

**接口**: `POST /api/v1/conversations/feedback`

**请求参数**:
```json
{
  "message_id": "msg_xyz789",
  "feedback_type": "good",
  "comment": "回答很准确"
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| message_id | string | 是 | 消息 ID |
| feedback_type | string | 是 | 反馈类型：good/bad |
| comment | string | 否 | 反馈评论 |

**响应示例**:
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "feedback_id": "feedback_123",
    "created_at": "2026-03-17T10:45:00Z"
  }
}
```

### 3.5 删除会话

**接口**: `DELETE /api/v1/conversations/{session_id}`

**路径参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| session_id | string | 是 | 会话 ID |

**响应示例**:
```json
{
  "code": 0,
  "msg": "success",
  "data": null
}
```
