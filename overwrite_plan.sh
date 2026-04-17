#!/usr/bin/env bash
# =============================================================================
#  apply-overwrite.sh
#  Run this from the root of your local orcheas clone.
#  It rewrites all files with the new Claude Code workflow.
#
#  Usage:
#    cd /path/to/orcheas
#    bash apply-overwrite.sh
# =============================================================================

set -euo pipefail

# Safety check — make sure we're in the right repo
if [[ ! -f "install.sh" ]] || [[ ! -d "templates" ]]; then
  echo "❌  Run this from the root of your orcheas repo (install.sh and templates/ must exist)."
  exit 1
fi

echo ""
echo "🔄  Overwriting orcheas with new Claude Code workflow..."
echo "──────────────────────────────────────────────────────────"

# ── Create new directory structure ───────────────────────────────────────────
mkdir -p \
  templates/vault/core \
  templates/vault/active \
  templates/vault/memories \
  templates/claude/commands \
  templates/claude/agents \
  templates/claude/hooks \
  templates/claude/logs \
  tests

echo "✅  Directories ready"

# =============================================================================
#  install.sh  (updated — now also copies .claude/ template)
# =============================================================================
cat > install.sh <<'INSTALL'
#!/usr/bin/env bash
# install.sh — Installs orcheas globally. Does NOT touch ~/.claude.
#
# What it does:
#   1. Copies orcheas to ~/.local/share/orcheas
#   2. Adds an `orcheas` shell function to your shell rc file
#
# Usage: ./install.sh [--dry-run]

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/orcheas"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

if [[ -f "$HOME/.zshrc" ]]; then RC_FILE="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then RC_FILE="$HOME/.bashrc"
else RC_FILE="$HOME/.profile"
fi

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "  $*"; }
run() { if $DRY_RUN; then echo "  [dry-run] $*"; else eval "$*"; fi; }

[[ -d "$INSTALL_DIR" ]] && MODE="update" || MODE="install"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  orcheas $MODE"
$DRY_RUN && echo "  (dry-run mode — no changes will be made)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "▶  Installing to $INSTALL_DIR"
run "mkdir -p '$INSTALL_DIR'"
run "cp -r '$SOURCE_DIR/templates' '$INSTALL_DIR/'"
run "cp '$SOURCE_DIR/orcheas'      '$INSTALL_DIR/'"
run "cp '$SOURCE_DIR/CLAUDE.md'    '$INSTALL_DIR/'"
run "chmod +x '$INSTALL_DIR/orcheas'"
run "echo '$SOURCE_DIR' > '$INSTALL_DIR/.source'"
log "done"

