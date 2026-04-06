---
globs:
  - docs/tasks/**/*.md
---

# 任务管理规范

## 任务 ID 格式
- 格式：`{layer}-{module}-{seq}`
- layer 取值：D(domain) / R(repository) / S(service) / H(handler) / M(migration) / MW(middleware) / FC(frontend-component) / FH(frontend-hook) / FS(frontend-store) / FA(frontend-api) / CF(config) / T(test) / DP(deploy)
- module：模块英文缩写，小写
- seq：两位数字，从 01 开始

## 任务状态
- `pending` — 未开始
- `in-progress` — 进行中，必须记录开始时间
- `completed` — 已完成，必须记录结束时间
- `error` — 出错，必须在备注中记录错误信息和结束时间

## 状态更新规则
- 开发 Agent 开始执行任务时，必须将状态更新为 `in-progress` 并记录开始时间
- 任务完成后，必须将状态更新为 `completed` 并记录结束时间
- 任务失败后，必须将状态更新为 `error`，记录结束时间和错误信息
- 状态更新必须同步更新拓扑图中的节点样式

## Git Worktree 分支命名
- 任务分支：`task/{TaskID}`
- 主开发分支：`dev/{subject}`
- 禁止在 main 分支上直接执行任务开发

## 任务执行顺序
- 严格遵循拓扑排序，不得跳过前置依赖
- 可并行的任务应尽量并行执行以提高效率
- 关键路径上的任务优先执行
