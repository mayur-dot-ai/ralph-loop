# Ralph Wiggum Loop

An autonomous agent iteration pattern for task completion.

## Background

### The Problem

When building multi-agent AI systems, we faced a challenge: agents that needed to complete complex tasks would often:
- Stop after one step thinking they were done
- Get stuck without signaling they needed help  
- Have no mechanism to retry or iterate

### The Solution

The Ralph Wiggum Loop (named affectionately) implements a simple but effective pattern:

1. **External loop control** — A bash script controls iteration, not the LLM
2. **Completion signal** — Agent outputs `IMPLEMENTATION_COMPLETE` when done
3. **Max iterations** — Hard limit prevents runaway execution
4. **Fresh context** — Each iteration spawns a new agent process

This keeps the LLM focused on the task while the orchestration layer handles retry logic.

## Why "Ralph Wiggum"?

Like the Simpsons character, the pattern is simple and straightforward. It just keeps trying until it gets it right (or hits the limit). No overthinking, no complex state machines — just iterate until done.

## How It Works

```
┌─────────────────┐
│  Orchestrator   │
│  (bash script)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Spawn Agent    │────▶│  Agent works    │
│  with task      │     │  on task        │
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │ Check output    │
                        │ for completion  │
                        └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
            ┌──────────────┐          ┌──────────────┐
            │ COMPLETE     │          │ INCOMPLETE   │
            │ Exit success │          │ Loop again   │
            └──────────────┘          └──────────────┘
```

## Usage

```bash
./ralph-wrapper.sh <issue_number> [max_iterations]

# Example: Work on GitHub issue #14 with max 10 iterations
./ralph-wrapper.sh 14 10
```

## Requirements

- Bash
- Python 3.x
- A ClawServant agent (or compatible agent framework)
- GitHub wrapper for repo operations

## Configuration

Edit the script to set:
- `REPO` — Target repository name
- `ORG` — GitHub organization
- `MAX_ITERATIONS` — Default iteration limit

## Safety

The loop is controlled externally (bash), not by the LLM. This means:
- LLM cannot create infinite loops
- LLM can only signal "done" or "not done"
- Hard iteration limit always enforced
- Each iteration is isolated (fresh process)

## License

MIT

## Related

- [ClawServant](https://github.com/mayur-dot-ai/ClawServant) — The agent framework
- [ClawSysMon-Pro](https://github.com/mayur-dot-ai/ClawSysMon-Pro) — Project management for AI orchestration