echo ""
echo "▶  Adding shell function to $RC_FILE"
MARKER="# orcheas — Claude Code scaffolding"
SHELL_BLOCK="
$MARKER
orcheas() { bash \"\$HOME/.local/share/orcheas/orcheas\" \"\$@\"; }
"
if grep -qF "$MARKER" "$RC_FILE" 2>/dev/null; then
  log "already present in $RC_FILE — skipping"
else
  run "printf '%s\n' '$SHELL_BLOCK' >> '$RC_FILE'"
  log "done"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ $MODE complete."
echo ""
if [[ "$MODE" == "install" ]]; then
  echo "  source $RC_FILE"
  echo ""
  echo "  Then in any project:"
fi
echo "  orcheas init [path]     scaffold vault + .claude + CLAUDE.md"
echo "  orcheas clean <vault>   reset active/ and .claude/logs/"
echo "  orcheas update          pull latest from source repo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INSTALL
chmod +x install.sh
echo "✅  install.sh"

# =============================================================================
#  orcheas  (updated CLI — new scaffold logic)
# =============================================================================
cat > orcheas <<'ORCHEAS'
#!/usr/bin/env bash
# orcheas — Claude Code project scaffolding CLI
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MD_SRC="$SELF_DIR/CLAUDE.md"
TEMPLATES="$SELF_DIR/templates"

usage() {
  cat <<EOF
Usage: orcheas <command> [args]

Commands:
  init [path]     Scaffold vault + .claude/ + CLAUDE.md (default: current dir)
  clean <path>    Reset mutable state (active/, .claude/logs/) without touching core/
  update          Reinstall from source repo
  help            Show this message
EOF
}

cmd_init() {
  local TARGET="${1:-.}"
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"

  echo ""
  echo "🤖  orcheas init → $TARGET"
  echo "──────────────────────────────────────────────────────────"

  # ── vault structure ─────────────────────────────────────────────────────────
  for dir in vault/core vault/active vault/memories; do
    mkdir -p "$TARGET/$dir"
  done

  copy_if_missing() {
    local src="$1" dst="$2"
    if [[ ! -f "$dst" ]]; then
      cp "$src" "$dst"
      echo "  ✅  $dst"
    else
      echo "  ⏭   $dst (exists, skipped)"
    fi
  }

  copy_if_missing "$TEMPLATES/vault/core/goal.md"      "$TARGET/vault/core/goal.md"
  copy_if_missing "$TEMPLATES/vault/core/rules.md"     "$TARGET/vault/core/rules.md"
  copy_if_missing "$TEMPLATES/vault/core/routine.md"   "$TARGET/vault/core/routine.md"
  copy_if_missing "$TEMPLATES/vault/active/summary.md" "$TARGET/vault/active/summary.md"
  copy_if_missing "$TEMPLATES/vault/memories/log.md"   "$TARGET/vault/memories/log.md"

  # ── .claude structure ────────────────────────────────────────────────────────
  for dir in .claude/commands .claude/agents .claude/hooks .claude/logs; do
    mkdir -p "$TARGET/$dir"
  done

  copy_if_missing "$TEMPLATES/claude/settings.json"              "$TARGET/.claude/settings.json"
  copy_if_missing "$TEMPLATES/claude/.gitignore"                 "$TARGET/.claude/.gitignore"
  copy_if_missing "$TEMPLATES/claude/commands/task.md"           "$TARGET/.claude/commands/task.md"
  copy_if_missing "$TEMPLATES/claude/commands/done.md"           "$TARGET/.claude/commands/done.md"
  copy_if_missing "$TEMPLATES/claude/commands/log.md"            "$TARGET/.claude/commands/log.md"
  copy_if_missing "$TEMPLATES/claude/commands/review.md"         "$TARGET/.claude/commands/review.md"
  copy_if_missing "$TEMPLATES/claude/agents/code-reviewer.md"    "$TARGET/.claude/agents/code-reviewer.md"
  copy_if_missing "$TEMPLATES/claude/hooks/session-start.sh"     "$TARGET/.claude/hooks/session-start.sh"
  copy_if_missing "$TEMPLATES/claude/hooks/session-stop.sh"      "$TARGET/.claude/hooks/session-stop.sh"
  copy_if_missing "$TEMPLATES/claude/hooks/protect-files.sh"     "$TARGET/.claude/hooks/protect-files.sh"
  copy_if_missing "$TEMPLATES/claude/hooks/verify-branch.sh"     "$TARGET/.claude/hooks/verify-branch.sh"

  chmod +x "$TARGET/.claude/hooks/"*.sh

  # ── root files ──────────────────────────────────────────────────────────────
  copy_if_missing "$TEMPLATES/TODO.md" "$TARGET/TODO.md"

  # CLAUDE.md always overwrites (it's the protocol, not user content)
  cp "$CLAUDE_MD_SRC" "$TARGET/CLAUDE.md"
  echo "  ✅  $TARGET/CLAUDE.md (always refreshed)"

  # ── .gitignore additions ────────────────────────────────────────────────────
  local GI="$TARGET/.gitignore"
  if [[ ! -f "$GI" ]]; then touch "$GI"; fi
  if ! grep -q ".claude/settings.local.json" "$GI"; then
    printf '\n# Claude Code local settings\n.claude/settings.local.json\n' >> "$GI"
    echo "  ✅  .gitignore updated"
  fi

  echo ""
  echo "🎉  Done! Structure:"
  echo "    $TARGET/"
  echo "    ├── CLAUDE.md              ← agent rules & workflow (auto-refreshed)"
  echo "    ├── TODO.md                ← shared task list"
  echo "    ├── vault/"
  echo "    │   ├── core/              ← EDIT: goal.md, rules.md, routine.md"
  echo "    │   ├── active/summary.md  ← agent-maintained state"
  echo "    │   └── memories/log.md    ← agent append-only notes"
  echo "    └── .claude/"
  echo "        ├── settings.json      ← hooks (branch guard, file protect)"
  echo "        ├── commands/          ← /task  /done  /log  /review"
  echo "        ├── agents/            ← code-reviewer persona"
  echo "        ├── hooks/             ← session context, branch guard"
  echo "        └── logs/              ← per-feature decision logs (Claude writes here)"
  echo ""
  echo "  Next steps:"
  echo "  1. Edit vault/core/goal.md   — describe your project"
  echo "  2. Edit vault/core/rules.md  — add your hard constraints"
  echo "  3. Fill TODO.md              — add your first tasks"
  echo "  4. Open Claude Code in VSCode and type /task"
}

cmd_clean() {
  local VAULT="${1:-}"
  if [[ -z "$VAULT" ]]; then echo "Usage: orcheas clean <vault-path>"; exit 1; fi
  if [[ ! -d "$VAULT" ]]; then echo "❌  '$VAULT' not found."; exit 1; fi

  VAULT="$(cd "$VAULT" && pwd)"
  PROJECT_ROOT="$(dirname "$VAULT")"

  echo "🧹  Cleaning mutable state in $VAULT and $PROJECT_ROOT/.claude/logs/"

  # Reset vault/active/
  cp "$TEMPLATES/vault/active/summary.md" "$VAULT/active/summary.md"
  echo "  ✅  vault/active/summary.md reset"

  # Reset vault/memories/
  find "$VAULT/memories/" -name "*.md" -delete
  cp "$TEMPLATES/vault/memories/log.md" "$VAULT/memories/log.md"
  echo "  ✅  vault/memories/ reset"

  # Reset .claude/logs/
  if [[ -d "$PROJECT_ROOT/.claude/logs" ]]; then
    find "$PROJECT_ROOT/.claude/logs/" -name "*.md" -delete
    echo "  ✅  .claude/logs/ cleared"
  fi

  echo "  Core files untouched: vault/core/"
  echo "  Task list untouched : TODO.md"
}

cmd_update() {
  local SOURCE_FILE="$SELF_DIR/.source"
  local SOURCE_DIR="${ORCHEAS_SOURCE:-}"

  if [[ -z "$SOURCE_DIR" ]] && [[ -f "$SOURCE_FILE" ]]; then
    SOURCE_DIR="$(cat "$SOURCE_FILE")"
  fi

  if [[ -z "$SOURCE_DIR" ]] || [[ ! -d "$SOURCE_DIR" ]]; then
    echo "❌  Source repo not found. Run: ORCHEAS_SOURCE=/path/to/orcheas orcheas update"
    exit 1
  fi

  echo "🔄  Updating from $SOURCE_DIR"
  bash "$SOURCE_DIR/install.sh"
}

case "${1:-help}" in
  init)    cmd_init   "${2:-}" ;;
  clean)   cmd_clean  "${2:-}" ;;
  update)  cmd_update ;;
  help|--help|-h) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
