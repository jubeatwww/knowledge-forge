#!/usr/bin/env bash
#
# Install / update justin_lin's Claude skills and agents into ~/.claude/.
#
# Default mode is symlink — edits in this repo take effect immediately,
# no need to re-run after every change.
#
# Usage:
#   ./sync.sh              # symlink skills + agents (default, idempotent)
#   ./sync.sh --copy       # snapshot copy with cp -rf instead
#   ./sync.sh --dry-run    # print what would happen, change nothing
#   ./sync.sh --uninstall  # remove only the items this script installed
#   ./sync.sh -h | --help  # show this help
#
# Conflict handling:
#   - If the same name already exists, leave it alone and skip installation.
#   - If the existing entry is already linked to this repo, skip as a no-op.

set -euo pipefail

MODE="symlink"
DRY_RUN=0
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --copy)      MODE="copy" ;;
    --dry-run)   DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown flag: $1" >&2
      echo "see ./sync.sh --help" >&2
      exit 2
      ;;
  esac
  shift
done

# Resolve source dirs relative to this script, so it works regardless of cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
AGENTS_SRC="$SCRIPT_DIR/agents"
COMMANDS_SRC="$SCRIPT_DIR/commands"
HOOKS_SRC="$SCRIPT_DIR/hooks"
AUDIO_SRC="$SCRIPT_DIR/../audio"
STATUSLINE_SRC="$SCRIPT_DIR/statusline/statusline-command.sh"
SETTINGS_SRC="$SCRIPT_DIR/settings.json"
SKILLS_DEST="$HOME/.claude/skills"
AGENTS_DEST="$HOME/.claude/agents"
COMMANDS_DEST="$HOME/.claude/commands"
HOOKS_DEST="$HOME/.claude/hooks"
AUDIO_DEST="$HOME/.claude/audio"
STATUSLINE_DEST="$HOME/.claude/statusline-command.sh"
SETTINGS_DEST="$HOME/.claude/settings.json"
NODE_PATH_DEST="$HOME/.claude/ai-harness-node-path.txt"

# Collect skill names (any directory under skills/ that contains SKILL.md).
skills=()
if [ -d "$SKILLS_SRC" ]; then
  for path in "$SKILLS_SRC"/*/; do
    [ -d "$path" ] || continue
    [ -f "$path/SKILL.md" ] || continue
    skills+=("$(basename "$path")")
  done
fi

# Collect agent files (*.md under agents/, deduplicated).
agents=()
if [ -d "$AGENTS_SRC" ]; then
  for path in "$AGENTS_SRC"/*.md; do
    [ -f "$path" ] || continue
    agents+=("$(basename "$path")")
  done
fi

# Collect slash-command files (*.md under commands/).
commands=()
if [ -d "$COMMANDS_SRC" ]; then
  for path in "$COMMANDS_SRC"/*.md; do
    [ -f "$path" ] || continue
    commands+=("$(basename "$path")")
  done
fi

# Collect hook files (*.mjs / *.ps1 under hooks/).
hook_files=()
if [ -d "$HOOKS_SRC" ]; then
  for path in "$HOOKS_SRC"/*.mjs "$HOOKS_SRC"/*.ps1; do
    [ -f "$path" ] || continue
    hook_files+=("$(basename "$path")")
  done
fi

# Collect audio files (*.mp3 under audio/).
audio_files=()
if [ -d "$AUDIO_SRC" ]; then
  for path in "$AUDIO_SRC"/*.mp3; do
    [ -f "$path" ] || continue
    audio_files+=("$(basename "$path")")
  done
fi

if [ ${#skills[@]} -eq 0 ] && [ ${#agents[@]} -eq 0 ] && [ ${#commands[@]} -eq 0 ] \
   && [ ${#hook_files[@]} -eq 0 ] && [ ${#audio_files[@]} -eq 0 ] \
   && [ ! -f "$STATUSLINE_SRC" ] && [ ! -f "$SETTINGS_SRC" ]; then
  echo "nothing to install — no skills, agents, commands, hooks, audio, statusline, or settings found" >&2
  exit 1
fi

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY: $*"
  else
    eval "$@"
  fi
}

ensure_dir() {
  if [ ! -d "$1" ]; then
    run "mkdir -p \"$1\""
  fi
}

detect_node_bin() {
  if [ -n "${AI_HARNESS_NODE_BIN:-}" ] && [ -x "${AI_HARNESS_NODE_BIN}" ]; then
    printf '%s\n' "${AI_HARNESS_NODE_BIN}"
    return 0
  fi

  if command -v node >/dev/null 2>&1; then
    command -v node
    return 0
  fi

  for candidate in \
    "$HOME/.volta/bin/node" \
    /opt/homebrew/bin/node \
    /usr/local/bin/node \
    /opt/local/bin/node
  do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  local found=""
  for candidate in "$HOME"/.nvm/versions/node/*/bin/node; do
    [ -x "$candidate" ] || continue
    found="$candidate"
  done
  if [ -n "$found" ]; then
    printf '%s\n' "$found"
    return 0
  fi

  return 1
}

