# /review

Perform a structured code review on the specified target.

## Usage

```
/review <file-or-branch>
```

If no argument, check `TODO.md` for `[review]` items and review the first one.

## Steps

1. Identify the target.
2. If branch: `git diff main...<branch>`
3. If file: read full content.
4. Produce a review report (template below).
5. Save to `.claude/logs/review-<slug>-<YYYY-MM-DD>.md`.
6. Mark the `[review]` item in `TODO.md` as `[x]`.

## Review Report Template

```markdown
# Code Review — <target>

**Date:** <YYYY-MM-DD>
**Reviewer:** Claude
**Target:** <file or branch>

---

## Summary

<2-3 sentence overall assessment.>

## ✅ Strengths

- <what is done well>

## ⚠️ Issues

| Severity | File | Line | Description | Suggestion |
|----------|------|------|-------------|------------|
| 🔴 High  |      |      |             |            |
| 🟡 Med   |      |      |             |            |
| 🟢 Low   |      |      |             |            |

## 💡 Suggestions (non-blocking)

- <style, naming, architecture ideas>

## Security Checklist

- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] Errors handled safely (no stack traces exposed)

## Verdict

- [ ] ✅ Approve
- [ ] 🔄 Approve with minor changes
- [ ] ❌ Changes required
```
