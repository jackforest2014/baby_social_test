---
description: 启动后端架构设计，进行领域建模、数据库设计和 API 契约定义
---

请以 backend-architect agent 的角色，基于已有的 PRD 文档进行架构设计：

$ARGUMENTS

工作流程：
1. 读取 `docs/prd/` 中的相关 PRD 文档
2. 进行领域分析和建模（实体、值对象、聚合、领域事件）
3. 设计系统模块划分和接口契约
4. 使用 `.claude/templates/design-overview.md.tpl` 和 `.claude/templates/contracts.md.tpl` 模板
5. 输出文档保存到 `docs/architecture/` 目录
6. 请求我审阅确认
