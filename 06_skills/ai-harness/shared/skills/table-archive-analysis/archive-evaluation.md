# Archive Evaluation

Run Q1 to Q3 on every read path. Evaluate Q4 at the table level, then carry
that result into the final matrix and recommendation.

Before running the loop, pin down:
- proposed archive predicate, e.g. `create_time < DATE_SUB(CURDATE(), INTERVAL N DAY)`
- proposed retention window in days, if known
- whether the report is `preliminary` or `review-ready`

If the predicate or retention is missing, infer the best working assumption from
schema + query evidence, then mark the final recommendation as `preliminary`.

## What Q1 to Q4 Actually Mean

- Q1 asks whether the path is logically "latest state lookup" rather than
  "history lookup". The key question is not `LIMIT 1`; it is whether the query
  is intentionally fetching the newest row for a specific business key.
- Q2 asks whether the path only needs a recent time window, and whether that
  window matches the archive predicate. This is about lookback shape, not just
  "there is some date condition somewhere."
- Q3 asks whether losing old rows is acceptable to the business. This is the
  product / operational tolerance question: if old data disappears, does the
  feature still work acceptably?
- Q4 asks whether rows are stable before they would be archived. This is the
  table maturity question: can rows older than the cutoff still be updated,
  repaired, replayed, or reconciled?

## Q1 to Q4 Loop

```text
Q1: Does the path only need the current / latest record by design?
    Evidence should include an explicit business key plus an explicit latest-row
    selector such as ORDER BY create_time/id DESC LIMIT 1.
    YES -> usually low risk for this path, still record the evidence
    NO  -> Q2

Q2: Is the path bounded to a recent window that matches the archive dimension?
    The bound must align with the proposed archive condition, usually
    create_time, or have a proven tighter correlation.
    YES -> archive period >= max effective lookback?
           YES -> acceptable for this path
           NO  -> risk gap, archive rule or retention must change
    NO  -> Q3

Q3: If older rows disappear, is partial history acceptable to the business?
    Common examples: aggregate dashboards, trend summaries, approximate counts,
    or flows where only recent records are operationally relevant.
    YES -> acceptable only with explicit product / business sign-off
    NO  -> blocker for the current archive rule

Q4: Are rows stable before they become archive candidates?
    Ask whether old rows can still be updated, backfilled, replayed, or used by
    reconciliation after the proposed cutoff.
    YES -> write-once / mature-enough for archive
    NO  -> blocker or requires a different archive condition / longer retention
```

Notes:
- Q1 to Q3 are path-level questions.
- Q4 is table-level. Do not treat a single `UPDATE` keyword hit as an automatic
  blocker; inspect whether the update can affect rows older than the archive
  threshold.
- If a query is bounded by some other time field, document why that field is or
  is not compatible with a `create_time` archive rule.

## How to Analyze Each Question

Use this order for each read path:
1. read the mapper SQL or the exact generated query shape
2. map the caller path and identify what the feature is trying to return
3. answer Q1, then Q2, then Q3 with explicit evidence
4. answer Q4 once at the table level by reviewing writes / updates / replays

Do not answer from method names alone. Always anchor the judgment to SQL shape,
caller purpose, or write-path behavior.

### Q1 — Latest-State Lookup or Not

Look at:
- `WHERE` business keys such as `user_id`, `order_id`, `ticket_id`
- `ORDER BY ... DESC`
- `LIMIT 1`
- service-layer assumptions like "get latest", "last log", "current status"

Say `YES` only when both are true:
- there is an explicit business key or grouping key
- there is an explicit newest-row selector such as `ORDER BY create_time DESC LIMIT 1`

Typical `YES` evidence:
- `WHERE user_id = ? AND task_type = ? ORDER BY create_time DESC LIMIT 1`
- `SELECT MAX(id)` only if `id` is the real monotonic latest-row signal for the same business key

Typical `NO` evidence:
- `LIMIT 1` with no business key
- `ORDER BY` without proving the caller only needs the latest row
- open-ended list query where the caller happens to read the first row

Typical `UNKNOWN` cases:
- dynamic SQL hides ordering
- mapper method name says "latest" but the actual SQL is not inspected

### Q2 — Recent Window Matching the Archive Predicate or Not

Look at:
- time filters in SQL, e.g. `create_time >= ?`
- service parameters such as "last 7 days" or "today only"
- which time column the path actually depends on
- proposed archive dimension and retention, e.g. `create_time`, `N days`

Say `YES` only when both are true:
- the path is clearly bounded to a recent window
- that window matches the archive predicate or has a defensible tighter correlation

Typical `YES` evidence:
- query filters `create_time >= NOW() - INTERVAL 7 DAY`
- archive rule is `create_time < ... 30 DAY`, so 7-day lookback is safely inside retention

