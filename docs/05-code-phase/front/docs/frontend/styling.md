# 样式开发规范

> 当样式复杂度增加时，从 FRONTEND.md 拆分到此文件。

## 核心原则

- **Design Tokens 优先**：使用 Shadcn/UI 的 CSS 变量，不硬编码
- **单一方案**：只用 Tailwind CSS，不混用其他样式系统
- **组件化**：样式跟随组件，避免全局污染
- **响应式**：统一断点，移动端优先

## Design Tokens（Shadcn/UI CSS 变量）

```css
/* 项目初始化后在 globals.css 中定义，以下为常用变量示例 */
--background: ...;
--foreground: ...;
--primary: ...;
--primary-foreground: ...;
--destructive: ...;
--muted: ...;
--border: ...;
--radius: ...;
```

> 初始化 Shadcn/UI 后，实际值由 `npx shadcn@latest init` 生成，按设计稿调整后填入上方。

## Tailwind 使用规范

```tsx
// ✅ 使用 Tailwind + Shadcn/UI 语义变量
<Button variant="destructive">删除</Button>
<div className="bg-background text-foreground p-4 rounded-md border">
  内容
</div>

// ❌ 避免：硬编码颜色
<button style={{ backgroundColor: '#ef4444' }}>删除</button>
<div className="bg-[#ffffff] text-[#1f2937]">内容</div>
```

## 响应式断点

```tsx
// 统一使用 Tailwind 断点
// sm: 640px / md: 768px / lg: 1024px / xl: 1280px

<div className="w-full md:w-1/2 lg:w-1/3">内容</div>
<Table className="hidden md:table" />
<Sheet>  {/* 移动端使用 Sheet 代替 Dialog */}</Sheet>
```

## 禁止事项

- 不在组件内硬编码品牌色（用 `--primary` 等 CSS 变量）
- 不引入 CSS Modules 或 styled-components
- 不使用内联 style（除非动态计算，如 `width: ${progress}%`）
