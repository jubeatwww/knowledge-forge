---
title: Codex Harness
kind: skill-index
tags:
  - codex
  - index
---

# Codex Harness

Portable Codex harness bits — skills + agent prompts — mirroring
`~/sporty-ai-playbook/individual/justin_lin/codex/`. Shares `../shared/`
with [[../claude/INDEX|the claude side]].

Vault 是 source of truth；`sync.sh` 預設以 symlink 裝進 `~/.codex/`，
編輯這裡立即生效。sync 時遇到同名 skill / agent 會以這個 repo 的版本
覆蓋掉。

## Layout

```
ai-harness/codex/
├── skills/
│   ├── commit               -> ../../shared/skills/commit
│   ├── create-pr            -> ../../shared/skills/create-pr
│   ├── quick-commit         -> ../../shared/skills/quick-commit
│   ├── sporty-commit        -> ../../shared/skills/sporty-commit
│   ├── sporty-create-pr     -> ../../shared/skills/sporty-create-pr
│   ├── sporty-quick-commit  -> ../../shared/skills/sporty-quick-commit
│   ├── requirement-analysis -> ../../shared/skills/requirement-analysis
│   ├── table-archive-analysis -> ../../shared/skills/table-archive-analysis
│   └── code-review/         # codex-flavored wrapper + agents/references
├── agents/
│   ├── code-review.agent.md
│   └── code-review-*.agent.md -> ../../shared/code-review/agents/...
└── sync.sh                  # skills + agents → ~/.codex/
```

## Usage

```bash
cd /path/to/knowledge-forge/06_skills/ai-harness/codex
./sync.sh            # symlink (default, idempotent)
./sync.sh --copy     # snapshot copy
./sync.sh --dry-run
./sync.sh --uninstall
```

## Skill scope

- `commit` / `quick-commit` / `create-pr` — 通用，但有 repo guard。
  偵測到 repo path 或 repo name 含 `sporty` 時才套用 Sporty 規則。
- `sporty-*` / `table-archive-analysis` — Sporty 專用。名稱 prefix +
  SKILL.md description guard 雙重保險；`table-archive-analysis` 因相容性
  保留舊名稱。非 Sporty 專案透過 Codex 設定停用。
- `code-review` / `requirement-analysis` — 通用。

## Related

- [[../INDEX]]
- [[../claude/INDEX]]
- Upstream：`~/sporty-ai-playbook/individual/justin_lin/codex/`
