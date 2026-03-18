# CLAUDE.md

> Claude 及其他 AI Agent 在后端开发中的执行手册。

## 项目信息
- 项目名称：ChatFile
- 技术栈：FastAPI · Python 3.11+ · PostgreSQL + pgvector · Haystack · LiteLLM · RabbitMQ/Kafka
- 当前阶段：开发阶段
- 服务架构：
  ```
  backend/
  ├── knowledge-base-service/   # 文档知识服务
  │   ├── app/                  # 应用入口
  │   ├── api/                  # API路由
  │   ├── services/             # 业务逻辑
  │   ├── models/               # 数据模型
  │   └── schemas/              # DTO定义
  └── qa-service/               # 问答服务
      ├── app/                  # 应用入口
      ├── api/                  # API路由
      ├── services/             # 业务逻辑
      ├── models/               # 数据模型
      └── schemas/              # DTO定义
  ```

## 文档地图

### 必读文档（开始任何任务前）
- `docs/BACKEND.md` - 后端开发规范总纲
- `backend-development-plan.md` - 后端开发技术方案

### 核心规范（按需查阅）
- `docs/ARCHITECTURE.md` - 架构设计、服务拆分、模块职责
- `docs/backend/api.md` - API设计规范
- `docs/backend/database.md` - 数据库设计规范
- `docs/backend/services.md` - 服务层设计规范

## 指令优先级

冲突时按此优先级：项目规范文档 > CLAUDE.md > 第三方 Skills > AI 默认知识

**示例**：`BACKEND.md` 规定使用 FastAPI，即使第三方 Skill 推荐 Flask，也必须用 FastAPI。

## 工作原则
- 契约先行：先定义 DTO 和接口，同步到 YAPI，再写实现
- 最小改动：复用现有代码，避免重复造轮子
- 类型安全：使用 Pydantic 严格定义数据模型
- 测试驱动：核心业务逻辑单测覆盖率 > 95%
- 安全第一：防止 SQL 注入、XSS、CSRF 等安全问题

## 开发流程（严格遵守）

### 1. 接单与建分支
- 从 PingCode 获取任务后，**禁止**直接在 `main/master` 分支写代码
- 必须先创建工作分支：`feat/REQ-{ID}` 或 `fix/BUG-{ID}`
- 示例：`git checkout -b feat/REQ-006`

### 2. 契约先行
- 在编写 Controller 逻辑前，必须先定义好：
  - Request/Response DTO（使用 Pydantic）
  - API 路径和方法
  - 错误码定义
- 将接口定义同步至 YAPI，确保前端可以并行开发

### 3. 本地自测
- 提交代码前，必须在本地运行：
  - 单元测试：`pytest tests/`
  - 代码检查：`ruff check .`
  - 类型检查：`mypy .`
- 核心业务逻辑单测覆盖率必须 > 95%

### 4. 规范提交
- Commit Message 必须遵循 Angular 规范：
  - `feat(module): 功能描述`
  - `fix(module): 修复描述`
  - `refactor(module): 重构描述`
- 示例：`feat(document-ingestion): 实现三段式上传流程`

### 5. 触发流水线
- 代码 Push 并创建 PR 后，触发 CI/CD 流水线
- 确保所有测试通过后才能合并

## 编码红线

### RESTful API 规范
- 所有 API 必须返回统一响应结构：
  ```python
  {
    "code": 0,
    "msg": "success",
    "data": {}
  }
  ```
- 请求路径使用小写字母加中划线：`/api/v1/user-profiles`
- HTTP 方法语义正确：GET（查询）、POST（创建）、PUT（更新）、DELETE（删除）

### 数据库与事务
- 所有涉及 `INSERT`, `UPDATE`, `DELETE` 的操作，必须在 Service 层添加事务
- **严禁**在代码中直接拼接 SQL，必须使用 ORM（SQLAlchemy）防止 SQL 注入
- 数据库查询必须添加适当的索引

### 异常处理
- 严禁"吞没"异常（不要写空的 `except` 块）
- 捕获异常后，必须记录带堆栈信息的 ERROR 日志
- 向外抛出带有具体业务错误码的自定义异常

### 安全规范
- 所有用户输入必须校验（使用 Pydantic）
- 敏感信息（密码、Token）不得记录到日志
- API 必须进行身份认证和权限校验
- 防止 SQL 注入、XSS、CSRF 等安全问题

## 问题记录

发现以下情况时，记录到 `CHANGELOG.md`：
- 破坏性变更（影响 API、数据结构）
- 需求冲突、架构疑问、规范缺失
- 性能瓶颈、安全隐患

格式：`- [ ] **类型**：描述 | 时间 | 影响范围 | AI建议 | @决策人`

## 文件修改与校验

### 允许修改
- 任务相关的业务代码、测试、文档

### 禁止修改
- 自动生成的迁移文件（除非任务明确要求）
- 与任务无关的模块
- 全局配置（除非任务明确要求）

### 校验命令
- 代码检查：`ruff check .`
- 类型检查：`mypy .`
- 单元测试：`pytest tests/`
- 集成测试：`pytest tests/integration/`

## 服务管理

启动开发服务前：
1. 检查端口占用：`lsof -i :8000` 或 `netstat -ano | findstr 8000`
2. 若已占用，检查服务健康：`curl http://localhost:8000/health`
3. 若不健康，清理后重启

禁止：不检查就重复启动、端口冲突时换端口

## 验收标准

### 功能验收
- API 接口正常响应
- 业务逻辑正确
- 单元测试通过
- 集成测试通过
- 无明显性能问题

### 代码质量验收
- 代码检查通过（ruff）
- 类型检查通过（mypy）
- 单测覆盖率 > 95%
- 无安全漏洞

## Bug 修复 SOP

当从 PingCode 获取到 Bug 任务时：
1. **强制复现**：先写一个会报错的单元测试（重现 Bug 触发条件）
2. **逻辑修复**：修改业务代码
3. **验证闭环**：运行测试，确保状态从 `Fail` 转为 `Pass`
4. **经验更新**：将解决方案提取为规则，追加到项目根目录的 `CLAUDE.md` 的 `<lessons-learned>` 标签内

## 自我完善

### 触发时机
- 同类错误出现 2 次以上 → 在本文件中新增约束
- 发现规范缺失 → 补充到对应文档
- 发现设计缺陷 → 记录到 CHANGELOG.md 并更新 ARCHITECTURE.md

### 文档行数控制
目标：每个 md 文件 ≤ 200 行。超过时识别冗余、合并相似内容、精简表达，必要时拆分文档。