write_node_path_file() {
  local node_bin="$1"

  if [ -z "$node_bin" ]; then
    echo "warning: node not found during sync; hook commands will still depend on runtime PATH"
    return 0
  fi

  ensure_dir "$(dirname "$NODE_PATH_DEST")"
  if [ -f "$NODE_PATH_DEST" ] && [ "$(cat "$NODE_PATH_DEST" 2>/dev/null)" = "$node_bin" ]; then
    echo "node path unchanged: $NODE_PATH_DEST"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY: write node path $node_bin -> $NODE_PATH_DEST"
  else
    printf '%s\n' "$node_bin" > "$NODE_PATH_DEST"
  fi
  echo "node path: $node_bin"
}

render_settings_source() {
  local out="$1"

  if ! command -v jq >/dev/null 2>&1 || [ -z "${NODE_BIN:-}" ]; then
    run "cp \"$SETTINGS_SRC\" \"$out\""
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY: render settings with node path $NODE_BIN"
    return 0
  fi

  jq --arg node "$NODE_BIN" '
    .hooks |= with_entries(
      .value |= map(
        .hooks |= map(
          if .type == "command" and (.command | test("play-sound\\.mjs ")) then
            .command = ("\"" + $node + "\" $HOME/.claude/hooks/play-sound.mjs " + ((.command | capture(" (?<event>[^ ]+)$")).event))
          else
            .
          end
        )
      )
    )
  ' "$SETTINGS_SRC" > "$out"
}

uninstall_one() {
  local target="$1"
  if [ -L "$target" ]; then
    run "rm \"$target\""
    echo "removed symlink: $target"
  elif [ -d "$target" ] || [ -f "$target" ]; then
    echo "skip (not a symlink, leaving alone): $target"
  fi
}

