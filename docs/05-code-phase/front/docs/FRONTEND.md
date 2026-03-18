# FRONTEND.md

> 前端开发规范总纲。初期项目只需本文件，复杂后可按需拆分详细规范到 `frontend/` 子目录。

## 技术栈

- 框架：Next.js 15（App Router）
- 语言：TypeScript 5+
- 构建工具：Next.js 内置（Turbopack）
- UI 组件：Shadcn/UI
- 样式方案：Tailwind CSS
- 状态管理：Zustand（全局）+ TanStack Query（服务端）
- AI 能力：Vercel AI SDK
- 表单方案：React Hook Form + Zod
- 测试方案：Vitest（单元测试）+ Playwright（E2E）

## 核心约束

### 组件开发
- 优先复用 Shadcn/UI 和现有组件，不重复造基础组件
- 基础组件放 `shared/ui`，业务组件放对应 `features/<模块>/components`
- Server Component 默认优先，需要交互时加 `'use client'`
- 一个组件一个职责，复杂逻辑抽到 hooks

### 样式规则
- 统一使用 Tailwind CSS + Shadcn/UI 的 CSS 变量（Design Tokens）
- 禁止硬编码颜色、间距、字号
- 不混用其他 CSS 方案（如 CSS Modules、styled-components）

### 状态管理
- UI 局部状态放组件内（useState）
- 跨页面共享状态放 Zustand
- 筛选/分页/排序等可分享状态优先放 URL query
- 服务端数据用 TanStack Query，不重复存为 Zustand

### 数据请求
- 请求统一通过 `src/shared/api` 的客户端封装
- 接口类型优先从契约生成（OpenAPI）
- 所有请求处理 loading、error、empty 三态
- AI 流式请求通过 Vercel AI SDK 的 `useChat` / `useCompletion`
- 当前 API Mock 基础地址为 `http://192.168.210.90:3010/mock/50`
- 编码阶段优先通过 YAPI 读取对应模块的接口路径、字段、错误码和示例
- 若页面、组件、状态设计有明确约束，再同步阅读 `docs/03-2-frontend-design/<模块>/`
- 若业务语义、状态机或设计边界不清，再补读 `docs/03-1-backend-design/<模块>/`
- 若当前模块的前端 API 封装规范缺失，先补 `frontend/api.md` 中的模块映射，再开始写页面和组件
- 不允许跳过 API 对齐直接根据页面猜测接口

### Mock 边界定义
**允许 Mock 的部分**：后端 API 响应、第三方服务调用、复杂计算结果

**即便 Mock 也必须完整的交互**：
- 上传状态反馈（进度、成功、失败）
- 错误态展示和处理
- 流式输出效果（打字机效果）
- 表单校验和提交流程、加载态和禁用态切换

**Mock 实现要求**：数据结构与真实 API 一致；异步行为必须模拟；边界情况必须可测试

### 表单规则
- 统一使用 React Hook Form + Zod
- 表单提交态、禁用态、错误提示必须完整
- 不允许无反馈的异步提交

## 安全规范

- **XSS**：使用 React JSX 自动转义；禁止 `dangerouslySetInnerHTML`（除非经过审查）；富文本用 DOMPurify 清洗
- **敏感信息**：API Key / 密钥 / Token 不得写入代码，使用环境变量；客户端环境变量必须加 `NEXT_PUBLIC_` 前缀
- **权限控制**：路由守卫确保未登录跳转登录页；无权限时禁用按钮并提示
- **依赖安全**：定期运行 `pnpm audit`

## 禁止事项
- 禁止组件内直接请求后端
- 禁止复制粘贴已有组件另起一套
- 禁止跳过类型错误直接提交
- 禁止未确认 YAPI 契约就开始前端接口开发
- 禁止硬编码敏感信息（API Key、密钥、Token）
- 禁止 `dangerouslySetInnerHTML` 而不做内容清洗
- 禁止在前端日志中输出敏感信息

## 详细规范（按需查阅）
- `frontend/components.md` - 组件开发详细规范
- `frontend/state.md` - 状态管理详细规范
- `frontend/api.md` - API 请求层详细规范
- `frontend/modules/` - 各后端模块对应的前端 API 对齐文档
- `frontend/styling.md` - 样式开发详细规范
