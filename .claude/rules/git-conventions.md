---
description: Git 提交规范
globs: "**/*"
---

# Git 提交规范

- 提交信息格式: `<type>(<scope>): <subject>`
- type 取值: feat | fix | docs | style | refactor | test | chore
- scope 取值: backend | frontend | docs | config | db
- subject 使用中文或英文，简明扼要
- 每次提交前必须通过格式化和 lint 检查
- 禁止向 main 分支 force push
