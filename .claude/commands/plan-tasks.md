# 任务规划

启动任务规划流程，对照技术方案文档进行任务拆解和排期规划。

## 执行步骤

### 1. 确认技术方案

- 读取 `docs/architecture/` 目录下的技术方案文档
- 如果用户指定了具体文档，使用指定的文档
- 如果未指定，列出可用的技术方案文档供用户选择
- 同时读取关联的 PRD 文档（`docs/prd/`）以理解业务上下文

### 2. 任务拆解

使用 `task-planner` Agent 进行任务拆解：

- 按 DDD 分层从底层到顶层逐层拆解
- 每个任务的粒度控制在方法级到类级之间
- 为每个任务分配唯一 ID（格式：`{layer}-{module}-{seq}`）
- 明确每个任务的：
  - 任务类型（domain / repository / service / handler / component / hook / test 等）
  - 目标文件路径
  - 验收标准
  - 估算工时（S/M/L/XL）
  - 执行者类型（backend-developer / frontend-developer / integration-tester）

### 3. 依赖分析与拓扑图

- 分析任务间的依赖关系
- 构建任务依赖的有向无环图（DAG）
- 使用 Mermaid `graph TD` 语法生成拓扑图
- 识别关键路径并高亮标注
- 识别可并行执行的任务组

### 4. 生成任务文档

- 使用模板 `.claude/templates/task-plan.md.tpl` 生成文档
- 保存到 `docs/tasks/{subject}.md`
- `{subject}` 为技术方案的英文主题名
- 文档必须包含目录

### 5. 更新项目记录

- 在 `docs/progress/` 下记录任务规划活动（遵循进度记录规范）

## 输入参数

- `$ARGUMENTS`：可选，指定技术方案文档路径或主题名。如未提供则交互式选择。

## 输出

- 任务安排文档：`docs/tasks/{subject}.md`
- 包含完整的任务列表、拓扑图、关键路径、并行任务组、统计信息

## 后续操作

任务规划完成后，建议：
1. 用户审阅任务拆解是否合理
2. 确认后，使用 `/dev-backend` 或 `/dev-frontend` 开始开发
3. 开发 Agent 将根据拓扑图自动判断并行/串行执行顺序
