#!/usr/bin/env node
//
// Cross-platform sound player shared by Claude, Codex, and Copilot CLI hooks.
// Claude install mode:
//   ~/.claude/hooks/play-sound.mjs   (this file)
//   ~/.claude/hooks/play-sound.ps1   (Windows helper)
//   ~/.claude/audio/*.mp3            (sound files)
// Codex install mode:
//   ~/.codex/hooks/play-sound.mjs   (this file)
//   ~/.codex/audio/*.mp3            (sound files)
// Copilot CLI install mode:
//   ~/.copilot/hooks/play-sound.mjs  (this file)
//   ~/.copilot/hooks/play-sound.ps1  (Windows helper)
//   ~/.copilot/audio/*.mp3           (sound files)
// Dev fallback mode:
//   <repo>/06_skills/ai-harness/claude/hooks/play-sound.mjs
//   AI_HARNESS_AUDIO_DIR=<repo>/06_skills/ai-harness/audio
//
// Invocation: node play-sound.mjs <event>
//   events: permission | stop | subagent_start | subagent_stop | session_end |
//           post_tool_failure | stop_failure | task_completed |
//           notify | session_start | post_tool_use
//
// `post_tool_use` is the Codex/Copilot alias for post-hook payloads; it only
// plays on failure-like payloads.

import { spawn } from 'node:child_process';
import { platform, homedir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { existsSync } from 'node:fs';

const EVENT = process.argv[2];
const __dirname = dirname(fileURLToPath(import.meta.url));
const CLAUDE_SOUND_DIR = join(homedir(), '.claude', 'audio');
const CODEX_SOUND_DIR = join(homedir(), '.codex', 'audio');
const COPILOT_SOUND_DIR = join(homedir(), '.copilot', 'audio');
const SOUND_DIR =
  process.env.AI_HARNESS_AUDIO_DIR ||
  (existsSync(CLAUDE_SOUND_DIR)
    ? CLAUDE_SOUND_DIR
    : existsSync(CODEX_SOUND_DIR)
      ? CODEX_SOUND_DIR
      : existsSync(COPILOT_SOUND_DIR)
        ? COPILOT_SOUND_DIR
        : join(__dirname, '..', '..', 'audio'));

const SOUND_MAP = {
  permission:        'megumin_explosion.mp3',
  stop:              'pain_itami_o_kanjiro.mp3',
  subagent_start:    'za_warudo.mp3',
  subagent_stop:     'road_roller_da.mp3',
  session_end:       'to_be_continued.mp3',
  post_tool_failure: 'sukuna_domain.mp3',
  stop_failure:      'saber_excalibur.mp3',
  task_completed:    'gojo_domain.mp3',
  notify:            'gojo_domain.mp3',
  session_start:     'nico_nico_nii.mp3',
};

const input = await readJsonFromStdin();
const resolvedEvent = resolveEvent(EVENT, input);
const file = resolvedEvent ? SOUND_MAP[resolvedEvent] : null;
if (!file) process.exit(0);

const soundPath = join(SOUND_DIR, file);
if (!existsSync(soundPath)) {
  console.error(`[hook] sound not found: ${soundPath}`);
  process.exit(0);
}

if (process.env.CODEX_SOUND_DEBUG === '1') {
  console.error(`[hook] event=${resolvedEvent} sound=${soundPath}`);
}

if (process.env.CODEX_SOUND_DRY_RUN === '1') {
  process.exit(0);
}

function fire(cmd, args) {
  // async: true on the hook side means Claude Code won't block on us; we still
  // want to wait for the player so the sound actually plays before we exit.
  spawn(cmd, args, { stdio: 'ignore', windowsHide: true });
}

const os = platform();

if (os === 'darwin') {
  fire('afplay', [soundPath]);
} else if (os === 'win32') {
  const ps1 = join(__dirname, 'play-sound.ps1');
  fire('powershell.exe', [
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', ps1,
    '-Path', soundPath,
  ]);
} else {
  for (const [cmd, args] of [
    ['paplay', [soundPath]],
    ['ffplay', ['-nodisp', '-autoexit', '-loglevel', 'quiet', soundPath]],
  ]) {
    try { fire(cmd, args); break; } catch {}
  }
}

function resolveEvent(event, payload) {
  if (event === 'post_tool_use') {
    return hasToolFailure(payload) ? 'post_tool_failure' : null;
  }
  return event;
}

function hasToolFailure(payload) {
  if (!payload || typeof payload !== 'object') return false;

  for (const value of [
    payload.tool_response,
    payload.toolResponse,
    payload.tool_output,
    payload.toolOutput,
  ]) {
    if (isFailurePayload(unwrapJson(value))) return true;
  }

  return false;
}

function isFailurePayload(value) {
  if (!value || typeof value !== 'object') return false;

  for (const key of ['exit_code', 'exitCode', 'statusCode', 'code']) {
    const code = value[key];
    if (typeof code === 'number') return code !== 0;
    if (typeof code === 'string' && code.trim() !== '' && !Number.isNaN(Number(code))) {
      return Number(code) !== 0;
    }
  }

  if (value.success === false || value.ok === false) return true;

  if (typeof value.status === 'string') {
    return ['error', 'failed', 'failure'].includes(value.status.toLowerCase());
  }

  return false;
}

function unwrapJson(value) {
  if (typeof value !== 'string') return value;
  const trimmed = value.trim();
  if (!trimmed) return null;

  try {
    return JSON.parse(trimmed);
  } catch {
    return null;
  }
}

async function readJsonFromStdin() {
  if (process.stdin.isTTY) return null;

  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
  }

  if (chunks.length === 0) return null;
  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}
