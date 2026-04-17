#!/usr/bin/env bash
# Injected as context when Claude starts a session
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
PENDING=$(grep -c '^\- \[ \]' TODO.md 2>/dev/null || echo "0")
IN_PROGRESS=$(grep -c '^\- \[~\]' TODO.md 2>/dev/null || echo "0")
REVIEWS=$(grep -c '^\- \[review\]' TODO.md 2>/dev/null || echo "0")

echo "=== Claude Code Session Context ==="
echo "Current branch  : $BRANCH"
echo "Pending tasks   : $PENDING"
echo "In progress     : $IN_PROGRESS"
echo "Review requests : $REVIEWS"
echo ""
echo "Context files   : vault/core/goal.md | vault/core/rules.md | TODO.md"
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "develop" ]; then
  echo "⚠️  WARNING: You are on '$BRANCH'. Create a claude/* branch before editing any code."
fi
