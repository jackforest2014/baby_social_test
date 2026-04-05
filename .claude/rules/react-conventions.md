---
description: React 前端编码规范
globs: "frontend/**/*.{ts,tsx}"
---

# React 编码规范

- 所有组件使用 TypeScript 编写
- 优先使用函数组件 + Hooks，避免 class 组件
- 组件文件名使用 PascalCase，如 `UserProfile.tsx`
- Hook 文件名使用 camelCase，以 `use` 开头，如 `useAuth.ts`
- API 请求和响应数据必须定义 TypeScript 接口
- 样式优先使用 CSS Modules 或 styled-components
