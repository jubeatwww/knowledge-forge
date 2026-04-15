---
title: Claude Harness
kind: skill-index
tags:
  - claude-code
  - index
---

# Claude Harness

Portable Claude Code harness bits — skills, agents, statusline — mirroring
`~/sporty-ai-playbook/individual/justin_lin/claude/`. Shares `../shared/`
with [[../codex/INDEX|the codex side]].

Vault 是 source of truth；`sync.sh` 預設以 symlink 裝進 `~/.claude/`，
編輯這裡立即生效。

This is **not** an agent-facing skill pack like [[../../habit-game/INDEX]].
It is Claude Code configuration carried across machines.

## Layout

```
ai-harness/claude/
├── skills/
│   ├── sporty-commit        -> ../../shared/skills/sporty-commit
│   ├── sporty-create-pr     -> ../../shared/skills/sporty-create-pr
│   ├── sporty-quick-commit  -> ../../shared/skills/sporty-quick-commit
│   ├── requirement-analysis -> ../../shared/skills/requirement-analysis
│   └── code-review/         # claude-flavored wrapper + aspects/references
├── agents/
│   ├── code-review.agent.md
│   └── code-review-*.agent.md -> ../../shared/code-review/agents/...
├── statusline/
│   └── statusline-command.sh
└── sync.sh                  # skills + agents + statusline → ~/.claude/
```

## Usage

```bash
cd /path/to/knowledge-forge/06_skills/ai-harness/claude
./sync.sh            # symlink (default, idempotent)
./sync.sh --copy     # snapshot copy
./sync.sh --dry-run
./sync.sh --uninstall
```

## Skill scope

- `sporty-*` — Sporty 專用。名稱 prefix + SKILL.md description guard 雙重
  保險。真要關，在非 Sporty repo 的 `.claude/settings.json` 停用即可。
- `code-review` / `requirement-analysis` — 通用。

## Related

- [[../INDEX]]
- [[../codex/INDEX]]
- Upstream：`~/sporty-ai-playbook/individual/justin_lin/claude/`