ORCHEAS
chmod +x orcheas
echo "✅  orcheas (CLI)"

# =============================================================================
#  CLAUDE.md  (template — copied into every project)
# =============================================================================
cat > CLAUDE.md <<'CLAUDEMD'
# Claude Code — Rules & Workflow

> This file is the operating contract between you (Claude) and the human developer.
> It is loaded automatically at every session start. Follow it without exception.

---

## ⚡ Core Rules

- **Never push directly to `main` or `develop`.** Always work on a dedicated branch.
- **Branch naming:** `claude/<feature-slug>` (e.g. `claude/add-auth`, `claude/fix-login-bug`).
- **One branch per task.** Create a fresh branch when picking up any TODO item.
- **Write a decision log** in `.claude/logs/<feature-slug>.md` for every feature or significant update. Use `/log`.
- **Never commit secrets**, `.env` files, or credentials.
- **Tests first.** Write or update tests before or alongside the implementation.
- **Keep changes focused.** One TODO item = one branch = one PR.
- **Ask before large refactors.** If a task requires touching more than 3 unrelated files, confirm scope first.
- **Follow existing code style.** Match what you see; do not reformat unrelated code.
- **Read context files before starting.** Always check `vault/core/goal.md`, `vault/core/rules.md`, and `TODO.md`.

---

## 📂 Project Context Files

