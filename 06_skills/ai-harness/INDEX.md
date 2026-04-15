---
title: AI Harness Pack
kind: skill-index
tags:
  - claude-code
  - codex
  - index
---

# AI Harness

Claude Code + Codex 的 harness 檔案，跟
`~/sporty-ai-playbook/individual/justin_lin/` 的結構一致：兩家 agent 共用
`shared/` 來源，各自透過 `sync.sh` 以 symlink 方式裝進 `~/.claude/` 或
`~/.codex/`。

Vault 是 source of truth；symlink 模式下編輯這裡立即生效。

## Layout

```
06_skills/ai-harness/
├── shared/                      # 單一來源
│   ├── skills/
│   │   ├── sporty-commit/       # Sporty 專用（Jira + mvn + pre-release-tw）
│   │   ├── sporty-create-pr/    # Sporty 專用
│   │   ├── sporty-quick-commit/ # Sporty 專用
│   │   └── requirement-analysis/
│   └── code-review/             # agents + aspects + references
├── claude/
│   ├── skills/   -> ../../shared/skills/*  (symlink)
│   ├── agents/   -> ../../shared/code-review/agents/*.agent.md
│   ├── statusline/statusline-command.sh
│   └── sync.sh   # → ~/.claude/
└── codex/
    ├── skills/   -> ../../shared/skills/*  (symlink)
    ├── agents/   -> ../../shared/code-review/agents/*.agent.md
    └── sync.sh   # → ~/.codex/
```

## Install

```bash
cd /path/to/knowledge-forge/06_skills/ai-harness/claude && ./sync.sh
cd /path/to/knowledge-forge/06_skills/ai-harness/codex  && ./sync.sh
```

兩支 `sync.sh` 都支援 `--dry-run` / `--copy` / `--uninstall`。

## Skill scope

- `sporty-*` — **工作專用**。綁死在 Sporty 的 Jira（`opennetltd.atlassian.net`）、
  `mvn clean test-compile`、`pre-release-tw` base branch。名稱 prefix 與
  SKILL.md 的 description guard 雙重保險，避免 agent 在非 Sporty 專案誤用。
  真的要限制進一步，用每個 repo 的 `.claude/settings.json` 關掉即可。
- `requirement-analysis` / `code-review` — 通用，可以全域啟用。

## Related

- [[claude/INDEX]]
- [[codex/INDEX]]
- [[../INDEX]]
- Upstream 結構：`~/sporty-ai-playbook/individual/justin_lin/`
