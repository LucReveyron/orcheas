#!/usr/bin/env bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

PROTECTED=(".env" ".env.local" ".env.production" ".env.staging" "package-lock.json" ".git/")
for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "{\"block\": true, \"message\": \"Blocked: '$FILE_PATH' is a protected file. Do not modify it.\"}"
    exit 0
  fi
done
