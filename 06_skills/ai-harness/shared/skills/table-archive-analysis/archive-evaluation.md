# Archive Evaluation

Run the archive decision loop on every read path, then confirm write-once
status at the table level.

## Q1 to Q4 Loop

```text
Q1: Is every query LIMIT 1 (latest record only)?
    YES -> archive-safe for this path
    NO  -> Q2

Q2: Does the query filter by create_time or a bounded date range?
    YES -> archive period >= max query date span?
           YES -> acceptable
           NO  -> risk gap, record mitigation
    NO  -> Q3

Q3: Is it an aggregate query (COUNT / MAX / SUM)?
    YES -> undercount or missing data acceptable?
           YES -> low risk, still document
           NO  -> blocker
    NO  -> continue with path-specific reasoning

Q4: Any UPDATE found anywhere in discovery?
    YES -> not write-once, blocker before archive
    NO  -> write-once confirmed
```

## Evaluation Matrix

Use this table in the report:

| 路徑 | Q1 | Q2 | Q3 | Q4 | 結論 |
|----|----|----|----|----|----|
| A  |    |    |    |    |    |

## Final Recommendation Format

Write the final recommendation as normal markdown, not inside a fenced code
block.

Use this structure:

### 最終建議

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

- A path that reads only the latest row with `LIMIT 1` is usually archive-safe.
- A path that depends on open-ended history without date bounds is a blocker
  unless business acceptance is explicit.
- Aggregate paths need product-level acceptance for undercount or drift.
- `idx_create_time` is mandatory if the archive condition depends on
  `create_time`.
- Any `UPDATE` breaks the default write-once assumption and must be called out.
- The final recommendation should read like a review note, not like pasted raw
  template text inside a code fence.
