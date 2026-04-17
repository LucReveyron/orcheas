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
