#!/usr/bin/env bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [ "$UNCOMMITTED" -gt "0" ]; then
  echo "⚠️  $UNCOMMITTED uncommitted change(s) on '$BRANCH'. Commit or stash before ending."
fi

if [[ "$BRANCH" == claude/* ]]; then
  echo "ℹ️  On branch '$BRANCH'. If the task is complete, run /done to propose a merge."
fi

echo "📝  Remember to update vault/active/summary.md and append to vault/memories/log.md."