| File | Purpose | Who edits |
|------|---------|-----------|
| `vault/core/goal.md` | Project objective | Human |
| `vault/core/rules.md` | Hard project constraints | Human |
| `vault/core/routine.md` | Tone & working style preferences | Human |
| `vault/active/summary.md` | Current project state | Claude (maintain) |
| `vault/memories/log.md` | Append-only session notes | Claude (append) |
| `TODO.md` | Shared task list | Both |
| `.claude/logs/<slug>.md` | Per-feature decision logs | Claude (create) |

---

## 🔄 Workflow

```
TODO.md  →  /task <id>  →  claude/<slug> branch
                        →  read vault/core/ for context
                        →  implement + tests
                        →  /log  (write decision log)
                        →  /done (push + merge proposal)
                        →  human reviews & merges
```

## 📋 TODO Protocol

- Read `TODO.md` at the start of every session.
- Pick the highest-priority unclaimed task (status: `[ ]`).
- Mark it `[~]` (in progress) when you start.
- Mark it `[x]` (done) only **after** the merge proposal is submitted and acknowledged.
- Do NOT mark done before the human has reviewed.

## 🌿 Git Protocol

```bash
# Start a task
git checkout main && git pull origin main
git checkout -b claude/<feature-slug>

# During work — commit often with clear messages
git commit -m "feat(<scope>): <what and why>"

# Propose merge
git push origin claude/<feature-slug>
# Then output a /done merge proposal
```

## 🔍 Code Review Protocol

When the human adds a `[review]` item to `TODO.md`:
1. Run `/review <target>` to analyze the file or branch.
2. Save the report to `.claude/logs/review-<slug>-<date>.md`.
3. Mark the `[review]` item in `TODO.md` as `[x]`.

## 🗂 Decision Log

Every feature gets `.claude/logs/<feature-slug>.md` via `/log`. It must include:
- **What** was built/changed
- **Why** (the reasoning and trade-offs)
- **How** (key technical decisions)
- **Alternatives considered**

## 🔁 Session End

Before ending any session:
1. Commit all work-in-progress with a clear message.
2. Update `vault/active/summary.md` with current project state.
3. Append key decisions to `vault/memories/log.md`.
4. If a task is complete, run `/done`.
CLAUDEMD
echo "✅  CLAUDE.md"

# =============================================================================
#  README.md
# =============================================================================
cat > README.md <<'README'
# orcheas

Scaffolds Claude Code projects with a **vault** for project context and a
**`.claude/`** directory for hooks, slash commands, and decision logs.

---

## Install

```bash
git clone https://github.com/LucReveyron/orcheas
cd orcheas
./install.sh
source ~/.zshrc   # or ~/.bashrc
```

---

## Commands

### `orcheas init [path]`

Scaffolds everything into the target directory (default: current dir).

```
orcheas init my-project/
```

Creates:

```
my-project/
├── CLAUDE.md                      ← agent rules & workflow (auto-refreshed on init)
├── TODO.md                        ← shared task list (human + Claude)
├── vault/
│   ├── core/
│   │   ├── goal.md                ← EDIT: your project objective
│   │   ├── rules.md               ← EDIT: hard constraints for Claude
│   │   └── routine.md             ← EDIT: tone and working style
│   ├── active/
│   │   └── summary.md             ← Claude-maintained: current project state
│   └── memories/
│       └── log.md                 ← Claude-maintained: append-only session log
└── .claude/
    ├── settings.json              ← hooks (branch guard, file protection)
    ├── commands/
    │   ├── task.md                ← /task  — pick a TODO, create branch, start work
    │   ├── done.md                ← /done  — push branch, output merge proposal
    │   ├── log.md                 ← /log   — write per-feature decision log
    │   └── review.md              ← /review — structured code review
    ├── agents/
    │   └── code-reviewer.md       ← review agent persona
    ├── hooks/
    │   ├── session-start.sh       ← inject context (branch, todo count) on start
    │   ├── session-stop.sh        ← remind to commit & propose merge on stop
    │   ├── protect-files.sh       ← block writes to .env, package-lock, etc.
    │   └── verify-branch.sh       ← warn if editing directly on main
    └── logs/                      ← per-feature decision logs (Claude writes here)
```

Safe to re-run — skips files that already exist. `CLAUDE.md` is always refreshed.

---

### `orcheas clean <vault-path>`

Resets mutable state without touching `vault/core/` or `TODO.md`.

```bash
orcheas clean my-project/vault
```

