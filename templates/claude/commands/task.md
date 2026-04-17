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
