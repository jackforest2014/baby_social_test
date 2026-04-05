---
description: 自动分析变更、生成提交信息、执行 commit 和 push
---

请执行以下步骤：

1. 运行 `git status` 和 `git diff` 查看所有变更
2. 分析变更内容，生成符合项目规范的提交信息：
   - 格式: `<type>(<scope>): <subject>`
   - type: feat / fix / docs / style / refactor / test / chore
   - scope: backend / frontend / docs / config / db
   - subject 用中文简明描述
3. 将提交信息展示给我确认
4. 确认后执行 `git add`、`git commit` 和 `git push`

如果尚未配置远程仓库，提示我先设置。

$ARGUMENTS
