---
name: db-migrate
description: 管理数据库迁移（创建、执行、回滚）
user_invocable: true
---

# 数据库迁移管理

管理 PostgreSQL 数据库的 schema 迁移。

## 用法

- `/db-migrate create <name>` — 在 `backend/migrations/` 下创建新的迁移文件
- `/db-migrate up` — 执行所有未应用的迁移
- `/db-migrate down` — 回滚最近一次迁移
- `/db-migrate status` — 查看迁移状态

## 注意事项

- 迁移文件使用时间戳命名：`YYYYMMDDHHMMSS_<name>.up.sql` / `YYYYMMDDHHMMSS_<name>.down.sql`
- 数据库连接: `postgresql://postgres:postgres@localhost:5432/babysocial`
- 执行前确认当前数据库状态
- 生产环境迁移必须先备份
