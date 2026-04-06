---
name: task-status
description: 查看和更新任务状态，支持查看任务拓扑图、更新单个任务状态、查看进度统计
user_invocable: true
---

# 任务状态管理

根据用户的命令管理 `docs/tasks/` 下的任务文档状态。

## 支持的命令

### 查看状态
- `/task-status list [subject]` — 列出指定主题（或全部）的任务概况
- `/task-status graph [subject]` — 显示任务拓扑图（当前状态着色）
- `/task-status critical [subject]` — 显示关键路径及其进度
- `/task-status next [subject]` — 显示下一步可执行的任务（所有前置已完成的 pending 任务）

### 更新状态
- `/task-status start {TaskID}` — 将任务标记为 `in-progress`，记录开始时间
- `/task-status done {TaskID}` — 将任务标记为 `completed`，记录结束时间
- `/task-status fail {TaskID} {reason}` — 将任务标记为 `error`，记录错误原因和结束时间
- `/task-status reset {TaskID}` — 将任务重置为 `pending`，清除时间戳

## 执行步骤

1. 解析用户命令和参数
2. 读取 `docs/tasks/` 下对应的任务文档
3. 如果是查看命令，解析文档并展示信息
4. 如果是更新命令：
   - 在任务总览表中更新对应行的状态、时间戳
   - 在任务详情中更新对应任务的状态、时间戳
   - 更新 Mermaid 拓扑图中对应节点的样式类（pending/active/done/error）
   - 更新统计信息
5. 保存文档

## 时间戳格式

- 使用 `YYYY-MM-DD HH:mm` 格式
- 使用当前系统时间（通过 `date` 命令获取）

## 注意事项

- 更新状态时必须检查前置依赖是否满足（start 命令）
- 如果前置任务未全部完成，拒绝 start 并提示哪些任务还未完成
- 更新后重新计算统计信息
