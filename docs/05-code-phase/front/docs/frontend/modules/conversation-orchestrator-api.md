# conversation-orchestrator API 对齐

## 03 文档来源

- 后端索引：`docs/03-1-backend-design/conversation-orchestrator/api-index.md`
- 后端规格：`docs/03-1-backend-design/conversation-orchestrator/api-specification.md`
- 前端：`docs/03-2-frontend-design/chatfile-web/`

## 前端需封装的接口

- `POST /api/v1/conversations/ask`
- `GET /api/v1/conversations/{session_id}/history`
- `GET /api/v1/conversations/documents/{doc_id}/summary`
- `POST /api/v1/conversations/feedback`
- `DELETE /api/v1/conversations/{session_id}`

## 前端职责

- 会话恢复、历史消息查询、流式生成必须统一封装
- 摘要与反馈作为独立 query / mutation 管理
- 页面组件只消费封装后的会话和消息数据，不直接处理底层协议
- 流式问答请求通过 `stream=true` 驱动，不额外假设独立 stop 接口

## 流式协议要求

- 当前 03-1 文档定义 SSE 事件：`token` / `citations` / `done`
- 前端按当前事件类型消费，不自行发明额外事件名
- 若后端后续切换统一流式协议，应以 03-1 文档更新为准

## 错误处理要求

- `2001`：文档未就绪，阻止发问
- `2002`：检索失败，展示可恢复错误态
- `2003`：模型调用失败，允许重试
- `2004`：会话不存在，清理当前会话上下文
- `2005`：相关性不足，按拒答态展示
- `9001`：参数错误，优先在前端输入校验阶段拦截
- `9002`：系统异常，展示通用错误态
- 摘要、反馈查询失败不能阻断主问答页面渲染
