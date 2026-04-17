#!/usr/bin/env bash
# =============================================================================
#  apply-worktree-update.sh
#  Applies on top of apply-overwrite.sh.
#  Adds git worktree support to orcheas.
#
#  Run from the root of your orcheas clone:
#    bash apply-worktree-update.sh
# =============================================================================

set -euo pipefail

if [[ ! -f "orcheas" ]] || [[ ! -d "templates/claude" ]]; then
  echo "❌  Run from the root of your orcheas repo (after apply-overwrite.sh)."
  exit 1
fi

echo ""
echo "🌿  Adding worktree support to orcheas..."
echo "──────────────────────────────────────────────────────────"

# =============================================================================
#  orcheas CLI  — replace entirely with worktree-aware version
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
  init [path]               Scaffold vault + .claude/ + CLAUDE.md
  workspace [branch]        Create a git worktree for Claude at ../[project]-claude
  workspace remove          Remove Claude's worktree (keeps branch by default)
  workspace remove --drop   Remove worktree AND delete the branch
  clean <vault-path>        Reset mutable state (active/, .claude/logs/)
  update                    Reinstall from source repo
  help                      Show this message
EOF
}

# ── helpers ───────────────────────────────────────────────────────────────────
worktree_path() {
  # Returns the canonical worktree path: ../[project-name]-claude
  local PROJECT_NAME
  PROJECT_NAME="$(basename "$(pwd)")"
  echo "$(dirname "$(pwd)")/${PROJECT_NAME}-claude"
}

current_claude_branch() {
  # Returns the most recent claude/* branch, or empty string
  git branch --list "claude/*" --sort=-creatordate | head -1 | sed 's/^[* ]*//'
}

# ── init ─────────────────────────────────────────────────────────────────────
cmd_init() {
  local TARGET="${1:-.}"
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"

  echo ""
  echo "🤖  orcheas init → $TARGET"
  echo "──────────────────────────────────────────────────────────"

  for dir in vault/core vault/active vault/memories; do
    mkdir -p "$TARGET/$dir"
  done
  for dir in .claude/commands .claude/agents .claude/hooks .claude/logs; do
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

  copy_if_missing "$TEMPLATES/vault/core/goal.md"                "$TARGET/vault/core/goal.md"
  copy_if_missing "$TEMPLATES/vault/core/rules.md"               "$TARGET/vault/core/rules.md"
  copy_if_missing "$TEMPLATES/vault/core/routine.md"             "$TARGET/vault/core/routine.md"
  copy_if_missing "$TEMPLATES/vault/active/summary.md"           "$TARGET/vault/active/summary.md"
  copy_if_missing "$TEMPLATES/vault/memories/log.md"             "$TARGET/vault/memories/log.md"
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
  copy_if_missing "$TEMPLATES/TODO.md"                           "$TARGET/TODO.md"

  chmod +x "$TARGET/.claude/hooks/"*.sh

  cp "$CLAUDE_MD_SRC" "$TARGET/CLAUDE.md"
  echo "  ✅  $TARGET/CLAUDE.md (always refreshed)"

  local GI="$TARGET/.gitignore"
  [[ ! -f "$GI" ]] && touch "$GI"
  if ! grep -q ".claude/settings.local.json" "$GI"; then
    printf '\n# Claude Code local settings\n.claude/settings.local.json\n' >> "$GI"
  fi

  echo ""
  echo "🎉  Done! Next steps:"
  echo "  1. Edit vault/core/goal.md and vault/core/rules.md"
  echo "  2. Add tasks to TODO.md"
  echo "  3. Run: orcheas workspace   ← creates Claude's isolated worktree"
  echo "  4. Open the worktree folder in VSCode and launch Claude Code"
}

