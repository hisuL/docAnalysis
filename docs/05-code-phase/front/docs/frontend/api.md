# API 请求层规范

> 当 API 调用复杂度增加时，从 FRONTEND.md 拆分到此文件。

## 与 03 技术设计的关系

- `docs/03-1-backend-design/<模块>/` 提供后端模块的设计意图、业务语义、状态机和边界说明
- `docs/03-2-frontend-design/<模块>/` 提供页面、组件、状态等前端设计约束
- YAPI 提供编码阶段应直接消费的接口路径、方法、字段、错误码、示例和 Mock
- 本文定义前端如何把 YAPI 契约落成请求层，不重复发明接口语义

## 默认执行流程

1. 先读取对应模块的 YAPI 定义，确认接口路径、方法、请求响应字段、错误码、示例和 Mock
2. 若业务语义、状态机或交互边界不清，再补读 `docs/03-1-backend-design/` 与 `docs/03-2-frontend-design/`
3. 判断当前 `src/features/<模块>/api/` 是否已有封装，`src/generated/api/` 是否已有可复用类型
4. 若 05 文档未覆盖当前模块的接入方式，先补本文档中的“模块 API 映射”
5. 再实现：
   - `src/shared/api/client.ts` 中的通用能力
   - `src/features/<模块>/api/*.ts` 中的模块封装
   - Query hooks / 流式 hooks / 错误映射
6. 页面和组件只能消费封装后的业务 API，不直接拼接接口细节

## 模块 API 映射要求

每新增或修改一个前端业务模块，至少要补齐以下内容：

- 对应的 03-1 文档来源
- 对应的 03-2 前端设计来源（如有）
- 对应的 YAPI 项目 / 分类 / 接口来源
- 前端实际使用的接口清单
- 每个接口的封装位置
- Query key / mutation key 约定
- 状态字段到 UI 状态机的映射
- 错误码到展示文案或交互动作的映射
- 若为流式接口，说明前端消费协议和中断策略

## 模块文档位置

- 模块级 API 对齐文档统一放在 `docs/frontend/modules/`
- 文件名必须对应 `docs/03-1-backend-design/` 下真实存在的后端模块名，格式为 `{backend-module}-api.md`
- 一个 05 模块文档只对应一个 03-1 backend 模块，不使用前端临时业务名或混合命名
- `api.md` 只保留总规则、默认流程、检查清单和模块索引
- 新增模块时，若不存在对应模块文档，AI Agent 必须先创建，再开始编码

## API Mock 基础地址

- 当前前端联调使用的 API Mock 前缀：`http://192.168.210.90:3010/mock/50`
- 拼接规则：`<Mock 前缀> + <YAPI 中的 API Path>`
- 示例：`http://192.168.210.90:3010/mock/50/api/v1/conversations/ask`
- 前端开发、Mock 联调、演示环境优先按该前缀拼接，不手写分散的完整 URL

## 架构原则

- **统一入口**：所有请求通过 `src/shared/api` 的客户端封装
- **类型安全**：接口类型从 OpenAPI 契约生成
- **错误处理**：统一拦截器处理认证失败、网络错误
- **三态处理**：loading、error、empty 必须完整

## 模块索引

| 模块 | 模块文档 |
| --- | --- |
| `document-ingestion` | `docs/frontend/modules/document-ingestion-api.md` |
| `conversation-orchestrator` | `docs/frontend/modules/conversation-orchestrator-api.md` |

## 目录结构

```
src/shared/api/
├── client.ts          # 统一 fetch 封装
└── types.ts           # 公共类型

src/generated/api/     # 自动生成，禁止手改

src/features/<模块>/api/
└── <模块>.ts          # 业务模块的 API 封装
```

## 请求封装示例

```ts
// src/shared/api/client.ts
const BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ??
  'http://192.168.210.90:3010/mock/50'

export async function apiRequest<T>(
  path: string,
  options?: RequestInit
): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  })
  if (res.status === 401) {
    // 跳转登录
  }
  if (!res.ok) {
    throw new Error(`API Error: ${res.status}`)
  }
  return res.json()
}
```

## 业务 API 封装

```ts
// src/features/orders/api/orders.ts
import { apiRequest } from '@/shared/api/client'
import type { Order, OrderListParams } from '@/generated/api'

export const ordersApi = {
  list: (params: OrderListParams) =>
    apiRequest<Order[]>(`/orders?${new URLSearchParams(params as Record<string, string>)}`),

  getById: (id: string) =>
    apiRequest<Order>(`/orders/${id}`),

  create: (data: CreateOrderDto) =>
    apiRequest<Order>('/orders', { method: 'POST', body: JSON.stringify(data) }),
}
```

## 对齐检查清单

- 是否已读取对应模块的 YAPI 定义
- 是否已同步对应 03-2 前端设计中的页面、状态或交互约束
- 若语义不清，是否已补读 03-1 的业务语义、状态机或边界说明
- 是否已确认前端只依赖对外接口，不误用内部接口
- 是否已为接口建立模块化封装，而不是在组件中拼请求
- 是否已明确状态枚举到 UI 状态机的映射
- 是否已覆盖 loading、error、empty、retry、cancel 等关键路径
- 是否已把新增对齐结论补回本文档，保证后续任务可自动沿用

## 在组件中使用

```tsx
// ✅ 使用 TanStack Query
import { useQuery } from '@tanstack/react-query'
import { ordersApi } from '../api/orders'

function OrderList() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['orders'],
    queryFn: () => ordersApi.list({})
  })

  if (isLoading) return <Loading />
  if (error) return <Error message={error.message} />
  if (!data?.length) return <Empty />

  return <Table data={data} />
}

// ❌ 避免：直接在组件中 fetch
function OrderList() {
  const [orders, setOrders] = useState([])
  useEffect(() => {
    fetch('/api/orders').then(/* ... */) // 不要这样做
  }, [])
}
```

## AI 流式请求

```tsx
// 使用 Vercel AI SDK
import { useChat } from 'ai/react'

function ChatPanel() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat({
    api: '/api/chat',
  })
  // isLoading 对应 loading 态，error 对应错误态
}
```