Resets:
- `vault/active/summary.md`
- `vault/memories/*.md`
- `.claude/logs/*.md`

---

### `orcheas update`

Reinstalls from the source repo.

```bash
orcheas update
# If you moved the repo:
ORCHEAS_SOURCE=/new/path orcheas update
```

---

## Workflow

1. `orcheas init` in your project
2. Edit `vault/core/goal.md` — describe what you're building
3. Edit `vault/core/rules.md` — add your project-specific constraints
4. Add tasks to `TODO.md`
5. Open Claude Code in VSCode → type **`/task`**
6. Claude creates a `claude/<slug>` branch and starts working
7. When done, Claude runs **`/log`** (decision log) + **`/done`** (merge proposal)
8. You review the branch and merge when happy

### Code review by Claude

Add a review request to `TODO.md`:

```markdown
- [review] #R01 · Review auth middleware · target: src/middleware/auth.ts
```

Then tell Claude: `/review src/middleware/auth.ts`

---

## Slash commands reference

| Command | What it does |
|---------|-------------|
| `/task [id]` | Pick a TODO item, create `claude/<slug>` branch, start implementation |
| `/done` | Commit, push, output a formatted merge proposal |
| `/log` | Write `.claude/logs/<slug>.md` with why/how/alternatives |
| `/review <target>` | Structured code review saved to `.claude/logs/` |

---

## Requirements

| Dependency | Notes |
|------------|-------|
| `bash` ≥ 3.2 | macOS default |
| `git` | Required for branch workflow |
| `claude` CLI | [Claude Code](https://docs.anthropic.com/claude-code) |
README
echo "✅  README.md"

# =============================================================================
#  templates/vault/core/
# =============================================================================
cat > templates/vault/core/goal.md <<'EOF'
# Project Goal

<!-- EDIT THIS FILE: describe what you are building -->

## Objective

One clear sentence describing the product/system.

## Key outcomes

- Outcome 1
- Outcome 2

## Out of scope

- Things Claude should NOT build without explicit ask
EOF

cat > templates/vault/core/rules.md <<'EOF'
# Project Rules

<!-- EDIT THIS FILE: hard constraints Claude must always follow -->

## Tech stack

- Language: <!-- e.g. TypeScript -->
- Framework: <!-- e.g. Next.js -->
- Database: <!-- e.g. PostgreSQL -->
- Package manager: <!-- e.g. pnpm -->

## Coding constraints

- [ ] All public functions must have JSDoc/docstring
- [ ] No `any` types (TypeScript)
- [ ] All API routes require authentication unless explicitly noted
- [ ] Add rule...

## Forbidden actions

- Never delete migration files
- Never modify files in `src/generated/`
- Add rule...
EOF

cat > templates/vault/core/routine.md <<'EOF'
# Agent Routine & Style

<!-- EDIT THIS FILE: define how you want Claude to work -->

## Communication style

- Be concise in commit messages
- Ask before making assumptions on ambiguous requirements
- Prefer explicit over implicit

## Code style

- Prefer small, focused functions
- Descriptive variable names over abbreviations
- Comments for "why", not "what"

## Workflow preferences

- Commit frequently with meaningful messages
- Write tests alongside implementation (not after)
- Update TODO.md status as you go
EOF

echo "✅  templates/vault/core/"

# =============================================================================
#  templates/vault/active/ & memories/
# =============================================================================
cat > templates/vault/active/summary.md <<'EOF'
# Project Summary

<!-- Claude maintains this file. Updated at the end of each session. -->

**Last updated:** —
**Current branch:** —
**Active task:** —

## Current state

<!-- What has been built so far -->

## Next up

<!-- What's coming next -->

## Blockers

<!-- Anything waiting on the human -->
EOF

cat > templates/vault/memories/log.md <<'EOF'
# Session Log

<!-- Claude appends to this file. Do not delete entries. -->
<!-- Format: ## YYYY-MM-DD — <branch> — <summary> -->

EOF

echo "✅  templates/vault/active/ & memories/"

# =============================================================================
#  templates/TODO.md
# =============================================================================
cat > templates/TODO.md <<'EOF'
# TODO — Shared Task List

> **Status legend:**
> `[ ]` = pending · `[~]` = in progress (Claude) · `[x]` = done · `[review]` = code review requested

---

## 🔥 High Priority

- [ ] #001 · **Example task** — Replace with your first real task
  - _Branch:_ `claude/example-task`
  - _Notes:_ Add context, links, or constraints here

## 🟡 Normal Priority

<!-- Add tasks here -->

## 🧊 Backlog

<!-- Add tasks here -->

---

## ✅ Completed

<!-- Claude moves finished items here after merge is proposed -->

---

## 🔍 Review Requests

> Add items here when you want Claude to review your code.
> Format: `[review] #<id> · <description> · target: <file-or-branch>`

<!-- Example:
- [review] #R01 · Review auth middleware · target: src/middleware/auth.ts
-->
EOF

echo "✅  templates/TODO.md"

# =============================================================================
#  templates/claude/settings.json
# =============================================================================
cat > templates/claude/settings.json <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/protect-files.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/verify-branch.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-stop.sh"
          }
        ]
      }
    ]
  },
  "permissions": {
    "deny": [
      "Bash(git push * main)",
      "Bash(git push * develop)",
      "Bash(rm -rf *)"
    ]
  }
}
EOF

