---
description: 启动后端架构设计，进行领域建模、数据库设计和 API 契约定义
---

请以 backend-architect agent 的角色，基于指定的 PRD 文档和前置分析报告进行架构设计。

## PRD 选择

$ARGUMENTS

- 如果用户指定了 PRD 文件名（如 `PRD-user-auth-20260405.md`），则读取该文件作为主输入
- 如果用户指定了多个 PRD 文件名，则读取所有指定的文件
- 如果用户未指定，则列出 `docs/prd/` 下所有 PRD 文件（排除用户故事类文档如 `*-user-story-*.md`），让用户选择一个或多个
- **注意**：如果所选 PRD 存在前置依赖（文档信息中的"前置依赖"字段），需一并读取被依赖的 PRD 作为上下文参考，但技术方案的范围仅限于所选 PRD

## 工作流程

1. 按上述规则确定目标 PRD 文档并读取
2. 读取 `docs/situation/` 中的现状分析报告（code-scout 输出），了解已有代码、中间件、第三方服务的现状和可复用资产
3. 读取 `docs/analytics/` 中的数据分析规划（data-analyst 输出），将埋点采集、指标计算等需求纳入架构设计
4. 读取 `docs/architecture/` 中已有的架构文档（如已存在），确保与已有设计保持一致
5. 进行领域分析和建模（实体、值对象、聚合、领域事件）
6. 设计系统模块划分和接口契约
7. 使用 `.claude/templates/design-overview.md.tpl`、`.claude/templates/contracts.md.tpl` 和 `.claude/templates/database-design.md.tpl` 模板
8. 输出文档保存到 `docs/architecture/` 目录，文件名包含 PRD 主题（如 `design-user-auth.md`、`contracts-user-auth.md`）
9. 请求我审阅确认
