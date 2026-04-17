# 用户注册与登录模块 - 总体架构设计

## 目录

- [1. 文档信息](#1-文档信息)
- [2. 设计概述](#2-设计概述)
- [3. 领域模型](#3-领域模型)
  - [3.1 限界上下文](#31-限界上下文)
  - [3.2 上下文映射图](#32-上下文映射图)
  - [3.3 领域对象](#33-领域对象)
  - [3.4 领域事件](#34-领域事件)
- [4. 系统架构](#4-系统架构)
  - [4.1 架构概览](#41-架构概览)
  - [4.2 分层设计](#42-分层设计)
  - [4.3 模块划分](#43-模块划分)
  - [4.4 模块间通信](#44-模块间通信)
  - [4.5 目录结构](#45-目录结构)
- [5. 安全架构](#5-安全架构)
  - [5.1 认证方案](#51-认证方案)
  - [5.2 授权方案](#52-授权方案)
  - [5.3 数据安全](#53-数据安全)
  - [5.4 API 安全防护](#54-api-安全防护)
- [6. 缓存策略](#6-缓存策略)
- [7. 错误处理](#7-错误处理)
  - [7.1 错误码体系](#71-错误码体系)
  - [7.2 统一错误响应格式](#72-统一错误响应格式)
  - [7.3 重试与降级策略](#73-重试与降级策略)
- [8. 可观测性](#8-可观测性)
  - [8.1 日志规范](#81-日志规范)
  - [8.2 监控指标](#82-监控指标)
  - [8.3 告警策略](#83-告警策略)
- [9. 第三方服务集成](#9-第三方服务集成)
- [10. 数据埋点采集接口设计](#10-数据埋点采集接口设计)
- [11. 部署架构](#11-部署架构)
  - [11.1 部署拓扑](#111-部署拓扑)
  - [11.2 环境隔离](#112-环境隔离)
  - [11.3 配置管理](#113-配置管理)
- [12. 设计决策记录](#12-设计决策记录)
- [13. 待确认事项](#13-待确认事项)

---

## 1. 文档信息

| 字段     | 内容                          |
| -------- | ----------------------------- |
| 文档编号 | ARCH-USER-AUTH-001            |
| 版本     | v1.1                          |
| 作者     | Backend Architect             |
| 创建日期 | 2026-04-06                    |
| 最后更新 | 2026-04-06                    |
| 状态     | 待评审                        |
| 关联 PRD | PRD-USER-AUTH-001             |

---

## 2. 设计概述

本文档定义 BabySocial 平台"用户注册与登录"模块的后端架构设计，覆盖领域建模、分层架构、安全方案、缓存策略、错误处理、可观测性、第三方服务集成和部署架构。

核心设计理念：

- **DDD 驱动**：以"身份认证"限界上下文为核心，将 User 作为聚合根，确保业务规则内聚于领域层。
- **接口抽象**：人机校验、邮件发送等外部能力通过接口抽象，实现可替换。
- **安全优先**：JWT（Access Token + Refresh Token）双令牌方案，bcrypt 密码加密，RBAC 权限控制。
- **可扩展**：认证方式通过策略模式设计，预留手机号注册、第三方 OAuth 登录扩展点。

关键技术选型：

| 项目 | 选型 |
|------|------|
| 语言 | Go |
| Web 框架 | Gin |
| 数据库 | PostgreSQL 15+ |
| 缓存 | Redis 7+ |
| 密码加密 | bcrypt (cost=12) |
| 认证 | JWT (RS256) |
| 迁移工具 | golang-migrate |

---

## 3. 领域模型

### 3.1 限界上下文

| 上下文名称 | 职责描述 | 核心聚合 |
|-----------|---------|---------|
| Identity（身份认证） | 管理用户注册、登录、令牌颁发与刷新、账号锁定、邮箱验证等身份认证全流程 | User 聚合、EmailVerificationCode 聚合、RefreshToken 聚合 |

MVP 阶段仅涉及单一限界上下文。后续 Profile（个人主页）、Chat（AI 助理）等上下文将通过领域事件与 Identity 上下文协作。

### 3.2 上下文映射图

```mermaid
graph LR
    subgraph Identity["Identity 限界上下文（本模块）"]
        U["User 聚合"]
        EVC["EmailVerificationCode 聚合"]
        RT["RefreshToken 聚合"]
    end

    subgraph Profile["Profile 限界上下文（后续迭代）"]
        UP["UserProfile"]
    end

    subgraph Chat["Chat 限界上下文（后续迭代）"]
        CS["ChatSession"]
    end

    Identity -- "UserRegistered 事件 / 防腐层" --> Profile
    Identity -- "User ID 查询 / 防腐层" --> Chat

    style Identity fill:#e1f5fe,stroke:#0288d1
    style Profile fill:#f3e5f5,stroke:#7b1fa2,stroke-dasharray: 5 5
    style Chat fill:#e8f5e9,stroke:#388e3c,stroke-dasharray: 5 5
```

**上下文间关系说明**：

- Identity -> Profile：下游（Downstream）。Identity 发布 `UserRegistered` 领域事件，Profile 上下文订阅该事件以创建初始用户资料。使用防腐层（ACL）隔离。
- Identity -> Chat：下游（Downstream）。Chat 上下文通过防腐层查询用户基础信息（ID、角色），不直接依赖 Identity 领域模型。

### 3.3 领域对象

#### User 聚合

| 对象类型 | 名称 | 说明 |
|---------|------|------|
| 聚合根 | User | 用户实体，承载注册、登录、锁定等核心业务规则 |
| 值对象 | Email | 邮箱地址，封装格式校验逻辑（RFC 5322） |
| 值对象 | Password | 密码，封装强度校验规则（8-64位，至少包含字母和数字） |
| 值对象 | PasswordHash | 加密后的密码哈希值，封装 bcrypt 比对逻辑 |
| 值对象 | Role | 用户角色枚举（user / admin） |
| 值对象 | UserID | 用户唯一标识，BIGINT 自增（后续可切换为 Snowflake ID） |

**User 聚合根核心业务规则**：

1. 注册时，密码必须满足强度要求（8-64位，含字母+数字），系统自动分配角色 `user`。
2. 登录时，校验密码哈希值。连续失败 5 次，锁定账号 15 分钟。
3. 锁定状态的账号拒绝登录请求，直到锁定到期。
4. 邮箱唯一性通过配置开关控制（测试阶段关闭，正式上线前开启）。

#### EmailVerificationCode 聚合

| 对象类型 | 名称 | 说明 |
|---------|------|------|
| 聚合根 | EmailVerificationCode | 邮箱验证码实体，管理验证码的生成、校验、过期、使用状态 |
| 值对象 | VerificationCode | 6 位数字验证码 |

**核心业务规则**：

1. 验证码有效期 10 分钟。
2. 同一邮箱在冷却期（60 秒）内不可重复发送。
3. 验证码最多允许验证 5 次，超过后失效，需重新获取。
4. 验证成功后标记为已使用，不可再次使用。

#### RefreshToken 聚合

| 对象类型 | 名称 | 说明 |
|---------|------|------|
| 聚合根 | RefreshToken | 刷新令牌实体，管理令牌的颁发、使用、撤销 |
| 值对象 | TokenHash | 令牌哈希值（SHA-256），数据库中不存储明文 |

**核心业务规则**：

1. 每次登录成功（勾选"记住我"）时颁发 Refresh Token，有效期 30 天。
2. Refresh Token 用于换取新的 Access Token。
3. 令牌可被主动撤销（用户登出时）。
4. 数据库存储令牌的 SHA-256 哈希值，不存储明文。

### 3.4 领域事件

| 事件名称 | 触发条件 | 事件数据 | 消费方 |
|---------|---------|---------|--------|
| UserRegistered | 用户注册成功 | user_id, email, role, registered_at | Profile 上下文（创建初始资料）、数据埋点（register_complete） |
| UserLoggedIn | 用户登录成功 | user_id, login_at, remember_me | 数据埋点（login_success） |
| UserLoginFailed | 用户登录失败 | email, fail_count, reason | 数据埋点（login_fail） |
| AccountLocked | 账号被锁定 | user_id, locked_until | 数据埋点（account_locked） |
| VerificationCodeSent | 验证码已发送 | email, sent_at | 数据埋点（verification_code_send） |
| VerificationCodeVerified | 验证码验证成功 | email, verified_at | 数据埋点（verification_code_verify_success） |
| TokenRefreshed | Token 刷新成功 | user_id, refreshed_at | 数据埋点（token_refresh） |

---

## 4. 系统架构

### 4.1 架构概览

```mermaid
graph TB
    Client["Frontend (React)"]
    
    subgraph Backend["Go Backend"]
        subgraph Interfaces["interfaces 层"]
            Router["Gin Router"]
            AuthHandler["AuthHandler"]
            Middleware["JWT / RBAC / RateLimit 中间件"]
        end
        
        subgraph Application["application 层"]
            AuthService["AuthService"]
            TokenService["TokenService"]
            VerificationService["VerificationService"]
            EventPublisher["EventPublisher"]
        end
        
        subgraph Domain["domain 层"]
            UserAggregate["User 聚合"]
            CodeAggregate["EmailVerificationCode 聚合"]
            TokenAggregate["RefreshToken 聚合"]
            UserRepo["UserRepository (接口)"]
            CodeRepo["VerificationCodeRepository (接口)"]
            TokenRepo["RefreshTokenRepository (接口)"]
            Verifier["HumanVerifier (接口)"]
            Mailer["EmailSender (接口)"]
        end
        
        subgraph Infrastructure["infrastructure 层"]
            PGUserRepo["PostgresUserRepository"]
            PGCodeRepo["PostgresVerificationCodeRepository"]
            PGTokenRepo["PostgresRefreshTokenRepository"]
            SliderVerifier["SliderCaptchaVerifier"]
            SMTPMailer["SMTPEmailSender"]
            RedisCache["RedisCache"]
        end
    end
    
    subgraph External["外部服务"]
        PG["PostgreSQL"]
        Redis["Redis"]
        SMTP["邮件服务 (SMTP/SendGrid)"]
    end
    
    Client --> Router
    Router --> Middleware --> AuthHandler
    AuthHandler --> AuthService
    AuthHandler --> TokenService
    AuthHandler --> VerificationService
    AuthService --> UserAggregate
    AuthService --> UserRepo
    AuthService --> EventPublisher
    VerificationService --> CodeAggregate
    VerificationService --> CodeRepo
    VerificationService --> Verifier
    VerificationService --> Mailer
    TokenService --> TokenAggregate
    TokenService --> TokenRepo
    
    PGUserRepo -.-> UserRepo
    PGCodeRepo -.-> CodeRepo
    PGTokenRepo -.-> TokenRepo
    SliderVerifier -.-> Verifier
    SMTPMailer -.-> Mailer
    
    PGUserRepo --> PG
    PGCodeRepo --> PG
    PGTokenRepo --> PG
    RedisCache --> Redis
    SMTPMailer --> SMTP
```

### 4.2 分层设计

| 层级 | 职责 | 依赖方向 | 主要组件 |
|------|------|---------|---------|
| interfaces | HTTP handlers、路由定义、请求/响应 DTO 转换、中间件 | -> application | AuthHandler, JWT Middleware, RBAC Middleware, RateLimit Middleware |
| application | 用例编排、事务管理、领域事件发布、DTO 定义 | -> domain | AuthService, TokenService, VerificationService, EventPublisher |
| domain | 领域模型、业务规则、Repository 接口定义、外部服务接口定义 | 无外部依赖 | User, EmailVerificationCode, RefreshToken, 各 Repository 接口, HumanVerifier, EmailSender |
| infrastructure | 数据库访问实现、外部服务调用实现、缓存实现 | 实现 domain 接口 | PostgresXxxRepository, SliderCaptchaVerifier, SMTPEmailSender, RedisCache |

**依赖规则**：严格遵循依赖倒置原则。domain 层定义接口，infrastructure 层提供实现。interfaces 层和 application 层不直接依赖 infrastructure 层的具体实现。所有依赖通过构造函数注入（Constructor Injection）。

### 4.3 模块划分

| 模块 | 限界上下文 | 核心职责 | 对外接口 |
|------|-----------|---------|---------|
| auth | Identity | 用户注册、密码登录、邮箱验证、人机校验 | POST /api/v1/auth/register, POST /api/v1/auth/login, POST /api/v1/auth/register/send-code, POST /api/v1/auth/register/verify-code |
| token | Identity | JWT 颁发、Access Token 刷新、Refresh Token 管理 | POST /api/v1/auth/token/refresh |
| captcha | Identity（基础设施） | 人机校验挑战生成与验证 | POST /api/v1/auth/captcha/challenge, POST /api/v1/auth/captcha/verify |

### 4.4 模块间通信

MVP 阶段，Identity 限界上下文内部各模块通过同步函数调用通信，不引入消息队列。

领域事件在 MVP 阶段采用进程内同步发布模式（in-process event bus），后续可升级为消息队列（如 RabbitMQ / NATS）。事件发布者调用 `EventPublisher.Publish(event)`，订阅者在同一进程内同步执行。

与 Profile 上下文的跨上下文通信，在 MVP 阶段通过进程内事件总线完成。`UserRegistered` 事件发布后，Profile 模块的事件处理器同步创建初始用户资料。

### 4.5 目录结构

```
backend/
├── cmd/
│   └── server/
│       └── main.go                    # 应用入口，依赖注入组装
├── internal/
│   ├── domain/
│   │   └── identity/
│   │       ├── user.go                # User 聚合根 + Email/Password/Role 值对象
│   │       ├── user_repository.go     # UserRepository 接口
│   │       ├── verification_code.go   # EmailVerificationCode 聚合根
│   │       ├── verification_code_repository.go
│   │       ├── refresh_token.go       # RefreshToken 聚合根
│   │       ├── refresh_token_repository.go
│   │       ├── email_sender.go        # EmailSender 接口
│   │       ├── human_verifier.go      # HumanVerifier 接口
│   │       └── events.go             # 领域事件定义
│   ├── application/
│   │   └── identity/
│   │       ├── auth_service.go        # 注册、登录用例
│   │       ├── token_service.go       # Token 颁发、刷新用例
│   │       ├── verification_service.go # 验证码发送、校验用例
│   │       ├── dto.go                 # 应用层 DTO
│   │       └── event_publisher.go     # 事件发布器接口
│   ├── infrastructure/
│   │   ├── persistence/
│   │   │   ├── postgres/
│   │   │   │   ├── user_repository.go
│   │   │   │   ├── verification_code_repository.go
│   │   │   │   ├── refresh_token_repository.go
│   │   │   │   └── db.go             # 数据库连接池
│   │   │   └── redis/
│   │   │       ├── cache.go           # Redis 通用缓存操作
│   │   │       └── rate_limiter.go    # 频率限制器
│   │   ├── email/
│   │   │   ├── smtp_sender.go         # SMTP 实现
│   │   │   └── sendgrid_sender.go     # SendGrid 实现（备选）
│   │   ├── captcha/
│   │   │   └── slider_verifier.go     # 滑动图片校验实现
│   │   └── event/
│   │       └── in_process_publisher.go # 进程内事件总线
│   └── interfaces/
│       └── http/
│           ├── router.go              # 路由注册
│           ├── middleware/
│           │   ├── jwt.go             # JWT 认证中间件
│           │   ├── rbac.go            # RBAC 授权中间件
│           │   ├── rate_limit.go      # 频率限制中间件
│           │   ├── cors.go            # CORS 中间件
│           │   └── request_id.go      # 请求 ID 中间件
│           ├── handler/
│           │   ├── auth_handler.go    # 注册/登录 handler
│           │   ├── token_handler.go   # Token 相关 handler
│           │   ├── captcha_handler.go # 人机校验 handler
│           │   └── analytics_handler.go # 埋点事件接收 handler
│           ├── request/
│           │   └── auth_request.go    # 请求 DTO
│           └── response/
│               ├── auth_response.go   # 响应 DTO
│               └── common.go          # 通用响应封装
├── pkg/
│   ├── config/
│   │   └── config.go                  # 配置加载
│   ├── errors/
│   │   └── errors.go                  # 全局错误码定义
│   ├── jwt/
│   │   └── jwt.go                     # JWT 工具（签发、解析）
│   ├── logger/
│   │   └── logger.go                  # 结构化日志
│   └── validator/
│       └── validator.go               # 通用输入校验
├── migrations/
│   ├── 000001_create_users_table.up.sql
│   ├── 000001_create_users_table.down.sql
│   ├── 000002_create_email_verification_codes_table.up.sql
│   ├── 000002_create_email_verification_codes_table.down.sql
│   ├── 000003_create_refresh_tokens_table.up.sql
│   ├── 000003_create_refresh_tokens_table.down.sql
│   ├── 000004_create_analytics_events_table.up.sql
│   └── 000004_create_analytics_events_table.down.sql
├── go.mod
└── go.sum
```

---

## 5. 安全架构

### 5.1 认证方案

采用 JWT 双令牌方案：Access Token + Refresh Token。

**Access Token**：

| 项目 | 设计 |
|------|------|
| 算法 | RS256（非对称签名） |
| 有效期 | 2 小时 |
| 存储位置 | 前端内存（不持久化到 localStorage），通过 HTTP Response Body 返回 |
| Payload | `{ sub: user_id (int64), role: "user", exp: timestamp, iat: timestamp, jti: uuid }` |
| 使用方式 | `Authorization: Bearer <access_token>` |

**Refresh Token**：

| 项目 | 设计 |
|------|------|
| 格式 | 随机字符串（crypto/rand 生成，64 字节 base64 编码） |
| 有效期 | 30 天（勾选"记住我"）/ 不颁发（未勾选） |
| 存储位置 | 前端 HttpOnly + Secure + SameSite=Strict Cookie |
| 后端存储 | PostgreSQL refresh_tokens 表，存储 SHA-256 哈希值 |
| 使用方式 | 通过 Cookie 自动携带至 POST /api/v1/auth/token/refresh |

**Token 签发流程**：

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    participant DB as PostgreSQL
    participant R as Redis

    C->>S: POST /api/v1/auth/login {email, password, remember_me}
    S->>R: 检查账号锁定状态
    R-->>S: 未锁定
    S->>DB: 查询用户 by email
    DB-->>S: User record
    S->>S: bcrypt.Compare(password, hash)
    
    alt 密码正确
        S->>S: 生成 Access Token (JWT RS256)
        S->>R: 重置登录失败计数
        alt remember_me = true
            S->>S: 生成 Refresh Token (随机字符串)
            S->>DB: 存储 SHA-256(refresh_token)
            S-->>C: 200 {access_token, expires_in} + Set-Cookie: refresh_token
        else remember_me = false
            S-->>C: 200 {access_token, expires_in}
        end
    else 密码错误
        S->>R: INCR 登录失败计数 (TTL 15min)
        alt 失败次数 >= 5
            S->>DB: UPDATE users SET is_locked=true, locked_until=now()+15min
            S-->>C: 423 账号已锁定
        else 失败次数 < 5
            S-->>C: 401 邮箱或密码错误
        end
    end
```

**Token 刷新流程**：

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    participant DB as PostgreSQL

    C->>S: POST /api/v1/auth/token/refresh (Cookie: refresh_token)
    S->>S: 计算 SHA-256(refresh_token)
    S->>DB: 查询 refresh_tokens WHERE token_hash = hash
    DB-->>S: RefreshToken record
    
    alt Token 有效且未过期、未撤销
        S->>S: 生成新 Access Token
        S->>S: 生成新 Refresh Token（Token Rotation）
        S->>DB: 撤销旧 Refresh Token + 存储新 Token
        S-->>C: 200 {access_token, expires_in} + Set-Cookie: new_refresh_token
    else Token 无效/过期/已撤销
        S-->>C: 401 Token 无效
    end
```

**设计决策 - Token Rotation**：每次使用 Refresh Token 刷新时，旧的 Refresh Token 立即失效，同时颁发新的 Refresh Token。这样即使 Refresh Token 被窃取，攻击者和合法用户中只有一个能成功刷新，另一方会触发异常检测。

### 5.2 授权方案

采用 RBAC（基于角色的访问控制）模型。

**角色定义**：

| 角色 | 标识 | 说明 |
|------|------|------|
| 普通用户 | user | 默认角色，注册时自动分配，可使用平台社交功能 |
| 管理员 | admin | 具备用户管理、内容审核等后台权限，由已有管理员手动授权 |

**接口权限矩阵**：

| 接口 | 匿名 | user | admin |
|------|------|------|-------|
| POST /api/v1/auth/register | Y | - | - |
| POST /api/v1/auth/register/send-code | Y | - | - |
| POST /api/v1/auth/register/verify-code | Y | - | - |
| POST /api/v1/auth/login | Y | - | - |
| POST /api/v1/auth/token/refresh | Y | - | - |
| POST /api/v1/auth/captcha/challenge | Y | - | - |
| POST /api/v1/auth/captcha/verify | Y | - | - |
| GET /api/v1/users/me | - | Y | Y |
| POST /api/v1/analytics/events | Y | Y | Y |

**RBAC 中间件实现**：

1. JWT 中间件从请求头提取 Access Token，解析 payload，将 `user_id` 和 `role` 注入请求上下文。
2. RBAC 中间件从上下文读取 `role`，与接口要求的最低角色进行比对。
3. 不满足权限要求时，返回 403 Forbidden。

### 5.3 数据安全

| 数据类型 | 安全措施 |
|---------|---------|
| 密码 | bcrypt 加密，cost factor = 12。原始密码不记录日志、不持久化 |
| Access Token | RS256 非对称签名。私钥通过环境变量注入，禁止硬编码。Token 仅存于客户端内存 |
| Refresh Token | 数据库存储 SHA-256 哈希值，不存明文。前端通过 HttpOnly Cookie 传输 |
| 验证码 | 数据库明文存储（6 位数字，有效期短），但接口响应中不返回验证码内容 |
| JWT 密钥 | RS256 密钥对。通过 `JWT_PRIVATE_KEY`、`JWT_PUBLIC_KEY` 环境变量注入，各环境独立生成，不共享 |
| 邮箱 | 日志中脱敏显示（如 `u***@example.com`），数据库正常存储 |

### 5.4 API 安全防护

| 防护项 | 方案 |
|--------|------|
| 限流 | Redis 令牌桶。全局：每 IP 每分钟 60 次。验证码发送：每 IP 每小时 20 次。登录：每邮箱每小时 20 次 |
| 防重放 | JWT 包含 `jti`（JWT ID），关键写操作可选检查 `jti` 唯一性 |
| 防注入 | 所有 SQL 使用参数化查询（`$1, $2` 占位符），所有用户输入后端二次校验 |
| CORS | 仅允许前端域名来源（开发环境允许 `localhost:3000`），禁止 `*` |
| HTTPS | 生产环境强制 HTTPS，HSTS 头启用。开发环境允许 HTTP |
| 敏感参数 | 验证码、密码等禁止出现在 URL Query String 中，仅通过 POST Body 传递 |

---

## 6. 缓存策略

| 缓存对象 | 缓存层 | 失效策略 | TTL | 说明 |
|---------|--------|---------|-----|------|
| 登录失败计数（per email） | Redis | TTL 自动过期 | 15 分钟 | key: `login_fail:{email}`，INCR 计数，达到 5 次触发锁定 |
| 验证码冷却状态（per email） | Redis | TTL 自动过期 | 60 秒 | key: `code_cooldown:{email}`，存在则拒绝重发 |
| IP 频率限制 | Redis | 滑动窗口 | 1 小时 | key: `rate_limit:send_code:{ip}`，限制每小时 20 次 |
| 全局 IP 频率限制 | Redis | 滑动窗口 | 1 分钟 | key: `rate_limit:global:{ip}`，限制每分钟 60 次 |

**设计决策 - 引入 Redis**：

验证码冷却（60s）、登录失败计数（15min TTL）、IP 频率限制等场景具有以下特点：短时高频读写、需要精确 TTL 过期、不需要持久化。这些特点天然适合 Redis。如果使用 PostgreSQL 承担这些职责，需要额外实现定时清理机制，且高频写入会增加数据库负载。

**被否决的备选方案**：

- 方案 B：仅用 PostgreSQL + 定时清理。否决原因：高频写入影响主库性能，TTL 实现复杂，需要额外的定时任务。
- 方案 C：进程内 Map 缓存。否决原因：多实例部署时数据不共享，且无法跨重启保持状态。

---

## 7. 错误处理

### 7.1 错误码体系

采用 5 位数字错误码，高两位标识模块，低三位标识具体错误。

| 错误码范围 | 模块 | 说明 |
|-----------|------|------|
| 10000-10999 | 通用 | 参数校验、权限、服务器内部错误等 |
| 11000-11999 | 认证（Auth） | 注册、登录、令牌相关错误 |
| 12000-12999 | 验证码（Verification） | 验证码发送、校验相关错误 |
| 13000-13999 | 人机校验（Captcha） | 人机校验相关错误 |

**通用错误码**：

| 错误码 | HTTP 状态码 | 说明 |
|--------|-----------|------|
| 10001 | 400 | 请求参数校验失败 |
| 10002 | 401 | 未认证（缺少或无效的 Token） |
| 10003 | 403 | 无权限访问 |
| 10004 | 404 | 资源不存在 |
| 10005 | 429 | 请求频率超限 |
| 10006 | 500 | 服务器内部错误 |

**认证错误码**：

| 错误码 | HTTP 状态码 | 说明 |
|--------|-----------|------|
| 11001 | 400 | 邮箱格式不合法 |
| 11002 | 400 | 密码不满足强度要求 |
| 11003 | 409 | 邮箱已被注册（正式上线后启用） |
| 11004 | 401 | 邮箱或密码错误（不区分具体原因） |
| 11005 | 423 | 账号已锁定，请稍后重试 |
| 11006 | 401 | Refresh Token 无效或已过期 |
| 11007 | 401 | Access Token 已过期 |

**验证码错误码**：

| 错误码 | HTTP 状态码 | 说明 |
|--------|-----------|------|
| 12001 | 429 | 验证码发送冷却中，请稍后重试 |
| 12002 | 400 | 验证码错误 |
| 12003 | 410 | 验证码已过期 |
| 12004 | 429 | 验证码验证次数超限，请重新获取 |
| 12005 | 500 | 验证码发送失败（邮件服务异常） |

**人机校验错误码**：

| 错误码 | HTTP 状态码 | 说明 |
|--------|-----------|------|
| 13001 | 400 | 人机校验失败 |
| 13002 | 400 | 人机校验 Token 无效或已过期 |

### 7.2 统一错误响应格式

```json
{
  "code": 11004,
  "message": "邮箱或密码错误",
  "details": "invalid credentials for email u***@example.com"
}
```

- `code`：业务错误码（成功时为 0）
- `message`：用户可读的错误描述（可直接展示给前端用户）
- `details`：调试信息，仅在非生产环境返回。生产环境该字段为空字符串

### 7.3 重试与降级策略

| 外部服务 | 超时时间 | 重试次数 | 降级方案 |
|---------|---------|---------|---------|
| 邮件服务（SMTP/SendGrid） | 10 秒 | 最多 2 次（指数退避） | 返回 12005 错误码，前端提示用户"发送失败，请稍后重试"。不静默失败 |
| 人机校验 | 5 秒 | 1 次 | 返回 13001 错误码，前端提示用户重试 |
| Redis | 3 秒 | 不重试 | 降级到 PostgreSQL 查询（频率限制临时失效，以保证核心注册登录流程可用） |
| PostgreSQL | 5 秒 | 不重试 | 返回 10006 服务器内部错误 |

**幂等性设计**：

- 验证码发送：通过 Redis 冷却 key 天然幂等，60 秒内重复请求返回 12001。
- 注册：通过邮箱唯一性约束保证幂等（正式上线后）。测试阶段通过验证码 `used_at` 字段保证同一验证码不会导致重复注册。
- Token 刷新：Refresh Token Rotation 机制保证每个 Token 只能使用一次。

---

## 8. 可观测性

### 8.1 日志规范

使用结构化 JSON 日志（基于 Go `slog` 标准库）。

| 日志级别 | 使用场景 | 示例 |
|---------|---------|------|
| ERROR | 系统异常、外部服务调用失败 | 邮件发送失败、数据库连接断开、Redis 不可用 |
| WARN | 业务告警、安全事件 | 账号锁定、异常频率请求、验证码重试超限 |
| INFO | 核心业务操作 | 用户注册成功、登录成功、Token 刷新 |
| DEBUG | 调试信息（仅开发环境） | SQL 查询详情、请求/响应 Body、缓存命中情况 |

**日志结构**：

```json
{
  "time": "2026-04-06T10:30:00Z",
  "level": "INFO",
  "msg": "user registered",
  "request_id": "req-uuid-xxx",
  "user_id": 1001,
  "email": "u***@example.com",
  "ip": "192.168.1.x",
  "duration_ms": 120
}
```

**安全要求**：

- 密码、Token 明文禁止写入日志。
- 邮箱在日志中脱敏显示。
- 日志中包含 `request_id` 用于链路追踪。

### 8.2 监控指标

| 指标名称 | 类型 | 说明 | 对应 PRD 指标 |
|---------|------|------|-------------|
| auth_register_total | Counter | 注册请求总数（按结果标签 success/fail 区分） | 注册转化率 |
| auth_login_total | Counter | 登录请求总数（按结果标签区分） | 登录成功率 |
| auth_login_duration_seconds | Histogram | 登录接口响应时间分布 | 登录接口 P99 |
| auth_register_duration_seconds | Histogram | 注册接口响应时间分布 | 注册接口 P99 |
| auth_account_locked_total | Counter | 账号锁定触发次数 | 账号锁定率 |
| auth_verification_code_sent_total | Counter | 验证码发送总数（按结果标签区分） | 验证码发送失败率 |
| auth_token_refresh_total | Counter | Token 刷新请求总数 | Token 刷新成功率 |
| auth_captcha_verify_total | Counter | 人机校验总数（按结果标签区分） | 人机校验通过率 |

指标暴露方式：通过 `/metrics` 端点暴露 Prometheus 格式指标。

### 8.3 告警策略

| 告警条件 | 级别 | 通知渠道 | 对应 PRD 阈值 |
|---------|------|---------|-------------|
| 注册接口 P99 > 500ms 持续 5 分钟 | P1 | 邮件 + 飞书/钉钉 | PRD 4.3 |
| 登录接口 P99 > 300ms 持续 5 分钟 | P1 | 邮件 + 飞书/钉钉 | PRD 4.3 |
| 验证码发送失败率 > 1% 持续 5 分钟 | P0 | 邮件 + 飞书/钉钉 + 电话 | PRD 8.3 |
| 账号锁定率 > 10%（日维度） | P1 | 邮件 + 飞书/钉钉 | PRD 8.3 |
| 账号锁定率 > 5%（日维度） | P2 | 邮件 | PRD 8.3 |
| Redis 连接失败 | P0 | 邮件 + 飞书/钉钉 + 电话 | - |
| PostgreSQL 连接失败 | P0 | 邮件 + 飞书/钉钉 + 电话 | - |
| 人机校验通过率 < 80%（日维度） | P2 | 邮件 | PRD 8.3 |

---

## 9. 第三方服务集成

| 服务 | 抽象接口 | MVP 实现 | 可替换方案 | 降级策略 |
|------|---------|---------|-----------|---------|
| 邮件发送 | `EmailSender` | SMTP（自建或企业邮箱） | SendGrid, AWS SES, Mailgun | 返回错误码 12005，前端提示用户重试 |
| 人机校验 | `HumanVerifier` | 滑动图片验证（自实现或开源组件） | Google reCAPTCHA, 极验, 数美 | 返回错误码 13001，前端提示重试 |

**EmailSender 接口定义**（domain 层）：

```go
type EmailSender interface {
    SendVerificationCode(ctx context.Context, to string, code string) error
}
```

**HumanVerifier 接口定义**（domain 层）：

```go
type ChallengeResult struct {
    ChallengeID string
    ImageURL    string // 滑动验证背景图
    PuzzleURL   string // 滑动验证拼图块
    ExpireAt    time.Time
}

type HumanVerifier interface {
    GenerateChallenge(ctx context.Context) (*ChallengeResult, error)
    Verify(ctx context.Context, challengeID string, userResponse string) (bool, error)
}
```

**实现选型建议（邮件服务）**：

- **MVP 推荐**：SendGrid 免费层（100 封/天），满足开发测试需求，API 简洁。
- **正式上线**：根据量级评估 AWS SES（成本低、高吞吐）或继续使用 SendGrid 付费层。
- **最终决策依赖 PRD Q-01 的确认**。

---

## 10. 数据埋点采集接口设计

根据数据分析规划（`docs/analytics/babysocial-mvp.md`），用户注册与登录模块需要采集以下埋点事件。

### 10.1 后端自动埋点

以下事件由后端在业务逻辑中自动触发，无需前端参与：

| 事件名 | 触发位置 | 实现方式 |
|--------|---------|---------|
| verification_code_send | VerificationService.SendCode | 发送成功后通过 EventPublisher 发布 |
| verification_code_send_fail | VerificationService.SendCode | 发送失败时通过 EventPublisher 发布 |
| verification_code_submit | VerificationService.VerifyCode | 验证请求时记录 |
| verification_code_verify_success | VerificationService.VerifyCode | 验证成功时记录 |
| verification_code_verify_fail | VerificationService.VerifyCode | 验证失败时记录 |
| register_complete | AuthService.Register | 注册成功后通过 UserRegistered 领域事件触发 |
| login_submit | AuthService.Login | 登录请求时记录 |
| login_success | AuthService.Login | 登录成功时通过 UserLoggedIn 领域事件触发 |
| login_fail | AuthService.Login | 登录失败时通过 UserLoginFailed 领域事件触发 |
| account_locked | AuthService.Login | 锁定触发时通过 AccountLocked 领域事件触发 |
| token_refresh | TokenService.Refresh | 刷新成功时通过 TokenRefreshed 领域事件触发 |
| token_refresh_fail | TokenService.Refresh | 刷新失败时记录 |

### 10.2 前端上报接口

前端埋点事件（如 `register_page_view`, `captcha_challenge_show`, `register_funnel_drop`, `login_page_view` 等）通过统一的事件上报接口提交：

```
POST /api/v1/analytics/events
```

接口设计详见 API 契约文档（contracts-user-auth.md）。

### 10.3 埋点数据存储

MVP 阶段，后端埋点事件写入 PostgreSQL `analytics_events` 表。前端上报的事件通过 API 写入同一张表。后续可切换为 ClickHouse 或大数据平台。

---

## 11. 部署架构

### 11.1 部署拓扑

```mermaid
graph TB
    subgraph Development["开发环境 (Local)"]
        DevApp["Go Backend<br/>(go run)"]
        DevReact["React Dev Server<br/>(npm start)"]
        DevDocker["Docker Compose"]
        DevPG["PostgreSQL<br/>(容器 :5432)"]
        DevRedis["Redis<br/>(容器 :6379)"]
        DevMailhog["MailHog<br/>(容器 :1025/:8025)"]
    end

    DevDocker --> DevPG
    DevDocker --> DevRedis
    DevDocker --> DevMailhog
    DevApp --> DevPG
    DevApp --> DevRedis
    DevApp --> DevMailhog
    DevReact --> DevApp

    subgraph Production["生产环境"]
        Nginx["Nginx (HTTPS + 反向代理)"]
        ProdApp["Go Backend<br/>(Docker 容器)"]
        ProdPG["PostgreSQL<br/>(Docker 容器 / 云 RDS)"]
        ProdRedis["Redis<br/>(Docker 容器 / 云 ElastiCache)"]
        ProdMail["邮件服务<br/>(SendGrid / AWS SES)"]
    end

    Nginx --> ProdApp
    ProdApp --> ProdPG
    ProdApp --> ProdRedis
    ProdApp --> ProdMail
```

### 11.2 环境隔离

| 环境 | 用途 | 数据库 | Redis | 邮件服务 | 配置来源 |
|------|------|--------|-------|---------|---------|
| dev | 本地开发 | Docker PostgreSQL (localhost:5432) | Docker Redis (localhost:6379) | MailHog（本地 SMTP 模拟） | .env 文件 |
| test | CI/CD 自动化测试 | Docker PostgreSQL（临时实例） | Docker Redis（临时实例） | Mock 实现 | 环境变量 |
| prod | 生产 | 云 RDS / Docker PostgreSQL | 云 ElastiCache / Docker Redis | SendGrid / AWS SES | 环境变量 + Secrets Manager |

### 11.3 配置管理

所有配置通过环境变量注入，通过 `.env` 文件管理本地开发配置。

| 环境变量 | 说明 | 示例值 | 必填 |
|---------|------|--------|------|
| `APP_ENV` | 运行环境 | dev / test / prod | 是 |
| `APP_PORT` | 服务端口 | 8080 | 是 |
| `DATABASE_URL` | PostgreSQL 连接字符串 | postgresql://postgres:postgres@localhost:5432/babysocial | 是 |
| `REDIS_URL` | Redis 连接字符串 | redis://localhost:6379/0 | 是 |
| `JWT_PRIVATE_KEY` | JWT RS256 私钥（PEM 格式，通过 `openssl genrsa` 生成） | -----BEGIN RSA PRIVATE KEY----- ... | 是 |
| `JWT_PUBLIC_KEY` | JWT RS256 公钥（PEM 格式） | -----BEGIN PUBLIC KEY----- ... | 是 |
| `SMTP_HOST` | SMTP 服务器地址 | smtp.sendgrid.net | 是 |
| `SMTP_PORT` | SMTP 端口 | 587 | 是 |
| `SMTP_USERNAME` | SMTP 用户名 | apikey | 是 |
| `SMTP_PASSWORD` | SMTP 密码/API Key | SG.xxxxx | 是 |
| `SMTP_FROM` | 发件人邮箱 | noreply@babysocial.com | 是 |
| `CORS_ALLOWED_ORIGINS` | 允许的 CORS 来源 | http://localhost:3000 | 是 |
| `ALLOW_DUPLICATE_EMAIL` | 是否允许重复邮箱注册（测试阶段开关） | true / false | 是 |

---

## 12. 设计决策记录

| 编号 | 决策 | 理由 | 被否决的备选方案 |
|------|------|------|----------------|
| DR-01 | JWT 使用 RS256（非对称签名）而非 HS256（对称签名） | 非对称签名允许公钥公开用于验证，私钥仅服务端持有。后续如果引入微服务或第三方验证 Token，无需共享密钥 | HS256：更简单，性能更好，但所有验证方都需持有同一密钥，扩展性差 |
| DR-02 | Refresh Token 存储于 HttpOnly Cookie 而非 localStorage | HttpOnly Cookie 不可被 JavaScript 访问，防止 XSS 窃取 Token | localStorage：前端使用更方便，但 XSS 攻击可直接读取；Body 返回 + 前端内存存储：页面刷新后丢失，无法实现"记住我" |
| DR-03 | 引入 Redis 而非仅用 PostgreSQL | 验证码冷却（60s TTL）、登录失败计数（15min TTL）、IP 频率限制均为短时高频操作，Redis 原生支持 TTL 和原子计数，性能远优于数据库 | 纯 PostgreSQL：可行但需额外实现清理机制，高频写入影响主库。进程内缓存：多实例不共享 |
| DR-04 | Web 框架选用 Gin 而非标准库 net/http | Gin 提供路由分组、中间件链、参数绑定、JSON 渲染等开箱即用能力，社区活跃，性能接近标准库 | net/http：零依赖但需手动实现路由、中间件等基础设施。Echo：功能相似但社区规模略小于 Gin。Fiber：基于 fasthttp，与标准库 net/http 不完全兼容 |
| DR-05 | 密码加密使用 bcrypt (cost=12) | PRD 明确要求 bcrypt，cost=12 在当前硬件下约 250ms，安全性和性能平衡良好 | Argon2id：更现代，抗 GPU 攻击更强，但 Go 生态支持不如 bcrypt 成熟。scrypt：介于两者之间，优势不明显 |
| DR-06 | Token Rotation（Refresh Token 一次性使用） | 即使 Refresh Token 泄露，攻击者和合法用户中只有一个能成功刷新，另一方触发异常 | 长期有效 Refresh Token：实现简单，但泄露后攻击者可持续使用直到过期 |
| DR-07 | 进程内事件总线而非消息队列 | MVP 阶段单体架构，进程内事件总线足够，避免引入额外中间件复杂度 | RabbitMQ / NATS：可靠但 MVP 阶段过度设计，运维成本高 |
| DR-08 | 迁移工具选用 golang-migrate | 支持 SQL 原生迁移文件（up/down），与 PostgreSQL 兼容良好，CLI 和代码库双模式 | goose：功能相似但社区规模略小。GORM AutoMigrate：与 DDD 理念冲突，隐式迁移不利于版本控制 |
| DR-09 | 登录失败计数存 Redis 而非数据库 `users` 表 | 频繁更新 users 表的失败计数会产生大量行级锁和 WAL 日志，影响正常读写性能。Redis INCR 是原子操作，带 TTL 自动过期 | 存 users 表：每次失败都 UPDATE，15 分钟后需要清理逻辑 |
| DR-10 | 埋点事件 MVP 阶段存 PostgreSQL 而非 ClickHouse | MVP 阶段事件量小，PostgreSQL 完全承受得住，避免引入额外的列存数据库运维成本 | ClickHouse：高性能分析型存储，但 MVP 阶段是过度设计 |
| DR-11 | 主键使用 BIGINT 自增而非 UUID v4 | 索引性能：BIGINT 顺序写入避免 B-tree 页分裂，存储空间仅 8 字节（UUID 为 16 字节），减半的键长度带来更高的 B-tree 缓存命中率。后续如需分布式 ID，可切换为 Snowflake ID（仍为 BIGINT，64-bit 有序），无需变更列类型 | UUID v4：随机写入导致 B-tree 页分裂严重，索引膨胀快；占用空间大（16 字节）；JOIN 和 WHERE 比较性能低于整型 |

---

## 13. 待确认事项

| 编号 | 问题 | 影响范围 |
|------|------|---------|
| ~~Q-01~~ | ~~邮件发送服务商最终选型（SendGrid / AWS SES / 自建 SMTP）~~ **已确认：MVP 使用 SendGrid。实现上必须通过 `EmailSender` 接口抽象，infrastructure 层提供 `SendGridEmailSender` 实现，后续替换为 AWS SES 只需新增实现类并修改 DI 配置，不改动业务逻辑。** | EmailSender 的 infrastructure 实现 |
| ~~Q-02~~ | ~~管理员初始账号创建方式（迁移脚本直插 / 命令行工具 / 运营后台）~~ **已确认：管理员初始账号通过迁移脚本直接插入数据库，后续可通过运营后台添加。迁移脚本中的初始邮箱和密码通过环境变量注入，禁止硬编码。** | 初始化流程 |
| ~~Q-03~~ | ~~正式上线前切换为"邮箱唯一性"校验的具体时间节点~~ **已确认：通过配置开关控制邮箱唯一性校验。开关在应用配置中定义（如环境变量 `ALLOW_DUPLICATE_EMAIL=true`），默认为 true（允许重复，测试阶段）。正式上线后通过修改配置一键关闭重复注册。同时需要执行数据库迁移将 email 索引升级为唯一索引。具体切换时间节点暂不确定。** | 数据库迁移计划 |
| ~~Q-04~~ | ~~JWT RS256 密钥对的生成和分发流程~~ **已确认：JWT RS256 密钥对通过 `openssl genrsa` 生成，存入环境变量（`JWT_PRIVATE_KEY`、`JWT_PUBLIC_KEY`），各环境独立生成，不共享。** | 部署流程 |
| ~~Q-05~~ | ~~人机校验 MVP 阶段是否采用纯前端实现（如 react-slider-captcha）还是接入第三方服务~~ **已确认：MVP 阶段人机校验采用纯前端实现（如 react-slider-captcha），不接入第三方服务。仍通过 `HumanVerifier` 接口抽象，后续可替换为极验、reCAPTCHA 等。** | 人机校验模块技术选型 |
| ~~Q-06~~ | ~~开发环境的邮件模拟是否使用 MailHog~~ **已确认：开发环境使用 `ConsoleEmailSender` 实现，将验证码直接打印到控制台日志。需要测试邮件模板样式时，可临时启用 MailHog（通过 Docker Compose）。** | Docker Compose 配置 |

---

*本文档版本 v1.1，如有修改请更新版本号并记录变更原因。*
