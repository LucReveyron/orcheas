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
