#!/usr/bin/env bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "develop" ]; then
  echo "{\"feedback\": \"⚠️ Editing files on '$BRANCH'. Move to a claude/* branch first.\"}"
fi