merge_settings() {
  [ -f "$SETTINGS_SRC" ] || return 0
  if ! command -v jq >/dev/null 2>&1; then
    echo "skip settings.json merge (jq not installed)"
    return 0
  fi
  ensure_dir "$(dirname "$SETTINGS_DEST")"
  if [ ! -f "$SETTINGS_DEST" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "DRY: create $SETTINGS_DEST from rendered settings template"
    else
      local rendered
      rendered=$(mktemp)
      render_settings_source "$rendered"
      mv "$rendered" "$SETTINGS_DEST"
      echo "created: $SETTINGS_DEST"
    fi
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY: merge hooks from $SETTINGS_SRC into $SETTINGS_DEST"
    return 0
  fi
  local tmp rendered
  tmp=$(mktemp)
  rendered=$(mktemp)
  render_settings_source "$rendered"
  jq --slurpfile proj "$rendered" '.hooks = $proj[0].hooks' "$SETTINGS_DEST" > "$tmp"
  rm -f "$rendered"
  mv "$tmp" "$SETTINGS_DEST"
  echo "merged hooks block into: $SETTINGS_DEST"
}

uninstall_settings() {
  [ -f "$SETTINGS_DEST" ] || return 0
  if ! command -v jq >/dev/null 2>&1; then
    echo "skip settings.json clean (jq not installed)"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY: remove hooks key from $SETTINGS_DEST"
    return 0
  fi
  local tmp
  tmp=$(mktemp)
  jq 'del(.hooks)' "$SETTINGS_DEST" > "$tmp"
  mv "$tmp" "$SETTINGS_DEST"
  echo "removed hooks block from: $SETTINGS_DEST"
}

install_one() {
  local src="$1"
  local target="$2"

  if [ -L "$target" ] || [ -e "$target" ]; then
    if [ -L "$target" ] && [ "$src" -ef "$target" ]; then
      echo "skip (already linked): $target"
    else
      echo "skip (name exists, leaving alone): $target"
    fi
    return 0
  fi

  if [ "$MODE" = "symlink" ]; then
    run "ln -s \"$src\" \"$target\""
    echo "linked: $target -> $src"
  else
    run "cp -rf \"$src\" \"$target\""
    echo "copied: $target"
  fi
}

# --- Uninstall mode ---
if [ "$UNINSTALL" -eq 1 ]; then
  for name in "${skills[@]}"; do
    uninstall_one "$SKILLS_DEST/$name"
  done
  for name in "${agents[@]}"; do
    uninstall_one "$AGENTS_DEST/$name"
  done
  for name in "${commands[@]}"; do
    uninstall_one "$COMMANDS_DEST/$name"
  done
  for name in "${hook_files[@]}"; do
    uninstall_one "$HOOKS_DEST/$name"
  done
  for name in "${audio_files[@]}"; do
    uninstall_one "$AUDIO_DEST/$name"
  done
  uninstall_one "$STATUSLINE_DEST"
  uninstall_settings
  exit 0
fi

NODE_BIN="$(detect_node_bin || true)"
write_node_path_file "$NODE_BIN"

# --- Install mode ---
echo "mode: $MODE"
echo

# Skills
if [ ${#skills[@]} -gt 0 ]; then
  ensure_dir "$SKILLS_DEST"
  echo "skills: $SKILLS_SRC -> $SKILLS_DEST"
  for name in "${skills[@]}"; do
    install_one "$SKILLS_SRC/$name" "$SKILLS_DEST/$name"
  done
  echo
fi

# Agents
if [ ${#agents[@]} -gt 0 ]; then
  ensure_dir "$AGENTS_DEST"
  echo "agents: $AGENTS_SRC -> $AGENTS_DEST"
  for name in "${agents[@]}"; do
    install_one "$AGENTS_SRC/$name" "$AGENTS_DEST/$name"
  done
  echo
fi

# Slash commands
if [ ${#commands[@]} -gt 0 ]; then
  ensure_dir "$COMMANDS_DEST"
  echo "commands: $COMMANDS_SRC -> $COMMANDS_DEST"
  for name in "${commands[@]}"; do
    install_one "$COMMANDS_SRC/$name" "$COMMANDS_DEST/$name"
  done
  echo
fi

# Hooks.
if [ ${#hook_files[@]} -gt 0 ]; then
  ensure_dir "$HOOKS_DEST"
  echo "hooks: $HOOKS_SRC -> $HOOKS_DEST"
  for name in "${hook_files[@]}"; do
    install_one "$HOOKS_SRC/$name" "$HOOKS_DEST/$name"
  done
  echo
fi

# Audio. Symlink mode handles individual files cleanly; copy mode duplicates
# the *.mp3 bytes once per machine.
if [ ${#audio_files[@]} -gt 0 ]; then
  ensure_dir "$AUDIO_DEST"
  echo "audio: $AUDIO_SRC -> $AUDIO_DEST"
  for name in "${audio_files[@]}"; do
    install_one "$AUDIO_SRC/$name" "$AUDIO_DEST/$name"
  done
  echo
fi

# Statusline (Claude Code specific)
statusline_installed=0
if [ -f "$STATUSLINE_SRC" ]; then
  ensure_dir "$HOME/.claude"
  echo "statusline: $STATUSLINE_SRC -> $STATUSLINE_DEST"
  install_one "$STATUSLINE_SRC" "$STATUSLINE_DEST"
  if [ "$MODE" = "copy" ] && [ "$DRY_RUN" -eq 0 ] && [ -f "$STATUSLINE_DEST" ]; then
    chmod +x "$STATUSLINE_DEST"
  fi
  statusline_installed=1
  echo
fi

# settings.json hooks merge (Claude Code specific). Always merge, regardless of
# --copy / symlink mode — we can't symlink a single key inside a shared file.
settings_installed=0
if [ -f "$SETTINGS_SRC" ]; then
  echo "settings: merge hooks from $SETTINGS_SRC into $SETTINGS_DEST"
  merge_settings
  settings_installed=1
  echo
fi

total=$(( ${#skills[@]} + ${#agents[@]} + ${#commands[@]} + ${#hook_files[@]} + ${#audio_files[@]} + statusline_installed + settings_installed ))
echo "done. processed $total item(s):"
for name in "${skills[@]}"; do
  echo "  skill:   $name"
done
for name in "${agents[@]}"; do
  echo "  agent:   $name"
done
for name in "${commands[@]}"; do
  echo "  command: $name"
done
for name in "${hook_files[@]}"; do
  echo "  hook:    $name"
done
for name in "${audio_files[@]}"; do
  echo "  audio:   $name"
done
if [ "$statusline_installed" -eq 1 ]; then
  echo "  statusline: $STATUSLINE_DEST"
fi
if [ "$settings_installed" -eq 1 ]; then
  echo "  settings:   $SETTINGS_DEST (hooks merged)"
fi