cat > templates/claude/.gitignore <<'EOF'
settings.local.json
EOF

echo "✅  templates/claude/settings.json"

# =============================================================================
#  templates/claude/hooks/
# =============================================================================
cat > templates/claude/hooks/session-start.sh <<'EOF'
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
EOF

cat > templates/claude/hooks/session-stop.sh <<'EOF'
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
EOF

cat > templates/claude/hooks/protect-files.sh <<'EOF'
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
EOF

cat > templates/claude/hooks/verify-branch.sh <<'EOF'
#!/usr/bin/env bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "develop" ]; then
  echo "{\"feedback\": \"⚠️ Editing files on '$BRANCH'. Move to a claude/* branch first.\"}"
fi
EOF

chmod +x \
  templates/claude/hooks/session-start.sh \
  templates/claude/hooks/session-stop.sh \
  templates/claude/hooks/protect-files.sh \
  templates/claude/hooks/verify-branch.sh

echo "✅  templates/claude/hooks/"

# =============================================================================
#  templates/claude/commands/
# =============================================================================
cat > templates/claude/commands/task.md <<'EOF'
# /task

Pick up a task from TODO.md and start working on it.

## Steps

1. Read `vault/core/goal.md`, `vault/core/rules.md`, and `vault/core/routine.md` for project context.
2. Read `TODO.md` and identify the highest-priority pending task (`[ ]`).
   - If an ID is provided as argument (e.g. `/task 003`), use that task instead.
3. Extract a slug from the task description (lowercase, hyphenated, 3-5 words).
4. Create the branch:
   ```bash
   git checkout main && git pull origin main
   git checkout -b claude/<slug>
   ```
5. Update `TODO.md`: change `[ ]` → `[~]` for that task.
6. Commit:
   ```bash
   git add TODO.md && git commit -m "chore: start task #<id> [claude]"
   ```
7. Announce the task and branch, then begin implementation.
8. When done: run `/log` then `/done`.
EOF

cat > templates/claude/commands/done.md <<'EOF'
# /done

Finalize the current task and propose a merge.

## Steps

1. Ensure all changes are committed:
   ```bash
   git add -A && git commit -m "feat(<scope>): <summary>"
   ```
2. Confirm `.claude/logs/<feature-slug>.md` exists. If not, run `/log` first.
3. Update `vault/active/summary.md` with current project state.
4. Append a session entry to `vault/memories/log.md`.
5. Push:
   ```bash
   git push origin claude/<current-branch>
   ```
6. Update `TODO.md`: change `[~]` → `[x]`.
7. Commit and push the TODO update.
8. Output a merge proposal:

---
## 🔀 Merge Proposal

- **Branch:** `claude/<slug>` → `main`
- **Task:** #<id> — <title>
- **Summary:** <what was built>
- **Files changed:** <list>
- **Decision log:** `.claude/logs/<slug>.md`
- **Tests:** <pass / fail / n/a>
- **Ready for review:** ✅

> Please review and merge when ready.
---
EOF

cat > templates/claude/commands/log.md <<'EOF'
# /log

Write a decision log for the current feature.

## Steps

1. Determine the slug from the current branch (strip `claude/` prefix).
2. Create `.claude/logs/<slug>.md` using the template below.
3. Commit:
   ```bash
   git add .claude/logs/<slug>.md
   git commit -m "docs: add decision log for <slug> [claude]"
   ```

