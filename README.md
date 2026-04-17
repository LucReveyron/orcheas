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
