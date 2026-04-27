#!/usr/bin/env bash
#
# Register and index the Knowledge Forge vault's curated folders with qmd.
#
# Design:
#   - qmd is assumed to be installed globally (see ../INDEX.md).
#   - This script owns the collection layout for this vault, so the vault
#     stays portable: clone repo on a new machine → run this once → qmd +
#     Claude Code MCP are ready.
#   - Named index: `knowledge-forge` (override with QMD_INDEX). The SQLite
#     file lives at ~/.cache/qmd/knowledge-forge.sqlite and is NOT committed.
#
# Usage:
#   ./bootstrap.sh               # add missing collections + embed
#   QMD_INDEX=kf-dev ./bootstrap.sh
#   ./bootstrap.sh --no-embed    # register only, skip embedding
#
# Idempotent: re-running does not duplicate collections.

set -euo pipefail

INDEX_NAME="${QMD_INDEX:-knowledge-forge}"
DO_EMBED=1

while [ $# -gt 0 ]; do
  case "$1" in
    --no-embed) DO_EMBED=0 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown flag: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if ! command -v qmd >/dev/null 2>&1; then
  echo "error: qmd not found in PATH. Install: https://github.com/tobi/qmd" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Script path: <vault>/06_skills/ai-harness/qmd/bootstrap.sh — up 3 to vault.
VAULT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [ ! -f "$VAULT_ROOT/AGENTS.md" ] || [ ! -d "$VAULT_ROOT/00_inbox" ] \
   || [ ! -d "$VAULT_ROOT/90_cache" ] || [ ! -d "$VAULT_ROOT/02_sources" ]; then
  echo "error: resolved vault root looks wrong: $VAULT_ROOT" >&2
  exit 1
fi

echo "vault root: $VAULT_ROOT"
echo "qmd index:  $INDEX_NAME"
echo

# Curated folders only. Deliberately excluded:
#   00_inbox/         — raw capture; human triages before it's worth searching
#   02_sources/       — Notion stubs, not full content
#   90_cache/         — generated Notion snapshots
#   91_exports/, 99_templates/, .forge/ — non-knowledge
COLLECTIONS=(
  "hubs:01_hubs"
  "notes:03_notes"
  "playbooks:04_playbooks"
  "projects:05_projects"
  "skills:06_skills"
  "context-packs:07_context-packs"
)

added=0
skipped=0
for entry in "${COLLECTIONS[@]}"; do
  name="${entry%%:*}"
  rel="${entry##*:}"
  abs="$VAULT_ROOT/$rel"

  if [ ! -d "$abs" ]; then
    echo "skip $name ($rel): directory does not exist"
    skipped=$((skipped + 1))
    continue
  fi

  if qmd --index "$INDEX_NAME" collection show "$name" >/dev/null 2>&1; then
    echo "skip $name: already registered"
    skipped=$((skipped + 1))
    continue
  fi

  echo "add  $name -> $abs"
  qmd --index "$INDEX_NAME" collection add "$abs" --name "$name"
  added=$((added + 1))
done

echo
echo "collections: $added added, $skipped skipped"

if [ "$DO_EMBED" -eq 1 ]; then
  echo
  echo "embedding (first run may take a while — local GGUF models auto-download)..."
  qmd --index "$INDEX_NAME" embed
fi

echo
qmd --index "$INDEX_NAME" status || true
