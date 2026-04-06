---
description: 启动前端架构设计，进行路由规划、组件架构和状态管理方案设计
---

请以 frontend-architect agent 的角色，基于指定的 PRD 文档、前置分析报告和后端架构设计进行前端架构设计。

## 前置条件检查

**本命令依赖后端架构设计的产出**（至少需要 API 契约文档）。执行前需检查：

1. 检查 `docs/architecture/` 下是否存在对应 PRD 的后端架构文档（如 `contracts-user-auth.md`）
2. 如果存在，正常执行
3. 如果不存在，提示用户："该 PRD 的后端架构设计尚未完成，前端架构依赖 API 契约定义。建议先执行 `/design-backend {PRD文件名}` 完成后端架构设计。"并等待用户确认是否继续

## PRD 选择

$ARGUMENTS

- 如果用户指定了 PRD 文件名（如 `PRD-user-auth-20260405.md`），则读取该文件作为主输入
- 如果用户指定了多个 PRD 文件名，则读取所有指定的文件
- 如果用户未指定，则列出 `docs/prd/` 下所有 PRD 文件（排除用户故事类文档如 `*-user-story-*.md`），让用户选择一个或多个
- **注意**：如果所选 PRD 存在前置依赖（文档信息中的"前置依赖"字段），需一并读取被依赖的 PRD 作为上下文参考，但技术方案的范围仅限于所选 PRD

## 工作流程

1. 执行前置条件检查
2. 按上述规则确定目标 PRD 文档并读取
3. 读取 `docs/situation/` 中的现状分析报告（code-scout 输出），了解已有前端组件、状态管理、API 调用层的现状和可复用资产
4. 读取 `docs/analytics/` 中的数据分析规划（data-analyst 输出），将前端埋点实现方案纳入架构设计
5. 读取 `docs/architecture/` 中对应 PRD 的后端架构设计和 API 契约
6. 设计前端路由结构、组件架构、状态管理方案
7. 设计 API 层封装、认证流程、错误处理策略
8. 设计前端埋点的技术实现方案（基于 data-analyst 的建议）
9. 使用 `.claude/templates/frontend-architecture.md.tpl` 模板
10. 输出文档保存到 `docs/architecture/` 目录，文件名包含 PRD 主题（如 `frontend-user-auth.md`）
11. 请求我审阅确认
