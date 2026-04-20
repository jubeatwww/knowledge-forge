---
name: table-archive-analysis
description: >-
  Analyze DB table dependency paths and archive-rule risk in the Sporty
  afbet_patron / service-patron codebase. Use when the user provides a `t_*`
  table and wants to map callers, generate dependency diagrams, evaluate an
  archive rule for DBA SOP review, or fill the Jira "1-2 Archive Rule"
  section.
---

# Table Archive Analysis

Produce a dependency-path and archive-review report for one DB table in the
Sporty `afbet_patron` / `service-patron` stack.

Use this skill when the task is operational and evidence-driven:
- expand every caller path from mapper to service to controller or consumer
- summarize DDL and index readiness for archive
- evaluate whether an archive rule is safe for DBA SOP review
- draft the Jira / SOP "1-2 Archive Rule" section

## Scope Guardrails

- This workflow is tuned for Sporty naming and repo layout:
  `service-patron/src/main/` and `service-patron/src/test/resources/db/migration/`.
- The skill name stays unprefixed for compatibility with the existing
  `~/.claude/skills/table-archive-analysis` install, but treat it as a
  work-specific skill.
- If the user does not provide a table name, stop and ask for it.
- If the repo layout or database naming differs, say so explicitly and treat
  this skill as a template rather than source-of-truth procedure.

## Inputs

Required:
- table name

Optional:
- Jira ticket URL
- existing archive rule in days
- Confluence SOP URL

Default SOP URL:
- `https://opennetltd.atlassian.net/wiki/spaces/DBA/pages/4252532749`

If Jira or Confluence links are available, extract scope, country, and database
name before starting the report.

## Workflow

1. Gather context and confirm the target table.
   Reference: `discovery-workflow.md`
2. Discover DDL, direct table references, and any `UPDATE` usage.
   Reference: `discovery-workflow.md`
3. Trace each mapper upward into service and controller or consumer call paths,
   then normalize every path into a path object.
   Reference: `discovery-workflow.md`
4. Spawn diagram subagents in one batch after the full path list is ready:
   one subagent for the overall diagram, plus one subagent per dependency
   path. Do not serialize these.
   Reference: `discovery-workflow.md`
5. Run the Q1 to Q4 archive evaluation loop for every read path and confirm
   write-once status.
   Reference: `archive-evaluation.md`
6. Assemble the final markdown report.
   Reference: `report-template.md`

## Output Contract

The final deliverable should contain:
- DDL summary with index confirmation
- one overall Mermaid overview diagram
- one per-path Mermaid diagram for each write or read path
- path-level explanation and field-touch summary
- archive evaluation matrix
- final DBA SOP recommendation block

## Rules

- Prefer `rg` over `grep` for discovery.
- Separate facts from inference. Mark guessed behavior clearly.
- Keep mapper, service, controller, MQ, and transactional side effects distinct.
- Default to subagent fan-out for diagram generation: 1 overall + 1 per path,
  all launched in the same turn after the path list is complete.
- Do not start diagram subagents before the path objects are complete.
- If the host truly lacks subagent capability, say that explicitly and only
  then fall back to sequential generation.
- For archive safety, reason from actual query shape, not naming guesses.
- Respond in the same language the user is writing in.
