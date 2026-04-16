# Todo

> Steps to reach the goal. Populated after the agent proposes a plan and the user approves it. The agent picks the first unchecked item each run and works on it exclusively.

<!-- Example format: - [x] Step already done - [ ] Step to do next ← agent picks this one - [ ] Future step -->

- [x] Define the bash script architecture: list all sub-scripts, entry points, and file structure
- [x] Implement `agent_plan.sh` — calls Claude Code agent in planning mode with restricted folder/write access
- [x] Implement `agent_test_spec.sh` — calls Claude Code agent to write test specifications
- [x] Implement `agent_blocks.sh` — calls Claude Code agent to define project blocks (function list) and document them in the vault
- [x] Implement `agent_implement.sh` — calls Claude Code agent to implement a single function (accepts function name as arg)
- [x] Implement `agent_test_run.sh` — calls Claude Code agent to run tests and write report to vault (log + summary)
- [x] Implement `agent_finetune.sh` — calls Claude Code agent to finetune implementation based on test report
- [x] Implement `orchestrate.sh` — main script that chains all steps with context clears between each
- [x] Implement token usage progress bar (reads token count from Claude API response or session output)
- [x] Write unit tests for each script component
- [x] Document all dependencies in vault