# Ralph Wiggum Loop

An autonomous agent iteration pattern for task completion.

## Credits

This pattern was inspired by and learned from:
**[Ralph Wiggum Loop - AwesomeClaude.ai](https://awesomeclaude.ai/ralph-wiggum)**

We adapted it for our multi-agent orchestration system.

---

## Background

### The Problem

When building multi-agent AI systems, we faced a challenge: agents that needed to complete complex tasks would often:
- Stop after one step thinking they were done
- Get stuck without signaling they needed help  
- Have no mechanism to retry or iterate

### The Solution

The Ralph Wiggum Loop implements a simple but effective pattern:

1. **External loop control** — Code controls iteration, not the LLM
2. **Completion signal** — Agent outputs `TASK_DONE` when finished
3. **Max iterations** — Hard limit prevents runaway execution
4. **Fresh context** — Each iteration spawns a new agent process
5. **Durable state** — Iteration count persisted to file, not LLM memory

This keeps the LLM focused on the task while the orchestration layer handles retry logic.

## Why "Ralph Wiggum"?

Like the Simpsons character, the pattern is simple and straightforward. It just keeps trying until it gets it right (or hits the limit). No overthinking, no complex state machines — just iterate until done.

## How It Works

```
┌─────────────────┐
│  Loop Control   │
│  (Python/Bash)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│  while iteration < max AND status != done:  │
│    1. Load task + iteration count           │
│    2. Call LLM with task                    │
│    3. Check output for TASK_DONE            │
│    4. If done → exit success                │
│    5. If not → increment counter, persist   │
└─────────────────────────────────────────────┘
```

## Task File Format

```markdown
---
task_id: abc123
iteration: 3
max_iterations: 10
status: in_progress
created_at: 2026-02-19T10:00:00Z
---

Your actual task description here...
```

- **Python manages** the frontmatter (iteration, status)
- **LLM focuses** on the task content
- **State persists** to disk between iterations

## Completion Signal

The LLM signals completion by outputting:

```
TASK_DONE
```

This can appear anywhere in the output. The loop controller checks for it.

## Usage

### Standalone Script
```bash
./ralph-wrapper.sh <issue_number> [max_iterations]

# Example: Work on GitHub issue #14 with max 10 iterations
./ralph-wrapper.sh 14 10
```

### Integrated (ClawServant)
```bash
python3 clawservant.py --task "task.md" --loop --max-iterations 10
```

## Safety

The loop is controlled externally, not by the LLM:
- LLM **cannot** create infinite loops
- LLM can only signal "done" or continue working
- Hard iteration limit **always** enforced
- State persisted to file (survives crashes)
- Each iteration is isolated

## Implementation Notes

**DO NOT** let the LLM:
- Control the iteration counter
- Decide max iterations
- Manage its own state file

**DO** let Python/Bash:
- Track iterations
- Enforce limits
- Persist state
- Check for completion signal

## License

MIT

## Related

- [ClawServant](https://github.com/mayur-dot-ai/ClawServant) — The agent framework (integrating this pattern)
- [ClawSysMon-Pro](https://github.com/mayur-dot-ai/ClawSysMon-Pro) — Project management for AI orchestration
