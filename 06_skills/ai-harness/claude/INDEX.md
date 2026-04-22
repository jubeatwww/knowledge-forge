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
編輯這裡立即生效。sync 時遇到同名 skill / agent / command / hook /
audio / statusline 會直接 skip；如果本來就已經 link 到這個 repo，則當成
no-op。

This is **not** an agent-facing skill pack like [[../../habit-game/INDEX]].
It is Claude Code configuration carried across machines.

## Layout

```
ai-harness/claude/
├── skills/
│   ├── commit               -> ../../shared/skills/commit
│   ├── create-pr            -> ../../shared/skills/create-pr
│   ├── quick-commit         -> ../../shared/skills/quick-commit
│   ├── sporty-commit        -> ../../shared/skills/sporty-commit
│   ├── sporty-create-pr     -> ../../shared/skills/sporty-create-pr
│   ├── sporty-quick-commit  -> ../../shared/skills/sporty-quick-commit
│   ├── requirement-analysis -> ../../shared/skills/requirement-analysis
│   ├── table-archive-analysis -> ../../shared/skills/table-archive-analysis
│   └── code-review/         # claude-flavored wrapper + aspects/references
├── agents/
│   ├── code-review.agent.md
│   └── code-review-*.agent.md -> ../../shared/code-review/agents/...
├── commands/
│   └── checkin.md           # /checkin — vault-scoped daily log capture
├── hooks/
│   ├── play-sound.mjs       # cross-platform audio player, reads ~/.claude/audio/*.mp3
│   └── play-sound.ps1       # Windows mciSendString helper
├── settings.json            # hooks block merged into ~/.claude/settings.json by sync
├── statusline/
│   └── statusline-command.sh
├── sync.sh                  # skills + agents + commands + hooks + audio + statusline + settings → ~/.claude/ (bash)
└── sync.ps1                 # same, PowerShell for Windows
```

Audio files live at `../audio/` (sibling to this dir) and are copied/symlinked
into `~/.claude/audio/` by sync.

## Hooks

`hooks/play-sound.mjs` fires audio cues for Claude Code events. Audio files
live in `../audio/` and the script resolves them via `import.meta.url`, so
symlinks / absolute-path invocation both work.

Event → sound mapping:

| Hook event           | Arg                 | File                       |
|----------------------|---------------------|----------------------------|
| `PermissionRequest`  | `permission`        | `gojo_domain.mp3`          |
| `Stop`               | `stop`              | `pain_itami_o_kanjiro.mp3` |
| `SubagentStart`      | `subagent_start`    | `nico_nico_nii.mp3`        |
| `SubagentStop`       | `subagent_stop`     | `za_warudo.mp3`            |
| `SessionEnd`         | `session_end`       | `to_be_continued.mp3`      |
| `PostToolUseFailure` | `post_tool_failure` | `sukuna_domain.mp3`        |
| `StopFailure`        | `stop_failure`      | `saber_excalibur.mp3`      |
| `TaskCompleted`      | `task_completed`    | `megumin_explosion.mp3`    |

Hooks are wired via `settings.json` (this repo) using `$HOME/.claude/hooks/`,
so they fire globally (not only inside this vault — `$CLAUDE_PROJECT_DIR` is
unreliable for hook commands). Command shape:

```json
"command": "node $HOME/.claude/hooks/play-sound.mjs <arg>"
```

`sync.sh` / `sync.ps1` do three things:

1. Install hook scripts to `~/.claude/hooks/` and audio files to
   `~/.claude/hooks/` / `~/.claude/audio/`，若同名檔已存在則 skip；
   若已經是指向本 repo 的 symlink，則視為 no-op。
2. Detect a usable `node` binary during install and record it in
   `~/.claude/ai-harness-node-path.txt` so hook execution does not depend only
   on the runtime PATH.
3. Merge the `hooks` block from this repo's `settings.json` into
   `~/.claude/settings.json`, preserving every other key like `model`,
   `statusLine`, `enabledPlugins`.
4. `--uninstall` / `-Uninstall` reverses 1 (symlinks only, to avoid
   clobbering hand edits) and drops the `hooks` key from user settings.

Bash needs `jq` for the settings merge; PowerShell uses native
`ConvertFrom-Json` / `ConvertTo-Json`.

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

- `commit` / `quick-commit` / `create-pr` — 通用，但有 repo guard。
  偵測到 repo path 或 repo name 含 `sporty` 時才套用 Sporty 規則。
- `sporty-*` / `table-archive-analysis` — Sporty 專用。名稱 prefix +
  SKILL.md description guard 雙重保險；`table-archive-analysis` 因相容性
  保留舊名稱。真要關，在非 Sporty repo 的 `.claude/settings.json`
  停用即可。
- `code-review` / `requirement-analysis` — 通用。

## Slash command scope

- `/checkin` — Knowledge Forge vault 專用。Command 內建 vault 偵測
  （找 `AGENTS.md` + `00_inbox/` + `90_cache/` + `02_sources/`），
  不在 vault 內會直接拒絕，避免在別的 repo 亂寫。

## Related

- [[../INDEX]]
- [[../codex/INDEX]]
- Upstream：`~/sporty-ai-playbook/individual/justin_lin/claude/`
