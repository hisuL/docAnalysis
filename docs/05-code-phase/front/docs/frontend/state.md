# 状态管理规范

> 当状态管理复杂度增加时，从 FRONTEND.md 拆分到此文件。

## 状态分类

### 组件局部状态
- 使用：`useState` / `useReducer`
- 适用：UI 交互状态（展开/收起、hover、focus）
- 示例：弹窗开关、表单输入

### 全局共享状态（Zustand）
- 适用：跨页面共享的业务状态
- 示例：用户信息、主题设置、全局配置

### URL 状态
- 使用：URL query / params（Next.js `useSearchParams`）
- 适用：可分享、可刷新保留的状态
- 示例：筛选条件、分页、排序、Tab 选中

### 服务端状态（TanStack Query）
- 适用：从后端获取的数据
- 原则：不重复存为 Zustand 全局状态

## 核心原则

- **最小化全局状态**：能放组件内就不放全局
- **单一数据源**：同一份数据不在多处维护
- **状态提升**：需要共享时才提升到父组件或全局
- **派生状态**：能计算出来的不单独存储

## 示例

```tsx
// ✅ 好的状态管理
// 筛选条件放 URL
const searchParams = useSearchParams()
const status = searchParams.get('status') || 'all'

// 服务端数据用 TanStack Query
const { data: orders, isLoading, error } = useQuery({
  queryKey: ['orders', status],
  queryFn: () => ordersApi.list({ status })
})

// ❌ 避免：重复存储服务端数据
const [orders, setOrders] = useState([])
useEffect(() => {
  fetchOrders().then(setOrders) // 用 TanStack Query 代替
}, [])
```

## 全局状态示例（Zustand）

```ts
// src/shared/stores/user.ts
import { create } from 'zustand'

interface UserStore {
  user: User | null
  setUser: (user: User) => void
  logout: () => void
}

export const useUserStore = create<UserStore>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
}))
```
