# 用户注册与登录模块 - API 契约文档

## 目录

- [1. 文档信息](#1-文档信息)
- [2. 通用规范](#2-通用规范)
  - [2.1 Base URL](#21-base-url)
  - [2.2 认证方式](#22-认证方式)
  - [2.3 通用请求头](#23-通用请求头)
  - [2.4 通用响应格式](#24-通用响应格式)
  - [2.5 分页规范](#25-分页规范)
  - [2.6 错误码规范](#26-错误码规范)
- [3. 接口列表](#3-接口列表)
- [4. 接口详情](#4-接口详情)
  - [4.1 发送邮箱验证码](#41-发送邮箱验证码)
  - [4.2 校验邮箱验证码](#42-校验邮箱验证码)
  - [4.3 用户注册](#43-用户注册)
  - [4.4 用户登录](#44-用户登录)
  - [4.5 刷新 Access Token](#45-刷新-access-token)
  - [4.6 生成人机校验挑战](#46-生成人机校验挑战)
  - [4.7 验证人机校验结果](#47-验证人机校验结果)
  - [4.8 获取当前用户信息](#48-获取当前用户信息)
  - [4.9 上报埋点事件](#49-上报埋点事件)
  - [4.10 手机号注册（预留）](#410-手机号注册预留)
  - [4.11 第三方 OAuth 回调（预留）](#411-第三方-oauth-回调预留)
- [5. 数据模型](#5-数据模型)
- [6. 变更记录](#6-变更记录)

---

## 1. 文档信息

| 字段     | 内容                          |
| -------- | ----------------------------- |
| 文档编号 | CONTRACT-USER-AUTH-001        |
| 版本     | v1.1                          |
| 作者     | Backend Architect             |
| 创建日期 | 2026-04-06                    |
| 最后更新 | 2026-04-06                    |
| 状态     | 待评审                        |
| 关联架构文档 | ARCH-USER-AUTH-001         |

---

## 2. 通用规范

### 2.1 Base URL

| 环境 | Base URL |
|------|----------|
| 开发 | `http://localhost:8080/api/v1` |
| 测试 | `https://test.babysocial.com/api/v1` |
| 生产 | `https://api.babysocial.com/api/v1` |

### 2.2 认证方式

需要认证的接口通过 JWT Bearer Token 进行身份验证：

```
Authorization: Bearer <access_token>
```

- Access Token 有效期 2 小时，过期后需使用 Refresh Token 刷新。
- Refresh Token 通过 HttpOnly Cookie 自动携带，无需前端手动处理。
- 不需要认证的接口在接口详情中标注"认证: 否"。

### 2.3 通用请求头

| Header | 必填 | 说明 |
|--------|------|------|
| Content-Type | 是 | `application/json` |
| Authorization | 视接口而定 | `Bearer <access_token>` |
| X-Request-ID | 否 | 请求追踪 ID，由客户端生成（UUID v4）。若客户端未提供，服务端自动生成 |

### 2.4 通用响应格式

**成功响应**：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

**错误响应**：

```json
{
  "code": 11004,
  "message": "邮箱或密码错误",
  "details": "invalid credentials for email u***@example.com"
}
```

- `code`：业务错误码。成功时为 `0`
- `message`：用户可读的信息描述
- `data`：业务数据（仅成功时存在）
- `details`：调试信息，仅非生产环境返回。生产环境不返回此字段

### 2.5 分页规范

**请求参数**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | int | 1 | 页码，从 1 开始 |
| page_size | int | 20 | 每页条数，最大 100 |

**响应格式**：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "items": [],
    "total": 100,
    "page": 1,
    "page_size": 20
  }
}
```

注：当前模块无分页接口，此规范为全局约定，供后续模块使用。

### 2.6 错误码规范

| 错误码范围 | 模块 | 说明 |
|-----------|------|------|
| 10000-10999 | 通用 | 参数校验、权限、服务器内部错误 |
| 11000-11999 | 认证（Auth） | 注册、登录、令牌 |
| 12000-12999 | 验证码（Verification） | 验证码发送、校验 |
| 13000-13999 | 人机校验（Captcha） | 人机校验 |

**完整错误码表**：

| 错误码 | HTTP 状态码 | 说明 |
|--------|-----------|------|
| 0 | 200/201 | 成功 |
| 10001 | 400 | 请求参数校验失败 |
| 10002 | 401 | 未认证（缺少或无效 Token） |
| 10003 | 403 | 无权限访问 |
| 10004 | 404 | 资源不存在 |
| 10005 | 429 | 请求频率超限 |
| 10006 | 500 | 服务器内部错误 |
| 11001 | 400 | 邮箱格式不合法 |
| 11002 | 400 | 密码不满足强度要求 |
| 11003 | 409 | 邮箱已被注册 |
| 11004 | 401 | 邮箱或密码错误 |
| 11005 | 423 | 账号已锁定 |
| 11006 | 401 | Refresh Token 无效或已过期 |
| 11007 | 401 | Access Token 已过期 |
| 12001 | 429 | 验证码发送冷却中 |
| 12002 | 400 | 验证码错误 |
| 12003 | 410 | 验证码已过期 |
| 12004 | 429 | 验证码验证次数超限 |
| 12005 | 500 | 验证码发送失败 |
| 13001 | 400 | 人机校验失败 |
| 13002 | 400 | 人机校验 Token 无效或已过期 |

---

## 3. 接口列表

| 序号 | 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|------|
| 1 | POST | /api/v1/auth/register/send-code | 发送邮箱验证码 | 否 |
| 2 | POST | /api/v1/auth/register/verify-code | 校验邮箱验证码 | 否 |
| 3 | POST | /api/v1/auth/register | 用户注册（设置密码，完成注册） | 否 |
| 4 | POST | /api/v1/auth/login | 用户登录 | 否 |
| 5 | POST | /api/v1/auth/token/refresh | 刷新 Access Token | 否（需 Refresh Token Cookie） |
| 6 | POST | /api/v1/auth/captcha/challenge | 生成人机校验挑战 | 否 |
| 7 | POST | /api/v1/auth/captcha/verify | 验证人机校验结果 | 否 |
| 8 | GET | /api/v1/users/me | 获取当前用户信息 | 是 |
| 9 | POST | /api/v1/analytics/events | 上报埋点事件 | 否 |
| 10 | POST | /api/v1/auth/register/phone | 手机号注册（预留，501） | 否 |
| 11 | GET | /api/v1/auth/oauth/{provider}/callback | 第三方 OAuth 回调（预留，501） | 否 |

---

## 4. 接口详情

### 4.1 发送邮箱验证码

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/auth/register/send-code` |
| 认证 | 否 |
| 权限 | 匿名可访问 |
| 说明 | 向指定邮箱发送 6 位数字验证码。需先通过人机校验 |
| 频率限制 | 同一邮箱 60 秒冷却；同一 IP 每小时 20 次 |

**请求参数**：

Body：

```json
{
  "email": "user@example.com",
  "captcha_token": "captcha-verification-token-xxx"
}
```

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|---------|------|
| email | string | 是 | RFC 5322 邮箱格式 | 接收验证码的邮箱地址 |
| captcha_token | string | 是 | 非空 | 人机校验通过后获得的 Token |

**响应示例**：

成功（200）：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "cooldown_seconds": 60
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| cooldown_seconds | int | 下次可发送验证码的冷却秒数 |

**失败示例**：

| HTTP 状态码 | 业务错误码 | 说明 |
|------------|-----------|------|
| 400 | 11001 | 邮箱格式不合法 |
| 400 | 13002 | 人机校验 Token 无效或已过期 |
| 429 | 12001 | 验证码发送冷却中（响应中包含剩余冷却秒数） |
| 429 | 10005 | IP 频率超限 |
| 500 | 12005 | 验证码发送失败（邮件服务异常） |

冷却中的错误响应包含额外信息：

```json
{
  "code": 12001,
  "message": "验证码发送冷却中，请稍后重试",
  "data": {
    "retry_after_seconds": 45
  }
}
```

---

### 4.2 校验邮箱验证码

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/auth/register/verify-code` |
| 认证 | 否 |
| 权限 | 匿名可访问 |
| 说明 | 校验用户输入的 6 位邮箱验证码。校验通过后返回一个一次性 verification_token，用于注册接口 |

**请求参数**：

Body：

```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|---------|------|
| email | string | 是 | RFC 5322 邮箱格式 | 验证码对应的邮箱 |
| code | string | 是 | 6 位数字 | 用户输入的验证码 |

**响应示例**：

成功（200）：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "verification_token": "eyJhbGciOi..."
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| verification_token | string | 邮箱验证通过的凭证（JWT，有效期 10 分钟），注册接口需携带此 Token |

**失败示例**：

| HTTP 状态码 | 业务错误码 | 说明 |
|------------|-----------|------|
| 400 | 12002 | 验证码错误 |
| 410 | 12003 | 验证码已过期 |
| 429 | 12004 | 验证码验证次数超限（5 次），需重新获取 |

---

### 4.3 用户注册

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/auth/register` |
| 认证 | 否 |
| 权限 | 匿名可访问 |
| 说明 | 完成注册：设置密码并创建用户。需先完成邮箱验证（携带 verification_token）。注册成功后自动颁发登录令牌 |

**请求参数**：

Body：

```json
{
  "email": "user@example.com",
  "password": "MyPassword123",
  "password_confirm": "MyPassword123",
  "verification_token": "eyJhbGciOi..."
}
```

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|---------|------|
| email | string | 是 | RFC 5322 邮箱格式 | 注册邮箱（需与验证码校验时一致） |
| password | string | 是 | 8-64 位，至少包含字母和数字 | 用户密码 |
| password_confirm | string | 是 | 与 password 一致 | 确认密码 |
| verification_token | string | 是 | 有效的 JWT | 邮箱验证通过后获得的凭证 |

**响应示例**：

成功（201）：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "user": {
      "id": 1001,
      "email": "user@example.com",
      "role": "user",
      "created_at": "2026-04-06T10:30:00Z"
    },
    "access_token": "eyJhbGciOiJSUzI1NiIs...",
    "expires_in": 7200
  }
}
```

注：注册成功后自动登录，返回 Access Token。Refresh Token 不通过注册接口颁发（用户需要在后续登录时勾选"记住我"才获得 Refresh Token）。

| 字段 | 类型 | 说明 |
|------|------|------|
| user | object | 用户基本信息 |
| user.id | integer (int64) | 用户 ID |
| user.email | string | 邮箱 |
| user.role | string | 角色（user） |
| user.created_at | string | 注册时间（ISO 8601） |
| access_token | string | JWT Access Token |
| expires_in | int | Access Token 有效期（秒） |

**失败示例**：

| HTTP 状态码 | 业务错误码 | 说明 |
|------------|-----------|------|
| 400 | 11001 | 邮箱格式不合法 |
| 400 | 11002 | 密码不满足强度要求 |
| 400 | 10001 | 两次密码不一致 |
| 400 | 13002 | verification_token 无效或已过期 |
| 409 | 11003 | 邮箱已被注册（仅正式上线后生效） |

---

### 4.4 用户登录

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/auth/login` |
| 认证 | 否 |
| 权限 | 匿名可访问 |
| 说明 | 使用邮箱和密码登录。可选"记住我"获取 Refresh Token |
| 频率限制 | 同一邮箱每小时 20 次 |

**请求参数**：

Body：

```json
{
  "email": "user@example.com",
  "password": "MyPassword123",
  "remember_me": true
}
```

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|---------|------|
| email | string | 是 | RFC 5322 邮箱格式 | 登录邮箱 |
| password | string | 是 | 非空 | 密码 |
| remember_me | bool | 否（默认 false） | - | 勾选后颁发 Refresh Token |

**响应示例**：

成功（200）：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "user": {
      "id": 1001,
      "email": "user@example.com",
      "role": "user"
    },
    "access_token": "eyJhbGciOiJSUzI1NiIs...",
    "expires_in": 7200
  }
}
```

当 `remember_me=true` 时，响应头额外包含：

```
Set-Cookie: refresh_token=<token>; Path=/api/v1/auth/token; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000
```

| 字段 | 类型 | 说明 |
|------|------|------|
| user | object | 用户基本信息 |
| user.id | integer (int64) | 用户 ID |
| user.email | string | 邮箱 |
| user.role | string | 角色 |
| access_token | string | JWT Access Token |
| expires_in | int | Access Token 有效期（秒） |

**失败示例**：

| HTTP 状态码 | 业务错误码 | 说明 |
|------------|-----------|------|
| 401 | 11004 | 邮箱或密码错误（不区分"邮箱不存在"和"密码错误"） |
| 423 | 11005 | 账号已锁定（响应中包含解锁时间） |
| 429 | 10005 | 请求频率超限 |

锁定时的错误响应包含额外信息：

```json
{
  "code": 11005,
  "message": "账号已锁定，请稍后重试",
  "data": {
    "locked_until": "2026-04-06T10:45:00Z"
  }
}
```

---

### 4.5 刷新 Access Token

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/auth/token/refresh` |
| 认证 | 否（需携带 Refresh Token Cookie） |
| 权限 | 拥有有效 Refresh Token |
| 说明 | 使用 Refresh Token 换取新的 Access Token。采用 Token Rotation，旧 Refresh Token 立即失效 |

**请求参数**：

无 Body。Refresh Token 通过 Cookie 自动携带：

```
Cookie: refresh_token=<token>
```

**响应示例**：

成功（200）：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiIs...",
    "expires_in": 7200
  }
}
```

响应头同时设置新的 Refresh Token Cookie：

```
Set-Cookie: refresh_token=<new_token>; Path=/api/v1/auth/token; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000
```

**失败示例**：

| HTTP 状态码 | 业务错误码 | 说明 |
|------------|-----------|------|
| 401 | 11006 | Refresh Token 无效、已过期或已被撤销 |

---

### 4.6 生成人机校验挑战

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/auth/captcha/challenge` |
| 认证 | 否 |
| 权限 | 匿名可访问 |
| 说明 | 生成一个滑动图片验证的挑战，返回图片资源和挑战 ID |

**请求参数**：

无 Body。

**响应示例**：

成功（200）：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "challenge_id": "ch-uuid-xxx",
    "image_url": "https://cdn.babysocial.com/captcha/bg-xxx.png",
    "puzzle_url": "https://cdn.babysocial.com/captcha/pz-xxx.png",
    "expire_at": "2026-04-06T10:35:00Z"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| challenge_id | string | 挑战唯一标识 |
| image_url | string | 背景图 URL |
| puzzle_url | string | 拼图块 URL |
| expire_at | string | 挑战过期时间（ISO 8601） |

---

### 4.7 验证人机校验结果

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/auth/captcha/verify` |
| 认证 | 否 |
| 权限 | 匿名可访问 |
| 说明 | 验证用户提交的滑动结果。通过后返回一个一次性 captcha_token，用于验证码发送接口 |

**请求参数**：

Body：

```json
{
  "challenge_id": "ch-uuid-xxx",
  "x_position": 156
}
```

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|---------|------|
| challenge_id | string | 是 | 非空 | 挑战 ID |
| x_position | int | 是 | >= 0 | 用户滑动拼图的 X 坐标位置 |

**响应示例**：

成功（200）：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "captcha_token": "ct-signed-token-xxx",
    "expires_in": 300
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| captcha_token | string | 人机校验通过凭证，有效期 5 分钟 |
| expires_in | int | Token 有效期（秒） |

**失败示例**：

| HTTP 状态码 | 业务错误码 | 说明 |
|------------|-----------|------|
| 400 | 13001 | 人机校验失败（滑动位置不正确） |
| 400 | 13002 | 挑战 ID 无效或已过期 |

---

### 4.8 获取当前用户信息

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `GET /api/v1/users/me` |
| 认证 | 是 |
| 权限 | user, admin |
| 说明 | 获取当前登录用户的基本信息 |

**请求参数**：

无。

**响应示例**：

成功（200）：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1001,
    "email": "user@example.com",
    "role": "user",
    "email_verified_at": "2026-04-06T10:30:00Z",
    "created_at": "2026-04-06T10:30:00Z"
  }
}
```

**失败示例**：

| HTTP 状态码 | 业务错误码 | 说明 |
|------------|-----------|------|
| 401 | 10002 | 未认证 |
| 401 | 11007 | Access Token 已过期 |

---

### 4.9 上报埋点事件

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/analytics/events` |
| 认证 | 否（匿名和已登录用户均可上报） |
| 权限 | 匿名可访问 |
| 说明 | 前端埋点事件上报接口。支持批量上报 |

**请求参数**：

Body：

```json
{
  "events": [
    {
      "event_name": "register_page_view",
      "timestamp": "2026-04-06T10:30:00Z",
      "anonymous_id": "anon-uuid-xxx",
      "user_id": 0,
      "session_id": "sess-uuid-xxx",
      "device_id": "dev-uuid-xxx",
      "properties": {
        "referrer": "https://google.com",
        "utm_source": "wechat"
      }
    }
  ]
}
```

| 字段 | 类型 | 必填 | 校验规则 | 说明 |
|------|------|------|---------|------|
| events | array | 是 | 长度 1-50 | 事件数组 |
| events[].event_name | string | 是 | 符合命名规范 | 事件名称 |
| events[].timestamp | string | 是 | ISO 8601 | 事件发生时间 |
| events[].anonymous_id | string | 是 | UUID | 匿名用户标识 |
| events[].user_id | integer (int64) | 否 | > 0 | 已登录用户 ID |
| events[].session_id | string | 是 | UUID | 会话 ID |
| events[].device_id | string | 否 | UUID | 设备 ID |
| events[].properties | object | 否 | - | 事件自定义属性 |

**响应示例**：

成功（202 Accepted）：

```json
{
  "code": 0,
  "message": "accepted",
  "data": {
    "received": 1
  }
}
```

**失败示例**：

| HTTP 状态码 | 业务错误码 | 说明 |
|------------|-----------|------|
| 400 | 10001 | 请求参数校验失败（如事件数组为空或超过 50 条） |

---

### 4.10 手机号注册（预留）

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `POST /api/v1/auth/register/phone` |
| 认证 | 否 |
| 权限 | - |
| 说明 | 预留接口，MVP 阶段返回 501 Not Implemented |

**响应示例**：

```json
{
  "code": 10006,
  "message": "此功能暂未实现"
}
```

HTTP 状态码：501

---

### 4.11 第三方 OAuth 回调（预留）

**基本信息**：

| 项目 | 内容 |
|------|------|
| 路径 | `GET /api/v1/auth/oauth/{provider}/callback` |
| 认证 | 否 |
| 权限 | - |
| 说明 | 预留接口，MVP 阶段返回 501 Not Implemented |

Path 参数：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| provider | string | 是 | OAuth 提供商标识（wechat / github / google） |

**响应示例**：

```json
{
  "code": 10006,
  "message": "此功能暂未实现"
}
```

HTTP 状态码：501

---

## 5. 数据模型

### UserResponse

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer (int64) | 用户 ID |
| email | string | 邮箱地址 |
| role | string | 角色（user / admin） |
| email_verified_at | string | 邮箱验证时间（ISO 8601），未验证时为 null |
| created_at | string | 注册时间（ISO 8601） |

### AuthResponse

| 字段 | 类型 | 说明 |
|------|------|------|
| user | UserResponse | 用户信息 |
| access_token | string | JWT Access Token |
| expires_in | int | Access Token 有效期（秒） |

### TokenResponse

| 字段 | 类型 | 说明 |
|------|------|------|
| access_token | string | 新的 JWT Access Token |
| expires_in | int | Access Token 有效期（秒） |

### ChallengeResponse

| 字段 | 类型 | 说明 |
|------|------|------|
| challenge_id | string | 挑战唯一标识 |
| image_url | string | 背景图 URL |
| puzzle_url | string | 拼图块 URL |
| expire_at | string | 过期时间（ISO 8601） |

### CaptchaVerifyResponse

| 字段 | 类型 | 说明 |
|------|------|------|
| captcha_token | string | 人机校验通过凭证 |
| expires_in | int | Token 有效期（秒） |

### AnalyticsEvent

| 字段 | 类型 | 说明 |
|------|------|------|
| event_name | string | 事件名称 |
| timestamp | string | 事件时间（ISO 8601） |
| anonymous_id | string | 匿名用户 ID |
| user_id | integer (int64) | 登录用户 ID（可空，0 表示匿名） |
| session_id | string | 会话 ID |
| device_id | string | 设备 ID（可空） |
| properties | object | 自定义属性 |

---

## 6. 变更记录

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|---------|------|
| v1.0 | 2026-04-06 | 初始版本 | Backend Architect |
| v1.1 | 2026-04-06 | 主键类型从 UUID 改为 BIGINT (int64)，同步更新所有 id/user_id 字段类型 | Backend Architect |

---

*本文档版本 v1.1，如有修改请更新版本号并记录变更原因。*
