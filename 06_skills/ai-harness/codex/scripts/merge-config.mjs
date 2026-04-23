#!/usr/bin/env node

import { existsSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const remove = args.find((arg) => arg.startsWith('--remove:'));
const target = remove ? remove.slice('--remove:'.length) : args.find((arg) => !arg.startsWith('--'));

if (!target) {
  console.error('usage: merge-config.mjs [--dry-run] <target> | --remove:<target>');
  process.exit(2);
}

const notifyBegin = '# ai-harness:begin notify';
const notifyEnd = '# ai-harness:end notify';
const hooksBegin = '# ai-harness:begin codex_hooks';
const hooksEnd = '# ai-harness:end codex_hooks';
const statusBegin = '# ai-harness:begin status_line';
const statusEnd = '# ai-harness:end status_line';

const notifyBlock = [
  notifyBegin,
  'notify = [',
  '  "/bin/sh",',
  '  "-lc",',
  '  "NODE_BIN=\\"$(cat \\"$HOME/.codex/ai-harness-node-path.txt\\" 2>/dev/null || true)\\"; if [ -z \\"$NODE_BIN\\" ]; then NODE_BIN=\\"$(command -v node 2>/dev/null || true)\\"; fi; [ -n \\"$NODE_BIN\\" ] || exit 0; \\"$NODE_BIN\\" \\"$HOME/.codex/hooks/play-sound.mjs\\" notify",',
  ']',
  notifyEnd,
];

const codexHooksBlock = [
  hooksBegin,
  'codex_hooks = true',
  hooksEnd,
];

const statusLineBlock = [
  statusBegin,
  'status_line = [',
  '  "project-root",',
  '  "git-branch",',
  '  "model-with-reasoning",',
  '  "five-hour-limit",',
  '  "weekly-limit",',
  '  "context-usage",',
  ']',
  statusEnd,
];

const targetExists = existsSync(target);
if (remove && !targetExists) {
  if (dryRun) {
    console.log(`DRY: clean Codex config at ${target} (target missing)`);
  } else {
    console.log(`skip Codex config cleanup: ${target} does not exist`);
  }
  process.exit(0);
}

const initial = targetExists ? readFileSync(target, 'utf8') : '';
const content = initial.replace(/\r\n/g, '\n');
const parsed = parseTomlSections(content);

stripManagedBlock(parsed.root, notifyBegin, notifyEnd);
const features = getOrCreateSection(parsed.sections, 'features');
const tui = getOrCreateSection(parsed.sections, 'tui');
stripManagedBlock(features.lines, hooksBegin, hooksEnd);
stripManagedBlock(tui.lines, statusBegin, statusEnd);

if (!remove) {
  if (hasKey(parsed.root, /^notify\s*=/)) {
    console.error('skip Codex notify merge: unmanaged notify already exists in ~/.codex/config.toml');
  } else {
    appendBlock(parsed.root, notifyBlock);
  }

  if (hasKey(features.lines, /^codex_hooks\s*=/)) {
    if (!hasExactLine(features.lines, 'codex_hooks = true')) {
      console.error('skip Codex hooks toggle merge: unmanaged features.codex_hooks already exists');
    }
  } else {
    appendBlock(features.lines, codexHooksBlock);
  }

  if (hasKey(tui.lines, /^status_line\s*=/)) {
    console.error('skip Codex status line merge: unmanaged tui.status_line already exists');
  } else {
    appendBlock(tui.lines, statusLineBlock);
  }
}

const next = serializeToml(parsed.root, parsed.sections);
if (dryRun) {
  console.log(`DRY: ${remove ? 'clean' : 'merge'} Codex config at ${target}`);
  process.exit(0);
}

if (remove && next === '') {
  unlinkSync(target);
  console.log(`cleaned Codex config: ${target} (removed empty file)`);
  process.exit(0);
}

writeFileSync(target, next, 'utf8');
console.log(`${remove ? 'cleaned' : 'merged'} Codex config: ${target}`);

function parseTomlSections(raw) {
  const root = [];
  const sections = [];
  let current = root;

  for (const line of raw.split('\n')) {
    const header = line.match(/^\s*\[([^\]]+)\]\s*$/);
    if (header) {
      const section = { name: header[1], header: line.trim(), lines: [] };
      sections.push(section);
      current = section.lines;
      continue;
    }
    current.push(line);
  }

  return { root, sections };
}

function getOrCreateSection(sections, name) {
  let section = sections.find((item) => item.name === name);
  if (!section) {
    section = { name, header: `[${name}]`, lines: [] };
    sections.push(section);
  }
  return section;
}

function stripManagedBlock(lines, begin, end) {
  let skipping = false;
  let idx = 0;
  while (idx < lines.length) {
    if (lines[idx].trim() === begin) {
      skipping = true;
      lines.splice(idx, 1);
      continue;
    }
    if (skipping) {
      const line = lines[idx];
      lines.splice(idx, 1);
      if (line.trim() === end) {
        skipping = false;
      }
      continue;
    }
    idx++;
  }
  trimBlankEdges(lines);
}

function appendBlock(lines, block) {
  trimBlankEdges(lines);
  if (lines.length > 0) {
    lines.push('');
  }
  lines.push(...block);
}

function trimBlankEdges(lines) {
  while (lines.length > 0 && lines[0].trim() === '') {
    lines.shift();
  }
  while (lines.length > 0 && lines.at(-1).trim() === '') {
    lines.pop();
  }
}

function hasKey(lines, pattern) {
  return lines.some((line) => pattern.test(line.trim()));
}

function hasExactLine(lines, expected) {
  return lines.some((line) => line.trim() === expected);
}

function serializeToml(rootLines, sections) {
  const parts = [];
  const normalizedRoot = [...rootLines];
  trimBlankEdges(normalizedRoot);
  if (normalizedRoot.length > 0) {
    parts.push(normalizedRoot.join('\n'));
  }

  for (const section of sections) {
    const sectionLines = [...section.lines];
    trimBlankEdges(sectionLines);
    if (sectionLines.length === 0) {
      continue;
    }
    parts.push([section.header, ...sectionLines].join('\n'));
  }

  if (parts.length === 0) {
    return '';
  }
  return `${parts.join('\n\n')}\n`;
}
