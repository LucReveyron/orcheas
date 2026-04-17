#!/usr/bin/env bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
DIR=$(pwd)

# Hard block if not in worktree
if [[ "$DIR" != *-claude ]]; then
  echo "{\"block\": true, \"message\": \"⛔ You are not in the Claude worktree (path should end in -claude). Stop editing. Tell the human to run: orcheas workspace\"}"
  exit 0
fi

# Soft warn if on wrong branch
if [[ "$BRANCH" != "claude/"* ]]; then
  echo "{\"feedback\": \"⚠️ Branch '$BRANCH' is not a claude/* branch. Use /task to start a proper task branch.\"}"
fi
