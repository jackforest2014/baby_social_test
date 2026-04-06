# {{subject}} — 数据分析规划

> **关联 PRD**：{{prd_doc_path}}
> **规划时间**：{{plan_date}}
> **规划者**：data-analyst Agent

---

## 目录

- [业务目标与指标映射](#业务目标与指标映射)
- [埋点方案](#埋点方案)
  - [事件命名规范](#事件命名规范)
  - [用户标识方案](#用户标识方案)
  - [埋点事件清单](#埋点事件清单)
- [指标体系](#指标体系)
  - [L1 业务指标](#l1-业务指标)
  - [L2 功能指标](#l2-功能指标)
  - [L3 技术指标](#l3-技术指标)
- [数据看板](#数据看板)
  - [产品看板](#产品看板)
  - [运营看板](#运营看板)
  - [技术看板](#技术看板)
- [技术实现建议](#技术实现建议)
  - [前端埋点实现](#前端埋点实现)
  - [后端埋点实现](#后端埋点实现)
  - [数据存储方案](#数据存储方案)
- [数据隐私合规](#数据隐私合规)
- [A/B 测试方案](#ab-测试方案)
- [实施优先级](#实施优先级)

---

## 业务目标与指标映射

| 业务目标 | 北极星指标 | 过程指标 | 健康指标 |
|----------|-----------|----------|----------|
| {{business_goal}} | {{north_star_metric}} | {{process_metrics}} | {{health_metrics}} |

```mermaid
graph TD
    Goal["{{business_goal}}"]
    Goal --> KPI1["{{kpi_1}}"]
    Goal --> KPI2["{{kpi_2}}"]
    KPI1 --> Event1["{{event_1}}"]
    KPI1 --> Event2["{{event_2}}"]
    KPI2 --> Event3["{{event_3}}"]
```

---

## 埋点方案

### 事件命名规范

- 格式：`{object}_{action}`
- object：操作对象（如 `page`、`button`、`form`、`message`）
- action：操作行为（如 `view`、`click`、`submit`、`send`）
- 全部小写，下划线分隔
- 示例：`page_view`、`login_button_click`、`message_send`

### 用户标识方案

| 标识类型 | 生成时机 | 存储位置 | 生命周期 |
|----------|---------|----------|----------|
| 匿名 ID（anonymous_id） | 首次访问 | {{storage}} | {{lifecycle}} |
| 用户 ID（user_id） | 注册/登录 | {{storage}} | {{lifecycle}} |
| 设备 ID（device_id） | 首次安装 | {{storage}} | {{lifecycle}} |
| 会话 ID（session_id） | 每次会话 | {{storage}} | {{lifecycle}} |

**ID 关联策略**：{{id_merge_strategy}}

### 埋点事件清单

#### {{module_name}} 模块

| 事件名 | 描述 | 触发时机 | 触发端 | 事件属性 | 关联页面/接口 |
|--------|------|----------|--------|----------|--------------|
| {{event_name}} | {{description}} | {{trigger}} | 前端 / 后端 | 见下方属性表 | {{related}} |

**`{{event_name}}` 事件属性**：

| 属性名 | 类型 | 必填 | 示例值 | 说明 |
|--------|------|------|--------|------|
| {{prop_name}} | {{type}} | 是/否 | {{example}} | {{description}} |

---

## 指标体系

### L1 业务指标

| 指标名称 | 英文标识 | 计算公式 | 统计口径 | 数据来源 | 刷新频率 |
|----------|---------|----------|----------|----------|----------|
| {{metric_name}} | {{metric_id}} | {{formula}} | {{caliber}} | {{source_events}} | {{refresh}} |

### L2 功能指标

| 指标名称 | 英文标识 | 计算公式 | 统计口径 | 数据来源 | 刷新频率 |
|----------|---------|----------|----------|----------|----------|
| {{metric_name}} | {{metric_id}} | {{formula}} | {{caliber}} | {{source_events}} | {{refresh}} |

### L3 技术指标

| 指标名称 | 英文标识 | 计算公式 | 统计口径 | 数据来源 | 刷新频率 |
|----------|---------|----------|----------|----------|----------|
| {{metric_name}} | {{metric_id}} | {{formula}} | {{caliber}} | {{source_events}} | {{refresh}} |

---

## 数据看板

### 产品看板

**目标受众**：产品经理
**刷新策略**：{{refresh_strategy}}

| 图表名称 | 图表类型 | 数据指标 | 维度 | 筛选条件 |
|----------|---------|----------|------|----------|
| {{chart_name}} | 折线图 / 漏斗图 / 数值卡片 / 表格 | {{metrics}} | {{dimensions}} | {{filters}} |

### 运营看板

**目标受众**：运营
**刷新策略**：{{refresh_strategy}}

| 图表名称 | 图表类型 | 数据指标 | 维度 | 筛选条件 |
|----------|---------|----------|------|----------|
| {{chart_name}} | {{chart_type}} | {{metrics}} | {{dimensions}} | {{filters}} |

### 技术看板

**目标受众**：开发 / SRE
**刷新策略**：{{refresh_strategy}}

| 图表名称 | 图表类型 | 数据指标 | 维度 | 筛选条件 |
|----------|---------|----------|------|----------|
| {{chart_name}} | {{chart_type}} | {{metrics}} | {{dimensions}} | {{filters}} |

---

## 技术实现建议

### 前端埋点实现

**推荐方案**：{{frontend_approach}}

**埋点植入方式**：
- 全局自动采集：{{auto_track_list}}
- 业务手动埋点：{{manual_track_approach}}

**上报策略**：
- 缓存方式：{{buffer_strategy}}
- 批量上报间隔：{{batch_interval}}
- 失败重试策略：{{retry_strategy}}

**代码示例**：
```typescript
// 埋点调用示例
{{frontend_code_example}}
```

### 后端埋点实现

**推荐方案**：{{backend_approach}}

**采集接口**：
- 路径：`POST /api/v1/analytics/events`
- 请求格式：
```json
{{event_api_request_format}}
```

**数据管道**：
```mermaid
graph LR
    Client["客户端"] --> API["采集接口"]
    API --> Queue["消息队列"]
    Queue --> Processor["数据处理"]
    Processor --> Storage["分析数据库"]
    Storage --> Dashboard["看板"]
```

### 数据存储方案

| 数据类型 | 存储方案 | 保留期限 | 预估数据量（日） |
|----------|---------|----------|----------------|
| 原始事件 | {{storage}} | {{retention}} | {{daily_volume}} |
| 聚合指标 | {{storage}} | {{retention}} | {{daily_volume}} |
| 用户画像 | {{storage}} | {{retention}} | {{daily_volume}} |

---

## 数据隐私合规

### 敏感数据分类

| 数据字段 | 敏感等级 | 采集方式 | 存储方式 | 合规要求 |
|----------|---------|----------|----------|----------|
| {{field}} | 高 / 中 / 低 | {{collection}} | 加密 / 脱敏 / 明文 | {{compliance}} |

### 合规检查清单

- [ ] 用户知情同意机制（隐私政策弹窗）
- [ ] 数据最小化采集原则
- [ ] 敏感数据加密存储
- [ ] 数据删除接口（Right to be Forgotten）
- [ ] 数据导出接口（Data Portability）
- [ ] 未成年人数据保护

---

## A/B 测试方案

| 实验名称 | 实验对象 | 分组策略 | 核心指标 | 显著性标准 | 最小样本量 |
|----------|---------|----------|----------|-----------|-----------|
| {{experiment}} | {{target}} | {{split}} | {{metric}} | {{significance}} | {{sample_size}} |

---

## 实施优先级

### P0 — MVP 必须（首版上线前完成）

{{p0_list}}

### P1 — 重要（上线后 1 个月内补齐）

{{p1_list}}

### P2 — 后续迭代

{{p2_list}}