Typical `NO` evidence:
- no date bound at all
- bounded by `update_time` while archive is by `create_time` and correlation is unproven
- path needs 90 days while proposed archive cutoff is 30 days

Typical `UNKNOWN` cases:
- retention days are not known
- SQL receives opaque start/end parameters and caller behavior was not traced

### Q3 — Is Partial History Acceptable

Look at:
- what the controller / consumer returns to the business
- whether the path is user-visible detail, audit, reconciliation, export, or just summary / trend
- whether missing old rows causes wrong decisions, broken UX, or only lower historical completeness

Say `YES` only when partial history is genuinely acceptable and you can point to
the business purpose. This is usually `conditional`, not automatically safe.

Typical `YES` evidence:
- dashboard counts that only care about recent activity
- trend or aggregate features where some historical undercount is accepted
- operational monitoring screens that only look at near-term data

Typical `NO` evidence:
- dispute handling, audit, financial reconciliation, detailed history pages
- any path where older rows may still be shown, exported, or compared exactly

Typical `UNKNOWN` cases:
- technical path found, but feature purpose is still unclear
- no product / business expectation available

### Q4 — Are Old Rows Stable Enough to Archive

Look at:
- write paths for `INSERT`, `UPDATE`, retry, replay, compensation, MQ consume
- scheduled jobs or backfill jobs
- status transitions that may land long after row creation
- whether updates are limited to fresh rows or can hit arbitrarily old rows

Say `YES` only when you can defend that rows older than the cutoff are mature:
- insert-only table, or
- updates exist but are clearly limited to recent rows before the archive threshold

Typical `YES` evidence:
- append-only log table with no old-row mutation path
- delayed updates exist, but only within a short bounded SLA well inside retention

Typical `NO` evidence:
- backfill jobs can rewrite old rows
- MQ replay or reconciliation can repair arbitrarily old data
- status updates may arrive days or months later for old records

Typical `UNKNOWN` cases:
- `UPDATE` exists but target-row age cannot be determined
- write path is split across services and not fully traced yet

## Recommended Answer Shape

Record each answer as a short judgment plus evidence, for example:

```text
Path A
Q1: YES
Evidence: WHERE patron_id + ORDER BY create_time DESC LIMIT 1, caller only needs latest login state

Q2: NO
Evidence: no date bound; query can read arbitrary history

Q3: NO
Evidence: API returns detailed record history, not a summary

Q4: table-level NO
Evidence: reconciliation job updates old rows by order_no after settlement replay
```

If the evidence is weak, write `UNKNOWN` instead of forcing `YES` or `NO`.

## Outcome Labels

Use one of these labels in the matrix and final summary:
- `acceptable` — compatible with the current archive assumption
- `conditional` — acceptable only with explicit business sign-off or rule tweak
- `blocker` — incompatible with the current archive assumption
- `unknown` — missing evidence or missing archive assumptions

## Evaluation Matrix

Use this table in the report:

| 路徑 | Lookback / 維度 | Q1 | Q2 | Q3 | Q4 (table) | 結論 / 證據 |
|----|---------------|----|----|----|------------|---------|
| A  |               |    |    |    |            |         |

## Final Recommendation Format

Write the final recommendation as normal markdown, not inside a fenced code
block.

Use this structure:

### 最終建議

Confidence:
- `preliminary` or `review-ready`

Assumptions:
- `<archive predicate / inferred archive column / retention assumption>`

Archive Rule: `[x] Required / [ ] Not Required`

Condition:
- `create_time < DATE_SUB(CURDATE(), INTERVAL <N> DAY)`

idx_create_time:
- `✅ already exists` or `❌ add before review`

write-once:
- `✅ no UPDATE found`
- or `⚠️ UPDATE found — <details>`

風險項目:
- `<path>: <risk> -> <mitigation>`

Action items before DBA review:
- `[ ] <item>`

## Judgment Rules

- `LIMIT 1` by itself is not enough. Treat it as low risk only when the query
  clearly means "latest for this business key" rather than "some single row."
- A path that depends on open-ended history without date bounds is a blocker
  unless business acceptance is explicit.
- A bounded date filter is useful only when it matches the archive predicate or
  you can defend the correlation.
- A path bounded by `update_time`, `event_time`, or another field is a mismatch
  until you explain why that field is equivalent to the proposed archive
  predicate.
- Aggregate paths need product-level acceptance for undercount, missing
  historical rows, or trend drift.
- `idx_create_time` is mandatory if the archive condition depends on
  `create_time`.
- `UPDATE` does not automatically kill the proposal. The real question is
  whether rows older than the archive threshold can still change.
- Backfill, reconciliation, replay, and delayed status transitions are stronger
  negative signals than a generic `UPDATE` statement match.
- Missing predicate / retention assumptions should produce `unknown` or
  `conditional`, not an unconditional safe verdict.
- The final recommendation should read like a review note, not like pasted raw
  template text inside a code fence.
