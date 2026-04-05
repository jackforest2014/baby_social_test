---
description: Go 后端编码规范
globs: "backend/**/*.go"
---

# Go 编码规范

- 使用 `gofmt` 格式化代码
- 错误处理不允许使用 `_` 忽略，必须显式处理或记录
- 公共函数和类型必须有 GoDoc 注释
- 遵循 DDD 分层：domain 层不依赖 infrastructure 层
- 测试文件与源文件同目录，命名为 `*_test.go`
- 使用 `context.Context` 传递请求上下文
