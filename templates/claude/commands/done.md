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
