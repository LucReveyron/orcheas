# orcheas

Scaffolds Claude Code projects with a **vault** structure and agent protocol (`CLAUDE.md`).

---

## Install

```bash
git clone <this-repo>
cd orcheas
./install.sh
source ~/.zshrc   # or ~/.bashrc
```

Installs to `~/.local/share/orcheas`. Does not touch `~/.claude`.

---

## Commands

### `orcheas init [path]`

Scaffolds a vault and installs `CLAUDE.md` into the target directory (default: current dir).

```bash
orcheas init my-project/
```

Creates:
```
my-project/
├── CLAUDE.md                  ← agent operating protocol (auto-installed)
└── vault/
    ├── core/
    │   ├── goal.md            ← EDIT: your project objective
    │   ├── rules.md           ← EDIT: hard constraints for the agent
    │   └── routine.md         ← EDIT: agent tone and working style
    ├── active/
    │   ├── todo.md            ← agent checklist (filled after planning)
    │   └── summary.md         ← current project state (agent-maintained)
    └── memories/
        └── log.md             ← append-only action log (agent-maintained)
```

Safe to re-run — skips files that already exist.

---

### `orcheas clean <vault>`

Resets mutable vault state without touching `vault/core/`.

```bash
orcheas clean my-project/vault
```

- Resets `vault/active/todo.md` and `vault/active/summary.md` to blank templates
- Deletes all `vault/memories/*.md` and re-creates a fresh `log.md`

---

### `orcheas update`

Reinstalls from the source repo (path saved at install time).

```bash
orcheas update

# If you moved the repo:
ORCHEAS_SOURCE=/new/path orcheas update
```

---

## Workflow

1. `orcheas init` in your project
2. Fill in `vault/core/goal.md`
3. Open Claude Code — say **`plan`**
4. Approve the plan, paste it into `vault/active/todo.md`
5. Say **`execute`** — agent runs one step, stops, waits
6. Repeat until done

The `CLAUDE.md` installed by `orcheas init` defines this protocol and is loaded automatically by Claude Code.

---

## Vault reference

| File | Who writes | Purpose |
|------|-----------|---------|
| `vault/core/goal.md` | You | Project objective |
| `vault/core/rules.md` | You | Hard constraints for the agent |
| `vault/core/routine.md` | You | Agent tone and working style |
| `vault/active/todo.md` | You + agent | Step checklist |
| `vault/active/summary.md` | Agent | Current project state |
| `vault/memories/log.md` | Agent | Append-only action log |
| `vault/memories/*.md` | Agent | Topic documentation |

---

## Requirements

| Dependency | Notes |
|------------|-------|
| `bash` ≥ 3.2 | macOS default — no extras needed |
| `claude` CLI | [Claude Code](https://docs.anthropic.com/claude-code) |
