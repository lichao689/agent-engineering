---
name: setup
description: Set up and repair this personal skills package across ~/.agents/skills, Codex, and Claude Code. Use before first installation, after moving to a new machine, or when a bundled skill is not visible.
---

# Setup

Install or refresh this repository's bundled skills. Inspection is read-only unless the user requests installation or repair.

## Commands

```bash
scripts/list-skills.sh
scripts/link-skills.sh --target agents
scripts/link-skills.sh --target codex
scripts/link-skills.sh --target claude
scripts/link-skills.sh --target all
```

Use `--strategy copy` or `--strategy link` to override the target's default installation strategy.

Default destination for `--target agents` is `~/.agents/skills`.

## Process

1. Run `scripts/list-skills.sh` to inspect the bundled skills.
2. Select `agents`, `codex`, `claude`, or `all` based on the requested host. Prefer `agents` for Grok Build and Codex shared discovery.
3. Install with `scripts/link-skills.sh --target <host>`.
4. Run `scripts/list-skills.sh` again and verify that each expected `SKILL.md` is present at the destination.
