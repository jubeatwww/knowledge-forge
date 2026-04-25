---
title: Copilot CLI Harness
kind: skill-index
tags:
  - copilot-cli
  - index
---

# Copilot CLI Harness

Portable GitHub Copilot CLI harness bits — skills, agents, hooks — mirroring
the Claude and Codex harnesses. Shares `../shared/` with
[[../claude/INDEX|the Claude side]] and [[../codex/INDEX|the Codex side]].

Vault is the source of truth; `sync.sh` installs items into `~/.copilot/`
(or `$COPILOT_HOME` if set) via symlink by default. Edits here take
effect immediately. Sync skips same-name items that already exist; if an
item is already linked to this repo, it is treated as a no-op.

## Layout

```
ai-harness/copilot/
├── skills/
│   ├── commit               -> ../../shared/skills/commit
│   ├── create-pr            -> ../../shared/skills/create-pr
│   ├── quick-commit         -> ../../shared/skills/quick-commit
│   ├── sporty-commit        -> ../../shared/skills/sporty-commit
│   ├── sporty-create-pr     -> ../../shared/skills/sporty-create-pr
│   ├── sporty-quick-commit  -> ../../shared/skills/sporty-quick-commit
│   ├── requirement-analysis -> ../../shared/skills/requirement-analysis
│   ├── table-archive-analysis -> ../../shared/skills/table-archive-analysis
│   ├── code-review/         # copilot-flavored wrapper + aspects/references
│   ├── code-smells/         # copilot-flavored wrapper + categories
│   ├── refactorings/        # copilot-flavored wrapper + techniques
│   └── checkin/             # vault check-in (converted from Claude command)
├── agents/
│   ├── code-review.agent.md
│   ├── code-review-*.agent.md -> ../../shared/code-review/agents/...
│   ├── code-quality-review.agent.md
│   └── code-quality-*.agent.md -> ../../shared/code-quality/agents/...
├── hooks/
│   └── ai-harness-hooks.json  # Copilot CLI hooks config (sessionStart/End, postToolUse, errorOccurred)
├── sync.sh                  # skills + agents + hooks + audio → ~/.copilot/ (bash)
└── sync.ps1                 # same, PowerShell for Windows
```

Audio files live at `../audio/` (sibling to this dir) and are copied/symlinked
into `~/.copilot/audio/` by sync. Hook scripts (`play-sound.mjs` /
`play-sound.ps1`) are shared from `../claude/hooks/` and installed to
`~/.copilot/hooks/`.

## Hooks

Copilot CLI uses a different hook system from Claude Code. Hook config is
stored in `hooks/ai-harness-hooks.json` and installed to
`~/.copilot/hooks/ai-harness-hooks.json`.

Supported event mapping:

| Copilot CLI event | Claude equivalent     | Sound                       |
|-------------------|-----------------------|-----------------------------|
| `sessionStart`    | —                     | `nico_nico_nii.mp3`         |
| `sessionEnd`      | `SessionEnd`          | `to_be_continued.mp3`       |
| `postToolUse`     | `PostToolUseFailure`  | `sukuna_domain.mp3` (failure only) |
| `errorOccurred`   | `PostToolUseFailure`  | `sukuna_domain.mp3`         |

Claude events without a Copilot CLI equivalent:
`PermissionRequest`, `Stop`, `SubagentStart`, `SubagentStop`, `StopFailure`,
`TaskCompleted`.

## Usage

```bash
# Linux / macOS / Git Bash
cd /path/to/knowledge-forge/06_skills/ai-harness/copilot
./sync.sh            # symlink (default, idempotent)
./sync.sh --copy     # snapshot copy
./sync.sh --dry-run
./sync.sh --uninstall
```

```powershell
# Windows (PowerShell) — symlink requires Developer Mode or admin
cd D:\knowledge-forge\Knowledge Forge\06_skills\ai-harness\copilot
.\sync.ps1              # symlink (default)
.\sync.ps1 -Copy        # snapshot copy
.\sync.ps1 -DryRun
.\sync.ps1 -Uninstall
```

## Skill scope

- `commit` / `quick-commit` / `create-pr` — general purpose with repo guard.
  Detects `sporty` in repo path or name to apply Sporty rules.
- `sporty-*` / `table-archive-analysis` — Sporty-specific.
- `code-review` / `requirement-analysis` — general purpose.
- `code-smells` / `refactorings` — general purpose code quality.
- `checkin` — Knowledge Forge vault only (has built-in vault detection).

## Differences from Claude harness

- No `/checkin` slash command — converted to a skill instead.
- No statusline — Copilot CLI manages its own via `/statusline`.
- No settings.json merge — hooks are configured via hooks.json files.
- Hook events are a subset of Claude's (4 vs 8 events).

## Related

- [[../INDEX]]
- [[../claude/INDEX]]
- [[../codex/INDEX]]
