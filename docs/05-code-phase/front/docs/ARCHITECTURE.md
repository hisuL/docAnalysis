# ARCHITECTURE.md

## 1. 文档目的

本文档用于定义项目的系统边界、目录分层、依赖方向和核心架构约束。让人和 AI 在改动代码前快速知道：模块如何划分、依赖如何流动、新功能落在哪一层。

## 2. 项目概览

- 项目名称：ChatFile
- 业务目标：单文档问答 Web 应用，支持 PDF 上传、解析切片、向量化、多轮对话与引用溯源
- 核心技术栈：Next.js 15（App Router）· TypeScript · Shadcn/UI · Tailwind · Zustand · TanStack Query · Vercel AI SDK

## 3. 架构原则

- 按业务模块组织代码，不按技术类型堆文件
- 依赖方向单向流动，低层不依赖高层
- 外部数据在边界处完成类型校验和转换
- 共享能力集中沉淀，避免业务模块间复制实现

## 4. 目录结构

```txt
src/
├── app/            # Next.js App Router：路由、页面、全局 layout/provider
├── features/       # 按业务模块拆分
│   └── chatfile-web/                 # ChatFile 前端工作台模块
├── entities/       # 跨模块复用的核心业务实体
├── shared/         # 通用组件、工具、请求层、hooks
│   ├── ui/         # 基础 UI 组件（封装 Shadcn/UI）
│   ├── api/        # API 客户端和拦截器
│   └── hooks/      # 通用 hooks
└── generated/      # 自动生成代码，禁止手改
```

## 5. 分层规则

推荐依赖方向：`app -> features -> entities -> shared`

- `shared` 不能依赖 `features`
- `entities` 不能依赖具体页面实现
- `features` 间避免直接互相调用内部实现
- `app` 负责组装，不负责写业务逻辑
- `features/` 下各模块相互独立，可并行开发

## 6. 数据边界

- 所有接口响应在请求层完成解析，页面组件不处理原始后端结构
- 表单输入提交前统一校验（React Hook Form + Zod）
- URL 参数、Local Storage、Query 参数都视为不可信输入

## 7. 状态划分

- 全局状态：Zustand（用户信息、主题、全局配置）
- 页面级状态：useState / useReducer（UI 交互、流式生成状态）
- 表单状态：React Hook Form
- 服务端状态：TanStack Query（messages、citations、overview、feedback 等，不重复存为全局状态）

## 8. 核心约束

- 禁止在页面组件中直接发请求
- 禁止跨业务模块引用私有实现
- 禁止手改 `generated/` 下文件
- Server Component 不能使用 `useState`/`useEffect`，需标记 `'use client'`

## 9. 新功能落点指南

1. 是否属于已有业务模块 → 落入对应 `features/<模块>`
2. 是否可复用已有实体模型 → 落入 `entities/`
3. 是否应该进入共享层 → 落入 `shared/`
4. 是否需要补充新的架构说明 → 更新本文档

## 10. 技术设计文档对齐说明

> 03-1（后端详细设计）与 03-2（前端详细设计）描述设计意图，05（本规范）定义实现约束。编码前需完成以下对齐。

### 03 设计模块 -> 代码目录映射

| 03 设计模块                    | features 目录                                    |
|-------------------------------|--------------------------------------------------|
| chatfile-web                   | `src/features/chatfile-web/`                     |

### 03 设计状态分类 -> 05 实现方式

| 03 设计状态分类 | 05 实现方式                                               |
|--------------|----------------------------------------------------------|
| 服务端状态     | TanStack Query（messages、citations、overview 等）         |
| 页面容器状态   | useState（streamingState、activeCitationTarget 等）        |
| 跨页面共享状态  | Zustand（当前版本暂无）                                    |

### 流式输出协议约定

- 当前以 `conversation-orchestrator` 的 03-1 API 文档为准
- 已确认接口为 `POST /api/v1/conversations/ask`，通过 `stream=true` 返回 SSE
- 当前事件类型包括 `token`、`citations`、`done`
- 在 03-1 未改版前，前端不自行假设 Vercel AI Stream Protocol
