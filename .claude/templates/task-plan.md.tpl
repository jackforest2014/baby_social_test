# {{subject}} — 任务规划

> **关联技术方案**：{{architecture_doc_path}}
> **关联 PRD**：{{prd_doc_path}}
> **规划时间**：{{plan_date}}
> **规划者**：task-planner Agent
> **状态**：{{plan_status}}

---

## 目录

- [任务拓扑图](#任务拓扑图)
- [关键路径](#关键路径)
- [任务总览](#任务总览)
- [任务详情](#任务详情)
  - [第 1 层：基础设施与配置](#第-1-层基础设施与配置)
  - [第 2 层：领域模型](#第-2-层领域模型)
  - [第 3 层：仓储层](#第-3-层仓储层)
  - [第 4 层：应用服务层](#第-4-层应用服务层)
  - [第 5 层：接口层](#第-5-层接口层)
  - [第 6 层：前端基础](#第-6-层前端基础)
  - [第 7 层：前端页面](#第-7-层前端页面)
  - [第 8 层：集成测试](#第-8-层集成测试)
  - [第 9 层：部署](#第-9-层部署)
- [并行任务组](#并行任务组)
- [Git Worktree 分支规划](#git-worktree-分支规划)
- [统计信息](#统计信息)

---

## 任务拓扑图

> 节点颜色说明：🟢 已完成 | 🔵 进行中 | ⚪ 未开始 | 🔴 出错

```mermaid
graph TD
    classDef done fill:#4CAF50,stroke:#388E3C,color:#fff
    classDef active fill:#2196F3,stroke:#1565C0,color:#fff
    classDef error fill:#F44336,stroke:#C62828,color:#fff
    classDef pending fill:#E0E0E0,stroke:#9E9E9E,color:#333

    %% === 第 1 层：基础设施 ===
    {{#each layer1_tasks}}
    {{this.id}}["{{this.name}}"]:::{{this.status}}
    {{/each}}

    %% === 第 2 层：领域模型 ===
    {{#each layer2_tasks}}
    {{this.id}}["{{this.name}}"]:::{{this.status}}
    {{/each}}

    %% === 后续层次 ===
    %% ... 按层继续

    %% === 依赖关系 ===
    {{#each dependencies}}
    {{this.from}} --> {{this.to}}
    {{/each}}

    %% === 关键路径高亮 ===
    linkStyle {{critical_path_link_indices}} stroke:#FF5722,stroke-width:3px
```

---

## 关键路径

| 序号 | 任务 ID | 任务名称 | 估算工时 |
|------|---------|----------|----------|
| {{#each critical_path}} |
| {{@index}} | {{this.id}} | {{this.name}} | {{this.estimate}} |
| {{/each}} |

**关键路径总工时**：{{critical_path_total}}

---

## 任务总览

| 任务 ID | 任务名称 | 类型 | 层 | 模块 | 估算 | 执行者 | 依赖 | 状态 | 开始时间 | 结束时间 |
|---------|----------|------|------|------|------|--------|------|------|----------|----------|
| {{#each all_tasks}} |
| {{this.id}} | {{this.name}} | {{this.type}} | {{this.layer}} | {{this.module}} | {{this.estimate}} | {{this.executor}} | {{this.dependencies}} | {{this.status}} | {{this.start_time}} | {{this.end_time}} |
| {{/each}} |

---

## 任务详情

### 第 1 层：基础设施与配置

#### {{task_id}}: {{task_name}}

- **类型**：{{task_type}}
- **所属层**：{{task_layer}}
- **所属模块**：{{task_module}}
- **目标文件**：`{{target_file_path}}`
- **依赖任务**：{{dependencies_or_none}}
- **执行者**：{{executor_type}}
- **估算工时**：{{estimate}}
- **状态**：{{status}}
- **开始时间**：{{start_time}}
- **结束时间**：{{end_time}}

**验收标准**：
- [ ] {{acceptance_criterion_1}}
- [ ] {{acceptance_criterion_2}}
- [ ] {{acceptance_criterion_3}}

**备注**：{{notes}}

---

<!-- 后续层次按相同格式展开 -->

### 第 2 层：领域模型

<!-- ... -->

### 第 3 层：仓储层

<!-- ... -->

### 第 4 层：应用服务层

<!-- ... -->

### 第 5 层：接口层

<!-- ... -->

### 第 6 层：前端基础

<!-- ... -->

### 第 7 层：前端页面

<!-- ... -->

### 第 8 层：集成测试

<!-- ... -->

### 第 9 层：部署

<!-- ... -->

---

## 并行任务组

以下任务组内的任务之间无依赖关系，可以同时并行执行。

### 并行组 {{group_index}}

> 前置条件：{{prerequisite_tasks}} 全部完成

| 任务 ID | 任务名称 | 执行者 | Worktree 分支 |
|---------|----------|--------|---------------|
| {{#each parallel_tasks}} |
| {{this.id}} | {{this.name}} | {{this.executor}} | `task/{{this.id}}` |
| {{/each}} |

---

## Git Worktree 分支规划

### 分支策略

- **主开发分支**：`dev/{{subject}}`
- **任务分支命名**：`task/{TaskID}`（如 `task/D-auth-01`）
- **合并顺序**：按拓扑排序，从叶子节点向根节点合并

### 分支生命周期

```
main
 └── dev/{{subject}}           ← 主开发分支
      ├── task/CF-xxx-01       ← 配置任务（最先完成，最先合并）
      ├── task/D-xxx-01        ← 领域模型任务
      ├── task/D-xxx-02        ← 可与 D-xxx-01 并行
      ├── task/R-xxx-01        ← 依赖 D-xxx-01，等其合并后开始
      └── ...
```

### Worktree 操作流程

```bash
# 1. 创建主开发分支
git checkout -b dev/{{subject}}

# 2. 为并行任务创建 worktree
git worktree add ../babysocial-task-D-xxx-01 -b task/D-xxx-01
git worktree add ../babysocial-task-D-xxx-02 -b task/D-xxx-02

# 3. 任务完成后合并
git checkout dev/{{subject}}
git merge task/D-xxx-01
git merge task/D-xxx-02

# 4. 清理 worktree
git worktree remove ../babysocial-task-D-xxx-01
git worktree remove ../babysocial-task-D-xxx-02
```

---

## 统计信息

| 指标 | 数值 |
|------|------|
| 总任务数 | {{total_tasks}} |
| 后端任务 | {{backend_tasks}} |
| 前端任务 | {{frontend_tasks}} |
| 测试任务 | {{test_tasks}} |
| 部署任务 | {{deploy_tasks}} |
| 已完成 | {{completed_count}} |
| 进行中 | {{in_progress_count}} |
| 未开始 | {{pending_count}} |
| 出错 | {{error_count}} |
| 估算总工时 | {{total_estimate}} |
| 关键路径工时 | {{critical_path_total}} |
| 最大并行度 | {{max_parallelism}} |
