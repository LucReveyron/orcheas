# Architecture

## Project Structure

```
orcheas/
├── orchestrate.sh            ← main entry point, chains all agents
├── scripts/
│   ├── agent_plan.sh         ← planning agent (restricted access)
│   ├── agent_test_spec.sh    ← test specification agent
│   ├── agent_blocks.sh       ← project block definition agent
│   ├── agent_implement.sh    ← single function implementation agent
│   ├── agent_test_run.sh     ← test runner + report writer
│   └── agent_finetune.sh     ← finetune agent based on test report
├── lib/
│   ├── context.sh            ← shared: clear context between agents
│   └── token_bar.sh          ← token usage progress bar
├── tests/
│   └── test_*.sh             ← unit tests per script
└── vault/                    ← vault structure (goal, rules, routine, todo, summary, memories)
```

## Key Design Decisions
- Each `agent_*.sh` receives the vault path as first argument
- `context.sh` handles Claude session resets between agent calls
- `token_bar.sh` parses token usage from Claude output and renders a progress bar in the terminal
- `orchestrate.sh` calls scripts in sequence, halting on any non-zero exit
