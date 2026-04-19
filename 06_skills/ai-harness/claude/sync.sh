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
#   - Existing symlinks are replaced silently.
#   - Existing real directories or files are NOT clobbered. The script
#     reports them and skips, so other people's items (or hand-edited
#     copies) are never destroyed.

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
STATUSLINE_SRC="$SCRIPT_DIR/statusline/statusline-command.sh"
SKILLS_DEST="$HOME/.claude/skills"
AGENTS_DEST="$HOME/.claude/agents"
COMMANDS_DEST="$HOME/.claude/commands"
STATUSLINE_DEST="$HOME/.claude/statusline-command.sh"

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

if [ ${#skills[@]} -eq 0 ] && [ ${#agents[@]} -eq 0 ] && [ ${#commands[@]} -eq 0 ] && [ ! -f "$STATUSLINE_SRC" ]; then
  echo "nothing to install — no skills, agents, commands, or statusline found" >&2
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

uninstall_one() {
  local target="$1"
  if [ -L "$target" ]; then
    run "rm \"$target\""
    echo "removed symlink: $target"
  elif [ -d "$target" ] || [ -f "$target" ]; then
    echo "skip (not a symlink, leaving alone): $target"
  fi
}

install_one() {
  local src="$1"
  local target="$2"

  # Existing symlink — safe to replace.
  if [ -L "$target" ]; then
    run "rm \"$target\""
  # Existing real dir/file — refuse to clobber.
  elif [ -e "$target" ]; then
    echo "skip (exists, not a symlink — refusing to clobber): $target"
    return
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
  uninstall_one "$STATUSLINE_DEST"
  exit 0
fi

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

total=$(( ${#skills[@]} + ${#agents[@]} + ${#commands[@]} + statusline_installed ))
echo "done. installed $total item(s):"
for name in "${skills[@]}"; do
  echo "  skill: $name"
done
for name in "${agents[@]}"; do
  echo "  agent: $name"
done
for name in "${commands[@]}"; do
  echo "  command: $name"
done
if [ "$statusline_installed" -eq 1 ]; then
  echo "  statusline: $STATUSLINE_DEST"
fi