# BabySocial 项目指引

## 项目概述
BabySocial 是一款面向全行业用户的社交平台应用。

## 技术栈
- **前端**: React + TypeScript
- **后端**: Go
- **数据库**: PostgreSQL（通过 Docker 运行）
- **设计方法论**: 领域驱动设计（DDD）
- **开发方法论**: 测试驱动开发（TDD）

## 项目结构
```
babysocial/
├── .claude/              # Claude Code 配置
│   ├── agents/           # Agent 定义
│   ├── commands/         # 自定义斜杠命令
│   ├── rules/            # 项目规则
│   ├── scripts/          # 钩子脚本
│   └── skills/           # 自定义技能
├── docs/
│   ├── prd/              # 产品需求文档
│   └── architecture/     # 架构设计文档
├── templates/            # 文档模板
├── backend/              # Go 后端代码
│   ├── cmd/              # 应用入口
│   ├── internal/         # 内部包
│   │   ├── domain/       # 领域模型
│   │   ├── application/  # 应用层服务
│   │   ├── infrastructure/ # 基础设施层
│   │   └── interfaces/   # 接口层（HTTP handlers）
│   ├── pkg/              # 公共包
│   └── migrations/       # 数据库迁移
└── frontend/             # React 前端代码
    ├── src/
    │   ├── components/   # 可复用组件
    │   ├── pages/        # 页面组件
    │   ├── hooks/        # 自定义 Hooks
    │   ├── services/     # API 调用
    │   ├── store/        # 状态管理
    │   └── types/        # TypeScript 类型定义
    └── public/
```

## 开发规范

### 文档
- 所有 markdown 文档都要有目录
- 项目进度要记录到 docs/progress/<YYYY_MM_DD>.md 中
    - 每次修改都要更新，携带时间戳，方便追溯和从之前的任务上继续
        - 记录中要包含：
            - 任务名称
            - 任务类型
            - 任务状态
            - 任务耗时
            - 任务负责人
            - 任务开始时间
            - 任务结束时间
            - 任务备注
- 项目过程中的经验需要记录到 docs/experience/<YYYY_MM_DD>.md 中
    - 每个经验的记录要包含：
        - 遇到的问题/需求等
        - 有哪些解决方案
            - 各个方案的内容
        - 为什么选择当前方案
        - 哪些地方可以优化
    

### Go 后端
- 使用 `gofmt` 格式化代码
- 使用 `golangci-lint` 进行静态分析
- 遵循 DDD 分层架构：domain → application → infrastructure → interfaces
- 所有核心业务逻辑必须有单元测试
- API 接口遵循 RESTful 规范

### React 前端
- 使用 TypeScript 编写所有代码
- 使用 Prettier 格式化代码
- 使用 ESLint 进行代码检查
- 组件优先使用函数组件 + Hooks
- API 请求和响应必须定义 TypeScript 接口

### Git 提交规范
- 提交信息格式: `<type>(<scope>): <subject>`
- type: feat / fix / docs / style / refactor / test / chore
- 提交前必须通过格式化和 lint 检查

## Agent 工作流
1. **product-manager** → 需求澄清，输出 PRD
2. **domain-expert** → 领域知识输入，术语统一
3. **backend-architect** → 领域建模，架构设计，API 契约
4. **interaction-designer** → UI 交互原型
5. **backend-developer** → TDD 实现后端代码
6. **frontend-developer** → 前端页面与 API 对接
7. **integration-tester** → 集成测试与回归测试

## 数据库
- PostgreSQL 通过 Docker 运行
- 连接地址: `postgresql://postgres:postgres@localhost:5432/babysocial`
- 迁移文件位于 `backend/migrations/`
