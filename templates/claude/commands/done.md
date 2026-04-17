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
