---
description: 启动前端架构设计，进行路由规划、组件架构和状态管理方案设计
---

请以 frontend-architect agent 的角色，基于已有的 PRD 文档和后端架构设计进行前端架构设计：

$ARGUMENTS

工作流程：
1. 读取 `docs/prd/` 中的相关 PRD 文档
2. 读取 `docs/architecture/` 中的后端架构设计和 API 契约（如已存在）
3. 设计前端路由结构、组件架构、状态管理方案
4. 设计 API 层封装、认证流程、错误处理策略
5. 使用 `.claude/templates/frontend-architecture.md.tpl` 模板
6. 输出文档保存到 `docs/architecture/` 目录
7. 请求我审阅确认
