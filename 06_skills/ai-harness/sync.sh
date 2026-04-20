#!/usr/bin/env bash
#
# Sync Claude and Codex harnesses in one shot, treating this repo as the
# source of truth and replacing same-name installed items.
#
# Usage:
#   ./sync.sh                 # sync both Claude and Codex
#   ./sync.sh --dry-run       # pass through to both child scripts
#   ./sync.sh --copy
#   ./sync.sh --uninstall
#   ./sync.sh --claude-only   # sync only Claude
#   ./sync.sh --codex-only    # sync only Codex
#   ./sync.sh -h | --help

set -euo pipefail

TARGET_MODE="all"
PASSTHROUGH=()

show_help() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --claude-only)
      if [ "$TARGET_MODE" = "codex" ]; then
        echo "cannot combine --claude-only with --codex-only" >&2
        exit 2
      fi
      TARGET_MODE="claude"
      ;;
    --codex-only)
      if [ "$TARGET_MODE" = "claude" ]; then
        echo "cannot combine --claude-only with --codex-only" >&2
        exit 2
      fi
      TARGET_MODE="codex"
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      PASSTHROUGH+=("$1")
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_target() {
  local target="$1"
  local script="$SCRIPT_DIR/$target/sync.sh"

  if [ ! -f "$script" ]; then
    echo "missing child sync script: $script" >&2
    exit 1
  fi

  echo "==> $target"
  bash "$script" "${PASSTHROUGH[@]}"
  echo
}

case "$TARGET_MODE" in
  all)
    run_target "claude"
    run_target "codex"
    ;;
  claude)
    run_target "claude"
    ;;
  codex)
    run_target "codex"
    ;;
esac
