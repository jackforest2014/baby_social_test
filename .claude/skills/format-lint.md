---
name: format-lint
description: 对项目代码执行格式化和 lint 检查
user_invocable: true
---

# 格式化与 Lint 检查

对项目代码执行格式化和静态分析。

## 执行步骤

1. **Go 后端**（如果 `backend/` 目录存在）：
   - 运行 `gofmt -w backend/`
   - 运行 `golangci-lint run ./backend/...`

2. **React 前端**（如果 `frontend/` 目录存在）：
   - 运行 `npx prettier --write frontend/src/`
   - 运行 `npx eslint frontend/src/`

3. 输出检查结果摘要，列出发现的问题和已自动修复的文件。
