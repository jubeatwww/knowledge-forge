#!/usr/bin/env node

import { existsSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const remove = args.find((arg) => arg.startsWith('--remove:'));
const target = remove ? remove.slice('--remove:'.length) : args.find((arg) => !arg.startsWith('--'));

if (!target) {
  console.error('usage: merge-hooks.mjs [--dry-run] <target> | --remove:<target>');
  process.exit(2);
}

const desiredHooks = {
  SessionStart: [
    {
      matcher: 'startup|resume',
      hooks: [
        {
          type: 'command',
          command: 'NODE_BIN="$(cat "$HOME/.codex/ai-harness-node-path.txt" 2>/dev/null || true)"; if [ -z "$NODE_BIN" ]; then NODE_BIN="$(command -v node 2>/dev/null || true)"; fi; [ -n "$NODE_BIN" ] || exit 0; "$NODE_BIN" "$HOME/.codex/hooks/play-sound.mjs" session_start',
          timeout: 5,
        },
      ],
    },
  ],
  PostToolUse: [
    {
      matcher: 'Bash',
      hooks: [
        {
          type: 'command',
          command: 'NODE_BIN="$(cat "$HOME/.codex/ai-harness-node-path.txt" 2>/dev/null || true)"; if [ -z "$NODE_BIN" ]; then NODE_BIN="$(command -v node 2>/dev/null || true)"; fi; [ -n "$NODE_BIN" ] || exit 0; "$NODE_BIN" "$HOME/.codex/hooks/play-sound.mjs" post_tool_use',
          timeout: 5,
        },
      ],
    },
  ],
};

const targetExists = existsSync(target);
if (remove && !targetExists) {
  if (dryRun) {
    console.log(`DRY: clean Codex hooks at ${target} (target missing)`);
  } else {
    console.log(`skip Codex hooks cleanup: ${target} does not exist`);
  }
  process.exit(0);
}

const root = targetExists ? JSON.parse(readFileSync(target, 'utf8')) : {};
if (!root.hooks || typeof root.hooks !== 'object') {
  root.hooks = {};
}

for (const [key, value] of Object.entries(desiredHooks)) {
  if (remove) {
    if (isEqual(root.hooks[key], value)) {
      delete root.hooks[key];
    }
    continue;
  }

  if (!(key in root.hooks)) {
    root.hooks[key] = value;
    continue;
  }

  if (!isEqual(root.hooks[key], value)) {
    console.error(`skip Codex hook merge: unmanaged hooks.${key} already exists`);
  }
}

if (Object.keys(root.hooks).length === 0) {
  delete root.hooks;
}

const next = `${JSON.stringify(root, null, 2)}\n`;
if (dryRun) {
  console.log(`DRY: ${remove ? 'clean' : 'merge'} Codex hooks at ${target}`);
  process.exit(0);
}

if (remove && Object.keys(root).length === 0) {
  unlinkSync(target);
  console.log(`cleaned Codex hooks: ${target} (removed empty file)`);
  process.exit(0);
}

writeFileSync(target, next, 'utf8');
console.log(`${remove ? 'cleaned' : 'merged'} Codex hooks: ${target}`);

function isEqual(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}
