---
version: 1.0.0
status: draft
module: conversation-orchestrator
role: backend
dependencies:
  - document-ingestion
change_log:
  - version: 1.0.0
    date: 2026-03-17
    changes: initial version
---

# Middleware Design

## 1. Referenced Inputs / 引用输入材料
- `docs/01-prd/PRD.md`:
  - 要求文档就绪后自动生成摘要和推荐问题
  - 要求流式响应首字延迟 ≤ 3 秒
- `docs/02-architecture/architecture-design.md`:
  - 定义 conversation-orchestrator 负责问答、会话、摘要、反馈

## 2. Scope / 范围
- 设计异步任务：文档摘要生成、推荐问题生成
- 设计任务触发、执行、失败处理和监控

## 3. Middleware Summary / 中间件概览
| Type / 类型 | Resource / 资源 | Purpose / 目的 | Producer / 生产方 | Consumer / 消费方 |
| --- | --- | --- | --- | --- |
| 任务事件 | `document.ready` | 触发摘要和推荐问题生成 | document-ingestion | conversation-orchestrator |
| 摘要任务 | `summary.generate` | 生成文档摘要 | conversation-orchestrator | celery-worker |
| 推荐任务 | `questions.generate` | 生成推荐问题 | conversation-orchestrator | celery-worker |

## 4. Event / Cache / Search Detail / 事件、缓存与搜索设计

### 4.1 `document.ready`
- Trigger / 触发条件:
  - document-ingestion 完成文档处理，状态变为 `ready`
- Payload / 载荷:
  - `docId`
  - `chunkCount`
  - `readyAt`
- Ordering / 顺序性:
  - 同一 `docId` 保证单消费者串行
- Retry / 重试:
  - 最多 2 次，超过后记录失败日志
- Idempotency / 幂等性:
  - 检查 `conversation.summaries` 表是否已存在该 `doc_id`
- Monitoring / 监控:
  - 任务入队、开始、完成、失败计数

### 4.2 `summary.generate`
- Trigger / 触发条件:
  - 接收到 `document.ready` 事件
- Payload / 载荷:
  - `docId`
- 执行逻辑:
  - 获取文档前 10 个 chunk
  - 调用 LLM 生成摘要（≤ 200 字）
  - 保存到 `conversation.summaries` 表
- Timeout / 超时:
  - 单次生成超时 60 秒
- Retry / 重试:
  - LLM 调用失败重试 1 次
- Failure Handling / 失败处理:
  - 记录失败日志，不影响文档可用性

### 4.3 `questions.generate`
- Trigger / 触发条件:
  - `summary.generate` 完成后
- Payload / 载荷:
  - `docId`
  - `summary`
- 执行逻辑:
  - 基于文档内容生成 3 个推荐问题
  - 保存到 `conversation.summaries.suggested_questions` 字段
- Timeout / 超时:
  - 单次生成超时 60 秒
- Retry / 重试:
  - LLM 调用失败重试 1 次
- Failure Handling / 失败处理:
  - 记录失败日志，不影响文档可用性

## 5. Failure Handling / 失败处理
- LLM 调用失败:
  - 分类成 `LLM_TIMEOUT`、`LLM_RATE_LIMIT`、`LLM_ERROR`
  - 可重试一次；重试后仍失败则记录日志
- 数据库写入失败:
  - 记录错误日志，任务标记失败
- 重复消费:
  - 以 `conversation.summaries.doc_id` 做幂等检查

## 6. Open Questions / 待确认问题
- 摘要和推荐问题生成是否需要支持手动重新生成
- 是否需要缓存 LLM 生成结果以减少重复调用