# ── workspace ─────────────────────────────────────────────────────────────────
cmd_workspace() {
  local SUBCOMMAND="${1:-}"

  # ── workspace remove ────────────────────────────────────────────────────────
  if [[ "$SUBCOMMAND" == "remove" ]]; then
    local DROP_BRANCH=false
    [[ "${2:-}" == "--drop" ]] && DROP_BRANCH=true

    local WT_PATH
    WT_PATH="$(worktree_path)"

    if [[ ! -d "$WT_PATH" ]]; then
      echo "❌  Worktree not found at $WT_PATH"
      exit 1
    fi

    # Identify the branch the worktree is on
    local WT_BRANCH
    WT_BRANCH="$(git -C "$WT_PATH" branch --show-current 2>/dev/null || echo "")"

    echo "🗑   Removing worktree: $WT_PATH"
    git worktree remove "$WT_PATH" --force
    echo "  ✅  Worktree removed"

    if $DROP_BRANCH && [[ -n "$WT_BRANCH" ]] && [[ "$WT_BRANCH" == claude/* ]]; then
      git branch -d "$WT_BRANCH" 2>/dev/null || git branch -D "$WT_BRANCH"
      echo "  ✅  Branch '$WT_BRANCH' deleted"
    else
      echo "  ℹ️   Branch '${WT_BRANCH:-unknown}' kept — merge or delete it manually"
    fi
    return
  fi

  # ── workspace create ────────────────────────────────────────────────────────
  local WT_PATH
  WT_PATH="$(worktree_path)"

  if [[ -d "$WT_PATH" ]]; then
    echo "⚠️   Worktree already exists at $WT_PATH"
    echo "     Open it in VSCode or run: orcheas workspace remove"
    exit 0
  fi

  # Determine which branch to use
  local BRANCH="${SUBCOMMAND:-}"

  if [[ -z "$BRANCH" ]]; then
    # Try to reuse the most recent claude/* branch, else prompt
    local EXISTING
    EXISTING="$(current_claude_branch)"
    if [[ -n "$EXISTING" ]]; then
      BRANCH="$EXISTING"
      echo "  ℹ️   Reusing existing branch: $BRANCH"
    else
      echo "  ℹ️   No claude/* branch found. Creating a placeholder branch."
      echo "      (Use /task inside the worktree to create a proper task branch)"
      BRANCH="claude/workspace"
    fi
  fi

  # Normalise: add claude/ prefix if missing
  if [[ "$BRANCH" != claude/* ]]; then
    BRANCH="claude/$BRANCH"
  fi

  echo ""
  echo "🌿  Creating Claude worktree"
  echo "    Path  : $WT_PATH"
  echo "    Branch: $BRANCH"
  echo ""

  # Create branch if it doesn't exist
  if ! git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
    git branch "$BRANCH" main 2>/dev/null || git branch "$BRANCH" HEAD
    echo "  ✅  Branch '$BRANCH' created from main"
  fi

  git worktree add "$WT_PATH" "$BRANCH"
  echo "  ✅  Worktree created"

  # Copy .claude/ into the worktree if it exists in the main tree
  # (worktrees share .git but NOT the working files)
  if [[ -d ".claude" ]] && [[ ! -d "$WT_PATH/.claude" ]]; then
    cp -r ".claude" "$WT_PATH/.claude"
    echo "  ✅  .claude/ copied into worktree"
  fi

  echo ""
  echo "──────────────────────────────────────────────────────────"
  echo "🎉  Worktree ready!"
  echo ""
  echo "  Your directory : $(pwd)           (your code, your branch)"
  echo "  Claude's dir   : $WT_PATH   (Claude works here only)"
  echo ""
  echo "  Open Claude's workspace in VSCode:"
  echo "    code $WT_PATH"
  echo ""
  echo "  Inside Claude Code, start a task with /task"
  echo "  When Claude proposes a merge, review with:"
  echo "    git diff main...$BRANCH"
  echo "    git merge $BRANCH   (after approval)"
  echo ""
  echo "  To tear down after merging:"
  echo "    orcheas workspace remove"
}

# ── clean ─────────────────────────────────────────────────────────────────────
cmd_clean() {
  local VAULT="${1:-}"
  if [[ -z "$VAULT" ]]; then echo "Usage: orcheas clean <vault-path>"; exit 1; fi
  if [[ ! -d "$VAULT" ]]; then echo "❌  '$VAULT' not found."; exit 1; fi

  VAULT="$(cd "$VAULT" && pwd)"
  PROJECT_ROOT="$(dirname "$VAULT")"

  echo "🧹  Cleaning mutable state in $VAULT"

  cp "$TEMPLATES/vault/active/summary.md" "$VAULT/active/summary.md"
  echo "  ✅  vault/active/summary.md reset"

  find "$VAULT/memories/" -name "*.md" -delete
  cp "$TEMPLATES/vault/memories/log.md" "$VAULT/memories/log.md"
  echo "  ✅  vault/memories/ reset"

  if [[ -d "$PROJECT_ROOT/.claude/logs" ]]; then
    find "$PROJECT_ROOT/.claude/logs/" -name "*.md" -delete
    echo "  ✅  .claude/logs/ cleared"
  fi

  echo "  Core files untouched : vault/core/"
  echo "  Task list untouched  : TODO.md"
}

# ── update ────────────────────────────────────────────────────────────────────
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

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-help}" in
  init)
    cmd_init "${2:-}"
    ;;
  workspace)
    # Handle: orcheas workspace | orcheas workspace <branch> | orcheas workspace remove [--drop]
    shift
    cmd_workspace "${@:-}"
    ;;
  clean)
    cmd_clean "${2:-}"
    ;;
  update)
    cmd_update
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "Unknown command: $1"
    usage
    exit 1
    ;;
esac
ORCHEAS
chmod +x orcheas
echo "✅  orcheas (CLI — workspace commands added)"

# =============================================================================
#  CLAUDE.md  — add Worktree Protocol section
# =============================================================================
cat > CLAUDE.md <<'CLAUDEMD'
# Claude Code — Rules & Workflow

> This file is the operating contract between you (Claude) and the human developer.
> It is loaded automatically at every session start. Follow it without exception.

---

## ⚡ Core Rules

- **You work in the worktree only.** Your directory ends in `-claude`. Never operate in the human's main directory.
- **Never push directly to `main` or `develop`.** Always work on a dedicated branch.
- **Branch naming:** `claude/<feature-slug>` (e.g. `claude/add-auth`, `claude/fix-login-bug`).
- **One branch per task.** Create a fresh branch when picking up any TODO item.
- **Write a decision log** in `.claude/logs/<feature-slug>.md` for every feature or significant update.
- **Never commit secrets**, `.env` files, or credentials.
- **Tests first.** Write or update tests before or alongside the implementation.
- **Keep changes focused.** One TODO item = one branch = one PR.
- **Ask before large refactors.** If a task requires touching more than 3 unrelated files, confirm scope first.
- **Follow existing code style.** Do not reformat unrelated code.
- **Read context files before starting.** Always check `vault/core/goal.md`, `vault/core/rules.md`, and `TODO.md`.

---

## 🌿 Worktree Protocol

You are operating in a **git worktree** — a separate filesystem directory that shares
the same `.git` database as the human's main directory, but on a different branch.

```
~/projects/my-project/           ← human's directory (main or their branch)
~/projects/my-project-claude/    ← YOUR directory   (claude/* branch)
```

**Rules:**
- All your edits happen here, in the `-claude` worktree directory.
- The human's directory is untouched until they explicitly merge your branch.
- Shared files (`TODO.md`, `vault/`) are synced through git — commit your changes to make them visible to the human.
- When you finish a task, run `/done` to push and propose the merge. The human reviews and merges from their directory.

**Verify you are in the right place at session start:**
```bash
pwd   # should end in -claude
git branch --show-current  # should be claude/*
```

If you are NOT in the worktree, stop and tell the human before touching any file.

---

## 📂 Project Context Files

| File | Purpose | Who edits |
|------|---------|-----------|
| `vault/core/goal.md` | Project objective | Human |
| `vault/core/rules.md` | Hard project constraints | Human |
| `vault/core/routine.md` | Tone & working style | Human |
| `vault/active/summary.md` | Current project state | Claude (maintain) |
| `vault/memories/log.md` | Append-only session notes | Claude (append) |
| `TODO.md` | Shared task list | Both |
| `.claude/logs/<slug>.md` | Per-feature decision logs | Claude (create) |

---

## 🔄 Workflow

```
orcheas workspace          ← human creates your worktree
     ↓
code [project]-claude/     ← human opens YOUR directory in VSCode
     ↓
/task <id>                 ← you pick a task, branch is already set
     ↓
implement + tests
     ↓
/log                       ← write decision log
     ↓
/done                      ← push + merge proposal
     ↓
human reviews diff and merges from their directory
     ↓
orcheas workspace remove   ← human tears down worktree after merge
```

## 📋 TODO Protocol

- Read `TODO.md` at the start of every session.
- Pick the highest-priority unclaimed task (`[ ]`).
- Mark it `[~]` when you start.
- Mark it `[x]` only after the merge proposal is submitted and acknowledged.

## 🌿 Git Protocol

```bash
# Inside your worktree — the branch is already set by orcheas workspace
# Just start working and commit often:
git commit -m "feat(<scope>): <what and why>"

# When done, push from the worktree
git push origin claude/<slug>
```

**Never run `git checkout` to switch branches in the worktree.**
If you need a different branch, tell the human — they will run `orcheas workspace remove`
and `orcheas workspace <new-branch>`.

## 🔍 Code Review Protocol

When the human adds a `[review]` item to `TODO.md`:
1. Run `/review <target>` to analyze the file or branch.
2. Save the report to `.claude/logs/review-<slug>-<date>.md`.
3. Mark the `[review]` item in `TODO.md` as `[x]`.

## 🗂 Decision Log

Every feature gets `.claude/logs/<feature-slug>.md` via `/log`. It must include:
**What** · **Why** · **How** · **Alternatives considered**

## 🔁 Session End

1. Commit all work-in-progress with a clear message.
2. Update `vault/active/summary.md`.
3. Append key decisions to `vault/memories/log.md`.
4. If a task is complete, run `/done`.
CLAUDEMD
echo "✅  CLAUDE.md (worktree protocol added)"

# =============================================================================
#  templates/claude/hooks/session-start.sh  — worktree detection
# =============================================================================
cat > templates/claude/hooks/session-start.sh <<'EOF'
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
EOF
chmod +x templates/claude/hooks/session-start.sh
echo "✅  templates/claude/hooks/session-start.sh (worktree detection)"

# =============================================================================
#  templates/claude/hooks/verify-branch.sh  — worktree-aware
# =============================================================================
cat > templates/claude/hooks/verify-branch.sh <<'EOF'
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
EOF
chmod +x templates/claude/hooks/verify-branch.sh
echo "✅  templates/claude/hooks/verify-branch.sh (worktree-aware)"

# =============================================================================
#  templates/claude/commands/task.md  — worktree-aware
# =============================================================================
cat > templates/claude/commands/task.md <<'EOF'
# /task

Pick up a task from TODO.md and start working on it.

## Pre-flight check

Before anything, verify you are in the correct environment:

```bash
pwd              # must end in -claude
git branch --show-current  # should be claude/* or workspace
```

If `pwd` does NOT end in `-claude`, stop immediately and tell the human:
> "I am not in the worktree. Please run `orcheas workspace` first."

## Steps

1. Read `vault/core/goal.md`, `vault/core/rules.md`, and `vault/core/routine.md`.
2. Read `TODO.md` — find the highest-priority pending task (`[ ]`).
   - If an ID is given as argument (e.g. `/task 003`), use that task instead.
3. Extract a slug from the task description (lowercase, hyphenated, 3-5 words).
4. Create a task branch from current HEAD:
   ```bash
   git checkout -b claude/<slug>
   ```
   _(No need to pull from main — the worktree was created from main by orcheas.)_
5. Update `TODO.md`: change `[ ]` → `[~]` for that task.
6. Commit:
   ```bash
   git add TODO.md && git commit -m "chore: start task #<id> [claude]"
   ```
7. Announce the task and branch name, then begin implementation.
8. When done: run `/log` then `/done`.
EOF
echo "✅  templates/claude/commands/task.md"

# =============================================================================
#  templates/claude/commands/done.md  — worktree-aware
# =============================================================================
cat > templates/claude/commands/done.md <<'EOF'
# /done

Finalize the current task and propose a merge.

## Steps

1. Verify you are in the worktree (`pwd` must end in `-claude`).
2. Ensure all changes are committed:
   ```bash
   git add -A && git commit -m "feat(<scope>): <summary>"
   ```
3. Confirm `.claude/logs/<feature-slug>.md` exists. If not, run `/log` first.
4. Update `vault/active/summary.md` with current project state.
5. Append a session entry to `vault/memories/log.md`.
6. Push the branch:
   ```bash
   git push origin claude/<current-branch>
   ```
7. Update `TODO.md`: change `[~]` → `[x]`. Commit and push.
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

> Human: to review run `git diff main...claude/<slug>`
> To merge: `git merge claude/<slug>` then `orcheas workspace remove`
---
EOF
echo "✅  templates/claude/commands/done.md"

# =============================================================================
#  README.md  — add workspace section
# =============================================================================
cat > README.md <<'README'
# orcheas

Scaffolds Claude Code projects with a **vault** for project context,
a **`.claude/`** directory for hooks and slash commands, and
**git worktrees** so Claude's code is fully isolated from yours until you merge.

---

## Install

```bash
git clone https://github.com/LucReveyron/orcheas
cd orcheas
./install.sh
source ~/.zshrc   # or ~/.bashrc
```

---

## Workflow overview

```
orcheas init          ← scaffold vault + .claude/ + CLAUDE.md
orcheas workspace     ← create Claude's isolated worktree at ../[project]-claude

┌─────────────────────────────┐    ┌─────────────────────────────────┐
│  ~/projects/my-project/     │    │  ~/projects/my-project-claude/  │
│  (your directory)           │    │  (Claude's directory)           │
│  branch: main               │    │  branch: claude/<slug>          │
└─────────────────────────────┘    └─────────────────────────────────┘
         same .git ──────────────────────────────────────────^

      you code here              Claude codes here — never in yours
```

After Claude proposes a merge:
```bash
git diff main...claude/<slug>   # review
git merge claude/<slug>         # merge when happy
orcheas workspace remove        # tear down worktree
```

---

## Commands

### `orcheas init [path]`

Scaffold everything into the target directory (default: current dir).

```
orcheas init my-project/
```

Creates:
```
my-project/
├── CLAUDE.md                      ← agent rules & workflow (auto-refreshed)
├── TODO.md                        ← shared task list
├── vault/
│   ├── core/
│   │   ├── goal.md                ← EDIT: project objective
│   │   ├── rules.md               ← EDIT: hard constraints for Claude
│   │   └── routine.md             ← EDIT: tone and working style
│   ├── active/
│   │   └── summary.md             ← Claude-maintained state
│   └── memories/
│       └── log.md                 ← Claude-maintained append log
└── .claude/
    ├── settings.json              ← hooks
    ├── commands/                  ← /task  /done  /log  /review
    ├── agents/                    ← code-reviewer persona
    ├── hooks/                     ← session context + worktree guard
    └── logs/                      ← per-feature decision logs
```

---

### `orcheas workspace [branch]`

Create Claude's isolated git worktree at `../[project-name]-claude`.

```bash
orcheas workspace                    # reuse latest claude/* branch (or create placeholder)
orcheas workspace claude/add-auth    # use a specific branch
orcheas workspace add-auth           # claude/ prefix added automatically
```

- Creates the branch from `main` if it doesn't exist yet
- Copies `.claude/` into the worktree
- Prints the `code` command to open it in VSCode

**After setup, open Claude's workspace in a separate VSCode window:**
```bash
code ../my-project-claude
```
Then launch Claude Code there — it will only ever see and touch that directory.

---

### `orcheas workspace remove [--drop]`

Remove Claude's worktree after a merge.

```bash
orcheas workspace remove           # remove worktree, keep branch
orcheas workspace remove --drop    # remove worktree AND delete the branch
```

---

### `orcheas clean <vault-path>`

Reset mutable state without touching `vault/core/` or `TODO.md`.

```bash
orcheas clean my-project/vault
```

Resets: `vault/active/summary.md` · `vault/memories/*.md` · `.claude/logs/*.md`

---

### `orcheas update`

Reinstall from source repo.

```bash
orcheas update
ORCHEAS_SOURCE=/new/path orcheas update   # if you moved the repo
```

---

## Slash commands (inside Claude Code)

| Command | What it does |
|---------|-------------|
| `/task [id]` | Verify worktree, pick a TODO, create `claude/<slug>` branch |
| `/done` | Commit, push, output merge proposal with review instructions |
| `/log` | Write `.claude/logs/<slug>.md` with why/how/alternatives |
| `/review <target>` | Structured code review saved to `.claude/logs/` |

---

## Requirements

| Dependency | Notes |
|------------|-------|
| `bash` ≥ 3.2 | macOS default |
| `git` ≥ 2.5 | Worktrees require git 2.5+ |
| `claude` CLI | [Claude Code](https://docs.anthropic.com/claude-code) |
README
echo "✅  README.md (workspace section added)"

# =============================================================================
#  Summary
# =============================================================================
echo ""
echo "──────────────────────────────────────────────────────────"
echo "🎉  Worktree update applied!"
echo ""
echo "  Modified files:"
echo "    orcheas                              ← workspace create/remove commands"
echo "    CLAUDE.md                            ← worktree protocol section"
echo "    README.md                            ← workspace docs"
echo "    templates/claude/hooks/"
echo "      session-start.sh                  ← worktree detection + hard stop"
echo "      verify-branch.sh                  ← blocks edits if not in worktree"
echo "    templates/claude/commands/"
echo "      task.md                           ← pre-flight worktree check"
echo "      done.md                           ← merge proposal includes review cmds"
echo ""
echo "  New orcheas commands:"
echo "    orcheas workspace                   create worktree at ../[project]-claude"
echo "    orcheas workspace <branch>          create with specific branch"
echo "    orcheas workspace remove            tear down after merge"
echo "    orcheas workspace remove --drop     tear down + delete branch"
echo ""
echo "  Commit and push:"
echo "    git add -A"
echo "    git commit -m 'feat: add git worktree isolation for Claude'"
echo "    git push"
