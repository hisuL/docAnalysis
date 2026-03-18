# document-ingestion API 对齐

## 03 文档来源

- 后端：`docs/03-1-backend-design/document-ingestion/api-design.md`
- 前端：`docs/03-2-frontend-design/chatfile-web/`

## 前端需封装的接口

- `POST /api/documents`
- `GET /api/documents/{docId}`
- `POST /api/documents/{docId}:cancel`
- `GET /api/documents/{docId}/preview`

## 前端职责

- 区分本地上传进度和服务端阶段状态
- 刷新后通过状态接口恢复文档状态
- 将 `cancel` 纳入统一 mutation 封装
- 预览地址通过 preview 或状态接口统一获取
- 不允许页面组件直接拼装上传、轮询和取消逻辑

## 状态映射要求

- `uploaded`：原始文件上传成功
- `parsing`：文档解析中
- `chunking`：智能切片中
- `indexing`：向量索引中
- `ready`：文档可进入问答态
- `failed`：展示失败原因，并根据场景支持重新上传
- `cancelled`：返回上传入口，不保留处理中 UI

## 错误处理要求

- `400 INVALID_FILE_TYPE`：提示仅支持 PDF
- `400 FILE_TOO_LARGE`：提示文件超限
- `409 DUPLICATE_UPLOAD`：提示重复上传并恢复已有文档状态
- `404 DOCUMENT_NOT_FOUND`：提示文档不存在
- `409 DOCUMENT_ALREADY_READY` / `409 DOCUMENT_ALREADY_FAILED`：阻止错误状态流转
- `500 STORAGE_WRITE_FAILED`：展示可重试错误态
