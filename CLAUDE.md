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
