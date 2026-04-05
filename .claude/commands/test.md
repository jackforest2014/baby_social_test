---
description: 启动集成测试，验证模块间协作
---

请以 integration-tester agent 的角色，执行集成测试：

$ARGUMENTS

工作流程：
1. 读取 `docs/architecture/` 中的契约文档
2. 编写覆盖关键业务流程的集成测试用例
3. 运行测试并收集结果
4. 如有失败，分析根因并指出问题模块
5. 输出集成测试报告