## Template

```markdown
# Decision Log — <slug>

**Date:** <YYYY-MM-DD>
**Branch:** `claude/<slug>`
**Task ref:** #<id>

---

## What

<Describe what was built or changed.>

## Why

<Explain the reason. What problem does it solve?>

## How

<Key technical approach.>

### Decisions

| Decision | Chosen | Reason |
|----------|--------|--------|
| <topic>  | <choice> | <why> |

## Alternatives considered

- **<Alt 1>:** <why rejected>
- **<Alt 2>:** <why rejected>

## Impact & risks

- <Side effects, performance, known limitations>

## Follow-up

- [ ] <Anything left to do>
```
EOF

cat > templates/claude/commands/review.md <<'EOF'
# /review

Perform a structured code review on the specified target.

## Usage

```
/review <file-or-branch>
```

If no argument, check `TODO.md` for `[review]` items and review the first one.

## Steps

1. Identify the target.
2. If branch: `git diff main...<branch>`
3. If file: read full content.
4. Produce a review report (template below).
5. Save to `.claude/logs/review-<slug>-<YYYY-MM-DD>.md`.
6. Mark the `[review]` item in `TODO.md` as `[x]`.

## Review Report Template

```markdown
# Code Review — <target>

**Date:** <YYYY-MM-DD>
**Reviewer:** Claude
**Target:** <file or branch>

---

## Summary

<2-3 sentence overall assessment.>

## ✅ Strengths

- <what is done well>

## ⚠️ Issues

| Severity | File | Line | Description | Suggestion |
|----------|------|------|-------------|------------|
| 🔴 High  |      |      |             |            |
| 🟡 Med   |      |      |             |            |
| 🟢 Low   |      |      |             |            |

## 💡 Suggestions (non-blocking)

- <style, naming, architecture ideas>

## Security Checklist

- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] Errors handled safely (no stack traces exposed)

## Verdict

- [ ] ✅ Approve
- [ ] 🔄 Approve with minor changes
- [ ] ❌ Changes required
```
EOF

echo "✅  templates/claude/commands/"

# =============================================================================
#  templates/claude/agents/
# =============================================================================
cat > templates/claude/agents/code-reviewer.md <<'EOF'
# Agent: Code Reviewer

You are a senior software engineer performing structured code reviews.
You are thorough, constructive, and precise. You do not nitpick style
unless it impacts readability or maintainability.

## Responsibilities

- Identify bugs, logic errors, and edge cases
- Flag security issues (injection, secrets, auth bypass, etc.)
- Check error handling and resilience
- Evaluate test coverage
- Note architectural concerns without over-engineering
- Praise what is done well — balanced feedback is more useful

## Output

Follow the Review Report Template in `.claude/commands/review.md`.
Save the report to `.claude/logs/review-<slug>-<date>.md`.

## Tone

Professional, specific, actionable. Every issue should come with a suggestion.
The goal is to improve the code, not to criticize the author.
EOF

echo "✅  templates/claude/agents/"

# =============================================================================
#  .gitignore
# =============================================================================
cat > .gitignore <<'EOF'
# orcheas personal/local files
templates/claude/logs/

# OS
.DS_Store
Thumbs.db
EOF

echo "✅  .gitignore"

# =============================================================================
#  Summary
# =============================================================================
echo ""
echo "──────────────────────────────────────────────────────────"
echo "🎉  Overwrite complete! Files updated:"
echo ""
echo "  Modified:"
echo "    install.sh       — now also copies .claude/ template"
echo "    orcheas          — new init/clean logic for .claude/"
echo "    CLAUDE.md        — full workflow: branches, logs, slash commands"
echo "    README.md        — updated docs"
echo "    .gitignore"
echo ""
echo "  New templates:"
echo "    templates/claude/settings.json"
echo "    templates/claude/commands/{task,done,log,review}.md"
echo "    templates/claude/agents/code-reviewer.md"
echo "    templates/claude/hooks/{session-start,session-stop,protect-files,verify-branch}.sh"
echo "    templates/TODO.md"
echo "    templates/vault/* (refreshed)"
echo ""
echo "  Next: commit everything and push to GitHub"
echo "    git add -A"
echo "    git commit -m 'feat: overhaul with full Claude Code workflow'"
echo "    git push"
