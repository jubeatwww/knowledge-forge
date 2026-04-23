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
編輯這裡立即生效。sync 時遇到同名 skill / agent 會直接 skip；如果本來
就已經 link 到這個 repo，則當成 no-op。

Codex harness 現在也走 user-scope：
- hooks 腳本裝到 `~/.codex/hooks/`
- audio 裝到 `~/.codex/audio/`
- `notify` / `codex_hooks` / `status_line` 合併進 `~/.codex/config.toml`
- `SessionStart` / `PostToolUse` hooks 合併進 `~/.codex/hooks.json`
- 偵測到的 node 路徑寫進 `~/.codex/ai-harness-node-path.txt`

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
├── scripts/
│   ├── merge-config.mjs     # merge ai-harness settings into ~/.codex/config.toml
│   └── merge-hooks.mjs      # merge ai-harness hooks into ~/.codex/hooks.json
└── sync.sh                  # skills + agents + hooks + audio + config → ~/.codex/
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

## Audio hooks

- `notify` 負責 turn 完成音，因為官方 stable config 只保證這個通知點。
- experimental hooks 目前只接 `SessionStart` 和 `PostToolUse(Bash)`；
  `PostToolUse` 只在 shell payload 看起來是 failure 時才播音，避免每個
  Bash tool call 都吵一次。
- 實作上直接共用 `../claude/hooks/play-sound.mjs`，但 sync 會把 hooks /
  audio 安裝到 `~/.codex/`，所以這些音效設定會跟著 user-scope 走，
  不是只在單一 repo 生效。
- `sync.sh` 會把 ai-harness 需要的 `notify` / `features.codex_hooks` /
  `tui.status_line` 合併進 `~/.codex/config.toml`。如果你已經有自己的
  unmanaged `notify` 或 `tui.status_line`，sync 會保留原設定並印出 warning。
- 這不是 Claude hooks 的 1:1 對應。官方目前沒有對等的
  `PermissionRequest` / `SubagentStart` / `SubagentStop` / `TaskCompleted`
  事件。

## Related

- [[../INDEX]]
- [[../claude/INDEX]]
- Upstream：`~/sporty-ai-playbook/individual/justin_lin/codex/`
