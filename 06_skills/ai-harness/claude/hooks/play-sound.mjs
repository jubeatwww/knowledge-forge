#!/usr/bin/env node
//
// Cross-platform sound player for Claude Code hooks.
// Audio + script are installed by sync.sh/sync.ps1 into ~/.claude/:
//   ~/.claude/hooks/play-sound.mjs   (this file)
//   ~/.claude/hooks/play-sound.ps1   (Windows helper)
//   ~/.claude/audio/*.mp3            (sound files)
// The audio dir is resolved via $HOME (os.homedir) so copy/symlink install
// modes and any working directory behave the same.
//
// Invocation: node play-sound.mjs <event>
//   events: permission | stop | subagent_start | subagent_stop | session_end |
//           post_tool_failure | stop_failure | task_completed

import { spawn } from 'node:child_process';
import { platform, homedir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { existsSync } from 'node:fs';

const EVENT = process.argv[2];
const __dirname = dirname(fileURLToPath(import.meta.url));
const SOUND_DIR = join(homedir(), '.claude', 'audio');

const SOUND_MAP = {
  permission:        'megumin_explosion.mp3',
  stop:              'pain_itami_o_kanjiro.mp3',
  subagent_start:    'nico_nico_nii.mp3',
  subagent_stop:     'za_warudo.mp3',
  session_end:       'to_be_continued.mp3',
  post_tool_failure: 'sukuna_domain.mp3',
  stop_failure:      'saber_excalibur.mp3',
  task_completed:    'gojo_domain.mp3',
};

const file = SOUND_MAP[EVENT];
if (!file) process.exit(0);

const soundPath = join(SOUND_DIR, file);
if (!existsSync(soundPath)) {
  console.error(`[hook] sound not found: ${soundPath}`);
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