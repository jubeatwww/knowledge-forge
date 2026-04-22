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
- proposed archive condition / column
- existing archive rule in days
- Confluence SOP URL

Default SOP URL:
- `https://opennetltd.atlassian.net/wiki/spaces/DBA/pages/4252532749`

If Jira or Confluence links are available, extract scope, country, and database
name before starting the report.

If the archive condition or retention window is missing, define a working
assumption explicitly before analysis and mark the report as preliminary until
that assumption is confirmed.

## Workflow

1. Gather context and confirm the target table.
   Reference: `discovery-workflow.md`
2. Discover DDL, direct table references, and any `UPDATE` usage using the
   most effective local inspection method for the host and repo.
   Reference: `discovery-workflow.md`
3. Trace each mapper upward into service and controller or consumer call paths,
   then normalize every path into a path object.
   Reference: `discovery-workflow.md`
4. Generate diagrams after the full path list is ready. Prefer fan-out:
   one overall diagram plus one per dependency path in a single batch. If the
   current host / policy requires explicit user approval for delegation, obtain
   that first; otherwise fall back to local generation.
   Reference: `discovery-workflow.md`
5. Run Q1 to Q3 for every read path, then evaluate Q4 at the table level to
   confirm whether archived candidates are already stable.
   Reference: `archive-evaluation.md`
6. Assemble the final markdown report.
   Reference: `report-template.md`

## Output Contract

The final deliverable should contain:
- DDL summary with index confirmation
- assumptions / confidence block when archive condition or retention is inferred
- blocker / risk summary before the long per-path detail
- one overall Mermaid overview diagram
- one per-path Mermaid diagram for each write or read path
- path-level explanation and field-touch summary
- archive evaluation matrix
- final DBA SOP recommendation block
  This must be rendered as normal markdown, not wrapped in a generic code block.

## Rules

- Treat command snippets in referenced docs as examples, not mandatory
  incantations.
- Prefer fast, reliable local inspection methods such as `rg`, IDE symbol
  search, repo-aware search, or targeted file reads. Choose the tool that gets
  to evidence fastest on the current host.
- Separate facts from inference. Mark guessed behavior clearly.
- Keep mapper, service, controller, MQ, and transactional side effects distinct.
- If archive dimension or retention is unknown, state the working assumption and
  avoid a hard "safe" verdict.
- Prefer subagent fan-out for diagram generation when the current host / policy
  allows delegation.
- If the current host requires explicit user approval before delegation, obtain
  that first; otherwise generate diagrams locally.
- If delegated diagram generation is used, wait until the path objects are
  complete, then launch 1 overall + 1 per path in the same turn.
- For Mermaid, strongly prefer `flowchart` because the dependency paths are
  easier to scan that way. Do not use `sequenceDiagram` unless the user
  explicitly asks for it.
- For archive safety, reason from actual query shape, not naming guesses.
- Summarize repetitive low-risk paths compactly. Spend detail on blockers,
  write paths, and any path that challenges the archive predicate.
- The final recommendation section must be normal markdown prose / bullets /
  checklist content, not a fenced `text` or `markdown` block.
- Respond in the same language the user is writing in.
