#!/usr/bin/env bash
#
# Install / update justin_lin's Codex skills and agent prompts into ~/.codex/.
#
# Default mode is symlink, so edits in this repo take effect immediately.
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
    --copy) MODE="copy" ;;
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
AGENTS_SRC="$SCRIPT_DIR/agents"
SKILLS_DEST="$HOME/.codex/skills"
AGENTS_DEST="$HOME/.codex/agents"
CODEX_LOCAL_DEST="$REPO_ROOT/.codex"
NODE_PATH_DEST="$CODEX_LOCAL_DEST/ai-harness-node-path.txt"

skills=()
if [ -d "$SKILLS_SRC" ]; then
  for path in "$SKILLS_SRC"/*/; do
    [ -d "$path" ] || continue
    [ -f "$path/SKILL.md" ] || continue
    skills+=("$(basename "$path")")
  done
fi

agents=()
if [ -d "$AGENTS_SRC" ]; then
  for path in "$AGENTS_SRC"/*.md; do
    [ -f "$path" ] || continue
    agents+=("$(basename "$path")")
  done
fi

if [ ${#skills[@]} -eq 0 ] && [ ${#agents[@]} -eq 0 ]; then
  echo "nothing to install - no skills or agents found" >&2
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
    echo "warning: node not found during sync; repo-local Codex hooks will still depend on runtime PATH"
    return 0
  fi

  ensure_dir "$CODEX_LOCAL_DEST"
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

if [ "$UNINSTALL" -eq 1 ]; then
  for name in "${skills[@]}"; do
    uninstall_one "$SKILLS_DEST/$name"
  done
  for name in "${agents[@]}"; do
    uninstall_one "$AGENTS_DEST/$name"
  done
  exit 0
fi

NODE_BIN="$(detect_node_bin || true)"
write_node_path_file "$NODE_BIN"

echo "mode: $MODE"
echo

if [ ${#skills[@]} -gt 0 ]; then
  ensure_dir "$SKILLS_DEST"
  echo "skills: $SKILLS_SRC -> $SKILLS_DEST"
  for name in "${skills[@]}"; do
    install_one "$SKILLS_SRC/$name" "$SKILLS_DEST/$name"
  done
  echo
fi

if [ ${#agents[@]} -gt 0 ]; then
  ensure_dir "$AGENTS_DEST"
  echo "agents: $AGENTS_SRC -> $AGENTS_DEST"
  for name in "${agents[@]}"; do
    install_one "$AGENTS_SRC/$name" "$AGENTS_DEST/$name"
  done
  echo
fi

total=$(( ${#skills[@]} + ${#agents[@]} ))
echo "done. processed $total item(s):"
for name in "${skills[@]}"; do
  echo "  skill: $name"
done
for name in "${agents[@]}"; do
  echo "  agent: $name"
done
