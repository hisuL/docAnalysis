---
service: conversation-orchestrator
version: 1.0.0
last_updated: 2026-03-17
---

# Conversation Orchestrator 开发指南

> **AI 指令**: 你正在开发 conversation-orchestrator 服务。严格遵循本文档的所有规则。

## 服务上下文

**服务名**: conversation-orchestrator
**职责**: 处理问答、会话管理、摘要生成和反馈收集

**技术栈**: FastAPI, PostgreSQL+pgvector, litellm, Celery+Redis, Python 3.11+

## 服务边界

**负责**:
- 流式问答和引用锚点
- 会话和对话历史
- 文档摘要和推荐问题
- 用户反馈

**不负责**:
- 文档存储和解析
- 切片和 embedding 生成
- 文档处理状态

## 开发流程

1. 从 PingCode 获取任务
2. 创建分支: `feat/REQ-{ID}` 或 `fix/BUG-{ID}` (绝对禁止在 main/master 开发)
3. 先定义 API 契约，同步到 YAPI
4. 编码实现
5. 编写测试 (覆盖率 > 95%)
6. 按 Angular 规范提交
7. 创建 PR 触发 CI/CD

## 关键规则

### 数据库操作

**必须**:
- 所有 INSERT/UPDATE/DELETE 使用事务
- 使用参数化查询 (绝对禁止字符串拼接)
- 所有检索查询的 WHERE 子句必须包含 `doc_id`

```python
# ✅ 正确
async def save_conversation(session_id: str, question: str):
    await db.execute(
        "INSERT INTO conversations (session_id, question) VALUES ($1, $2)",
        session_id, question
    )

# ❌ 错误：SQL 注入风险
query = f"INSERT INTO conversations VALUES ('{session_id}')"
```

### 异常处理

**必须**:
- 记录所有异常，使用 ERROR 级别 + 堆栈跟踪
- 抛出带错误码的 BizException
- 绝对禁止空的 except 块

```python
try:
    result = await retrieve_chunks(doc_id, query)
except Exception as e:
    logger.error(f"检索失败: doc_id={doc_id}", exc_info=True)
    raise BizException(code=2002, msg="检索失败")
```

### 核心约束

- **doc_id 隔离**: 所有检索必须在 WHERE 子句中过滤 `doc_id`
- **拒答低相关性**: 相似度 < 0.7 时返回拒答消息
- **引用必带**: 每个回答必须包含引用 (chunk_id, page_num)
- **流式响应**: 问答接口支持 SSE 流式返回

## API 规范

响应格式:
```json
{"code": 0, "msg": "success", "data": {}}
```

错误码: `2000-2999`
路径命名: 小写字母 + 中划线 (如 `/api/v1/conversations/ask`)

## 测试要求

- 核心业务逻辑覆盖率 > 95%
- 使用 pytest + pytest-asyncio
- Mock 外部依赖（数据库、模型）

**关键测试场景**:
- doc_id 隔离性（确保不会跨文档检索）
- 低相关性拒答（相似度 < 0.7）
- 流式响应完成
- 异常处理

```python
# 示例：doc_id 隔离性测试
async def test_retrieve_chunks_isolation():
    await create_test_chunks("doc_1")
    await create_test_chunks("doc_2")

    result = await retrieve_chunks("doc_1", "test query")

    assert all(c["doc_id"] == "doc_1" for c in result)
```

## 提交规范

格式: `<type>(orchestrator): <subject>`

示例:
```
feat(orchestrator): 实现流式问答

- 添加 SSE 流式支持
- 包含引用锚点
- 实现低相关性拒答

Closes REQ-456
```

## 经验教训

<lessons-learned>
  <lesson date="2026-03-17" author="Architect">
    <problem>跨 doc_id 检索导致用户看到其他文档的内容。</problem>
    <solution>在 WHERE 子句中强制添加 doc_id 过滤，用单元测试验证。</solution>
    <prevention>所有检索查询必须在 WHERE 子句中包含 doc_id。</prevention>
  </lesson>

  <lesson date="2026-03-17" author="Architect">
    <problem>低相关性内容仍然返回，导致回答质量差。</problem>
    <solution>设置相关性阈值 0.7，低于此值直接拒答。</solution>
    <prevention>检索后检查相似度分数，< 0.7 时返回拒答。</prevention>
  </lesson>

  <lesson date="2026-03-17" author="Architect">
    <problem>流式响应中断后，前端无法判断是否完成。</problem>
    <solution>在流末尾发送 {"type": "done"} 标记。</solution>
    <prevention>所有流式端点必须发送完成标记。</prevention>
  </lesson>
</lessons-learned>

## PR 前检查清单

提交 PR 前验证：

- [ ] API 已同步到 YAPI
- [ ] 测试覆盖率 > 95%
- [ ] doc_id 隔离性测试通过
- [ ] 低相关性拒答测试通过
- [ ] 无空 except 块
- [ ] 日志完整（ERROR 含堆栈跟踪）
- [ ] 数据库写操作使用事务
- [ ] 使用参数化查询（无 SQL 注入）
- [ ] 提交信息符合规范
- [ ] 代码通过 lint 检查

## 相关文档

- [API 接口文档](./api-specification.md)
- [数据库设计](./database-design.md)
- [技术设计](./technical-design.md)
- [架构设计](../../02-architecture/architecture-design.md)
