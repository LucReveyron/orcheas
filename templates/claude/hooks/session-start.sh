#!/usr/bin/env bash
# Injected as context when Claude starts a session.
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
DIR=$(pwd)
PENDING=$(grep -c '^\- \[ \]' TODO.md 2>/dev/null || echo "0")
IN_PROGRESS=$(grep -c '^\- \[~\]' TODO.md 2>/dev/null || echo "0")
REVIEWS=$(grep -c '^\- \[review\]' TODO.md 2>/dev/null || echo "0")

echo "=== Claude Code Session Context ==="
echo "Directory       : $DIR"
echo "Current branch  : $BRANCH"
echo "Pending tasks   : $PENDING"
echo "In progress     : $IN_PROGRESS"
echo "Review requests : $REVIEWS"
echo ""

# Worktree check — directory should end in -claude
if [[ "$DIR" != *-claude ]]; then
  echo "⛔  WARNING: You do not appear to be in the Claude worktree."
  echo "    Expected a directory ending in '-claude'."
  echo "    Current path: $DIR"
  echo ""
  echo "    STOP. Tell the human to run: orcheas workspace"
  echo "    Do not edit any files until you are in the correct directory."
else
  echo "✅  Worktree confirmed: $(basename "$DIR")"
fi

# Branch check
if [[ "$BRANCH" != claude/* ]] && [[ "$BRANCH" != "workspace" ]]; then
  echo "⚠️   Branch '$BRANCH' is not a claude/* branch."
  echo "    Run /task to create a proper task branch before editing."
fi

echo ""
echo "Context files: vault/core/goal.md | vault/core/rules.md | TODO.md"
