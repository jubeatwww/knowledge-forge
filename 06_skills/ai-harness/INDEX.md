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
`sync.sh` / child sync scripts 遇到 `~/.claude/` / `~/.codex/` 裡同名項目
時會直接 skip，不覆蓋既有檔案；如果本來就已經連到這個 repo，則視為
no-op。

Codex 現在也跟 Claude 一樣走 user-scope 安裝：skills / agents 裝到
`~/.codex/`，`notify` / hooks / status line 也由 `codex/sync.sh`
合併進 `~/.codex/config.toml` 和 `~/.codex/hooks.json`，不再依賴 repo
root 的 tracked `.codex/` 設定檔。

## Layout

```
06_skills/ai-harness/
├── shared/                      # 單一來源
│   ├── skills/
│   │   ├── commit/              # repo-aware generic commit
│   │   ├── create-pr/           # repo-aware generic PR flow
│   │   ├── quick-commit/        # repo-aware generic quick commit
│   │   ├── sporty-commit/       # Sporty 專用（Jira + mvn + pre-release-tw）
│   │   ├── sporty-create-pr/    # Sporty 專用
│   │   ├── sporty-quick-commit/ # Sporty 專用
│   │   ├── requirement-analysis/
│   │   └── table-archive-analysis/ # Sporty DBA / archive review 專用
│   └── code-review/             # agents + aspects + references
├── sync.sh                      # 一次同步 claude/ + codex/
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
cd /path/to/knowledge-forge/06_skills/ai-harness && ./sync.sh
```

只同步單邊時，仍可直接跑各自的腳本：

```bash
cd /path/to/knowledge-forge/06_skills/ai-harness/claude && ./sync.sh
cd /path/to/knowledge-forge/06_skills/ai-harness/codex  && ./sync.sh
```

頂層 `sync.sh` 會把 flags 原封不動往下傳，所以同樣支援
`--dry-run` / `--copy` / `--uninstall`，另外也支援
`--claude-only` / `--codex-only`。

## Skill scope

- `commit` / `quick-commit` / `create-pr` — 通用，但有 repo guard。
  偵測到 repo path 或 repo name 含 `sporty` 時，自動切到 Sporty 規則；
  否則走 generic 流程，不要求 Jira ticket。
- `sporty-*` / `table-archive-analysis` — **工作專用**。綁死在 Sporty 的
  Jira（`opennetltd.atlassian.net`）、`mvn clean test-compile`、
  `pre-release-tw` base branch、`service-patron` / `afbet_patron`
  archive review。`table-archive-analysis` 保留舊名稱，避免打破既有
  `~/.claude/skills/` 使用習慣。真的要限制進一步，用每個 repo 的
  `.claude/settings.json` 關掉即可。
- `requirement-analysis` / `code-review` — 通用，可以全域啟用。

## Related

- [[claude/INDEX]]
- [[codex/INDEX]]
- [[../INDEX]]
- Upstream 結構：`~/sporty-ai-playbook/individual/justin_lin/`
