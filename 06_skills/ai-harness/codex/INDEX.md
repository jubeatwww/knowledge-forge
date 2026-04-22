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

這個 repo 也提供 repo-local Codex 音效設定：
`.codex/config.toml` 開 `notify` + `codex_hooks`，`.codex/hooks.json`
直接重用 `../claude/hooks/play-sound.mjs`，只是在 Codex 端用
`AI_HARNESS_AUDIO_DIR` 指回 repo 內 audio。
`sync.sh` 也會順手把偵測到的 node 路徑寫進 repo-local
`.codex/ai-harness-node-path.txt`，讓 notify / hooks 不只依賴 PATH。

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

Repo root 另外有：

```text
.codex/config.toml           # status line + notify + codex_hooks
.codex/hooks.json            # SessionStart / PostToolUse(Bash) hooks
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
- 實作上直接共用 `claude/hooks/play-sound.mjs`；Codex 只是在 command
  裡多塞 `AI_HARNESS_AUDIO_DIR`，讓同一支腳本改讀 repo 內 audio。
- 這不是 Claude hooks 的 1:1 對應。官方目前沒有對等的
  `PermissionRequest` / `SubagentStart` / `SubagentStop` / `TaskCompleted`
  事件。

## Related

- [[../INDEX]]
- [[../claude/INDEX]]
- Upstream：`~/sporty-ai-playbook/individual/justin_lin/codex/`
