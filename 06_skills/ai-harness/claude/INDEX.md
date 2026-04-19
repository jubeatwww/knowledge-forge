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
├── commands/
│   └── checkin.md           # /checkin — vault-scoped daily log capture
├── statusline/
│   └── statusline-command.sh
├── sync.sh                  # skills + agents + commands + statusline → ~/.claude/ (bash)
└── sync.ps1                 # same, PowerShell for Windows
```

## Usage

```bash
# Linux / macOS / Git Bash
cd /path/to/knowledge-forge/06_skills/ai-harness/claude
./sync.sh            # symlink (default, idempotent)
./sync.sh --copy     # snapshot copy
./sync.sh --dry-run
./sync.sh --uninstall
```

```powershell
# Windows (PowerShell) — symlink 需要 Developer Mode 或管理員權限
cd D:\knowledge-forge\Knowledge Forge\06_skills\ai-harness\claude
.\sync.ps1              # symlink (default)
.\sync.ps1 -Copy        # snapshot copy
.\sync.ps1 -DryRun
.\sync.ps1 -Uninstall
```

## Skill scope

- `sporty-*` — Sporty 專用。名稱 prefix + SKILL.md description guard 雙重
  保險。真要關，在非 Sporty repo 的 `.claude/settings.json` 停用即可。
- `code-review` / `requirement-analysis` — 通用。

## Slash command scope

- `/checkin` — Knowledge Forge vault 專用。Command 內建 vault 偵測
  （找 `AGENTS.md` + `00_inbox/` + `90_cache/` + `02_sources/`），
  不在 vault 內會直接拒絕，避免在別的 repo 亂寫。

## Related

- [[../INDEX]]
- [[../codex/INDEX]]
- Upstream：`~/sporty-ai-playbook/individual/justin_lin/claude/`
