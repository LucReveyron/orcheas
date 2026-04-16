# Dependencies

All external dependencies used in this project.

---

## claude (Claude Code CLI)
- **Used by**: all `scripts/agent_*.sh`, `orchestrate.sh`
- **Purpose**: runs AI agent steps (planning, block definition, implementation, testing, finetuning)
- **Install**: https://docs.anthropic.com/claude-code
- **Version requirement**: must support `--print`, `--model`, `--allowedTools`, `--output-format text`
- **Model selection**: set via `ORCHEAS_MODEL` env var or third arg to `orchestrate.sh`
  - `claude-opus-4-6` — most capable, slower
  - `claude-sonnet-4-6` — balanced (default)
  - `claude-haiku-4-5-20251001` — fastest, lightest

## bash
- **Used by**: all scripts
- **Purpose**: shell runtime for the entire orchestration system
- **Version requirement**: bash >= 3.2 (macOS default). `mapfile` is intentionally avoided for compatibility.
- **Note**: if you install bash 5 via `brew install bash`, it will be picked up automatically via the `#!/usr/bin/env bash` shebang.

## awk
- **Used by**: `scripts/agent_implement.sh`
- **Purpose**: extracts a named block section from `vault/memories/blocks.md`
- **Install**: standard POSIX tool, available on all Unix systems

## python3
- **Used by**: `lib/stream.sh`
- **Purpose**: parses Claude stream-json events in real-time (text, tool calls, token usage)
- **Install**: standard on macOS and most Linux systems
- **Version requirement**: python3 >= 3.6

## grep, sed, printf, seq
- **Used by**: `lib/token_bar.sh`, `scripts/agent_finetune.sh`
- **Purpose**: text parsing and terminal rendering
- **Install**: standard POSIX tools, available on all Unix systems
