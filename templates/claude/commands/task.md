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
