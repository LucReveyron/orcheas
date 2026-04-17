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
