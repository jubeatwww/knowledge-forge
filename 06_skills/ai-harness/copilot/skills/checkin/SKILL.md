---
name: checkin
description: >-
  Append today's free-form log entry to the Knowledge Forge vault's
  00_inbox/checkin-<date>.md. Use when the user says "checkin", "check in",
  "log entry", or wants to record what they did today.
---

# Check-in

Append the user's input to the Knowledge Forge vault's daily check-in file.
Allow a small number of clarifying questions to help the user add enough
context for future readability.

## Vault Resolution (mandatory first step)

This skill only works inside the Knowledge Forge vault. From the cwd, look
upward for a directory that simultaneously contains `AGENTS.md`, `00_inbox/`,
`90_cache/`, and `02_sources/`.

- Found → use that path as the write root.
- Not found → report `not inside Knowledge Forge vault — cd into it first`
  and stop. Do not write anything.

## Steps

1. Resolve the vault root (see above).
2. Check input completeness; decide whether to ask questions (see Clarification
   Policy below).
3. If needed, ask 1–2 precise questions and wait for answers before writing.
4. Get today's date (absolute date `YYYY-MM-DD`).
5. Target file: `<vault-root>/00_inbox/checkin-<YYYY-MM-DD>.md`
6. Check whether the file exists:
   - Does not exist: create it with frontmatter + first entry.
   - Already exists: append to the end without modifying frontmatter.
7. Entry format:
   ```
   ## <HH:MM>
   <consolidated content>
   ```
   24-hour clock, local time.
8. Frontmatter (new files only):
   ```yaml
   ---
   title: Check-in <YYYY-MM-DD>
   kind: checkin
   date: <YYYY-MM-DD>
   ---
   ```

## Clarification Policy

**Goal**: avoid entries that are incomprehensible three months later. But don't
turn a quick capture into an interview.

**Ask when**:
- Pronouns with no referent ("that bug", "that PR", "he")
- Events with no outcome ("debugged a bit", "read the docs")
- Emotion/judgment with no cause ("today was chaotic", "feeling stuck")
- Tasks/deliverables without a name ("pushed a PR", "opened a ticket")

**Don't ask when**:
- Input is already self-contained → save directly.
- User is clearly doing a brain dump (long, detailed input) → save directly.
- Already asked 2 questions → stop, write with what you have.

**How**: one question at a time, concise, no explanation of why you're asking.

## Writing Rules

- Consolidate the user's original text + answers into a coherent entry,
  preserving the user's voice (don't over-edit, don't translate).
- Do **not** proactively refine into `03_notes/` or `04_playbooks/`. This
  skill only captures. Refinement is handled by weekly-refine or explicit
  user request.
- After writing, report: file path + timestamp. Don't paste the full entry.
- Empty input → error: `checkin <content>`.
