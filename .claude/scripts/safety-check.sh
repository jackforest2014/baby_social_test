#!/usr/bin/env bash
# 安全检查钩子：在执行 Bash 工具前检测危险操作
# 通过 stdin 接收 JSON 格式的工具调用信息

set -euo pipefail

# 读取 stdin 中的工具调用信息
INPUT=$(cat)

# 提取命令内容
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('command', ''))
" 2>/dev/null || echo "")

if [ -z "$COMMAND" ]; then
  exit 0
fi

# 危险模式列表
DANGEROUS_PATTERNS=(
  # 文件系统破坏
  'rm\s+-rf\s+/'
  'rm\s+-rf\s+\*'
  'rm\s+-rf\s+\.'
  'rm\s+-fr\s+/'
  'rmdir\s+/'
  'find\s+.*-delete'
  'find\s+.*-exec\s+rm'
  # 数据库破坏
  'DROP\s+DATABASE'
  'DROP\s+SCHEMA.*CASCADE'
  'DROP\s+TABLE.*CASCADE'
  'TRUNCATE\s+'
  'DELETE\s+FROM\s+\w+\s*;'
  'DELETE\s+FROM\s+\w+\s+WHERE\s+1\s*=\s*1'
  'DELETE\s+FROM\s+\w+\s+WHERE\s+true'
  # 磁盘/系统破坏
  'mkfs\.'
  'dd\s+if='
  ':>\s+/'
  '>\s+/dev/'
  # Git 危险操作
  'git\s+push.*--force\s+.*main'
  'git\s+push.*--force\s+.*master'
  'git\s+push\s+-f\s+.*main'
  'git\s+push\s+-f\s+.*master'
  # Docker 破坏
  'docker\s+system\s+prune\s+-a'
  'docker\s+rm\s+-f\s+\$\(docker\s+ps'
  'docker\s+rmi\s+-f\s+\$\(docker\s+images'
  # 环境变量/凭证泄露
  'curl.*\$\{?GITHUB_TOKEN'
  'curl.*\$\{?AWS_SECRET'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -iEq "$pattern"; then
    echo "🚫 安全检查未通过：检测到危险操作" >&2
    echo "匹配的危险模式: $pattern" >&2
    echo "被拦截的命令: $COMMAND" >&2
    exit 2
  fi
done

exit 0
