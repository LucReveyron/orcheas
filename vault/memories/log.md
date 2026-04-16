# Agent Log

> Append-only. The agent adds an entry after each completed step.

<!-- Format: ## [YYYY-MM-DD@HH:MM:SS] — [Step title] - What was done - Key decisions or findings - Files created or modified -->

## [2026-03-18@00:00:09] — Document all dependencies in vault
- Created vault/memories/dependencies.md listing: claude CLI, bash >=4.0, awk, grep/sed/printf/seq
- Noted macOS bash 3.x limitation with fix instruction
- Files created: vault/memories/dependencies.md

## [2026-03-18@00:00:08] — Write unit tests for each script component
- Created tests/test_lib.sh: 6 tests for token_bar and context (all pass)
- Created tests/test_agents.sh: 12 tests for all agent scripts — arg validation, pre-condition checks, stub claude CLI
- All 18 tests pass
- Files created: tests/test_lib.sh, tests/test_agents.sh

## [2026-03-18@00:00:07] — Implement token usage progress bar
- Created lib/token_bar.sh: parses "context: USED/TOTAL" or "N input, N output" from claude output, renders █░ bar
- Created lib/context.sh: clear_context() stub (claude --print starts new session per invocation by default)
- Files created: lib/token_bar.sh, lib/context.sh

## [2026-03-18@00:00:06] — Implement orchestrate.sh and agent_finetune.sh
- Created orchestrate.sh: chains all steps, clears context between each, shows token bar after each step, loops over blocks from blocks.md
- Created scripts/agent_finetune.sh: reads test_report.md, skips if Status: PASS, otherwise fixes failing tests with minimal changes
- Files created: orchestrate.sh, scripts/agent_finetune.sh

## [2026-03-18@00:00:05] — Implement agent_test_run.sh
- Created scripts/agent_test_run.sh: detects language/framework, runs test suite, writes structured report to vault/memories/test_report.md
- Report includes: pass/fail summary, coverage, failed test details, per-failure recommendations
- Files created: scripts/agent_test_run.sh

## [2026-03-18@00:00:04] — Make scripts language-agnostic
- Removed bash-specific language from agent_test_spec.sh, agent_blocks.sh, agent_implement.sh
- agent_test_spec.sh: now groups tests by module/feature, not one file per block; lets agent choose conventions
- agent_blocks.sh: block can now be function/method/class/module — language-agnostic
- agent_implement.sh: instructs agent to follow existing project language/conventions
- Files modified: scripts/agent_test_spec.sh, scripts/agent_blocks.sh, scripts/agent_implement.sh

## [2026-03-18@00:00:03] — Implement agent_implement.sh
- Created scripts/agent_implement.sh: takes block_name as arg, extracts its spec from blocks.md using awk, prompts Claude to implement only that block
- Key decision: awk extracts the named section from blocks.md so the agent only sees the relevant spec — reduces hallucination risk
- Files created: scripts/agent_implement.sh

## [2026-03-18@00:00:02] — Implement agent_blocks.sh
- Created scripts/agent_blocks.sh: prompts Claude to analyze project structure and write blocks.md to vault/memories/
- Key decision: uses Read,Write,Glob tools only — no Bash execution during block discovery
- Files created: scripts/agent_blocks.sh

## [2026-03-18@00:00:01] — Implement agent_test_spec.sh
- Created scripts/agent_test_spec.sh: reads blocks.md + rules, prompts Claude to write test files into tests/
- Key decision: requires blocks.md to exist first (agent_blocks.sh must run before this); enforces no-external-framework rule
- Files created: scripts/agent_test_spec.sh

## [2026-03-18@00:00:00] — Implement agent_plan.sh
- Created scripts/agent_plan.sh: reads vault core files, pipes prompt to `claude --print` with `--allowedTools Read` (read-only restriction)
- Key decision: vault files are injected into the prompt directly rather than giving the agent filesystem access, limiting blast radius
- Files created: scripts/agent_plan.sh

## [2026-03-18] — Define bash script architecture
- Defined full project directory structure with entry point, scripts/, lib/, tests/
- Key decisions: each agent script takes vault path as arg; context.sh handles session resets; token_bar.sh parses Claude output for token usage
- Files modified: vault/active/todo.md (plan added), vault/memories/log.md