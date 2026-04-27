# SPLT-679 Context

## Ticket

- Jira: [SPLT-679](https://opennetltd.atlassian.net/browse/SPLT-679)
- Summary: `BE - Review and add the archiving rules following 4 tables in the afbet_patron`
- Project: `SPlatform-TW (SPLT)`
- Type: `Task`
- Status: `進行中`
- Reporter: `Vincent Huang`
- Assignee: `Justin Lin`
- Created: `2026-04-15 15:08 +08:00`
- Updated: `2026-04-23 16:11 +08:00`

## Why This Folder Exists

This folder is the local working set for the backend review requested in
`SPLT-679`: determine whether four table-level archive rules are safe from the
current `service-patron` code path and query-shape perspective.

The Jira description already contains a condensed verdict for each table. The
four markdown files in this folder are the expanded local reports behind that
description, intended to preserve the code-trace evidence, risk analysis, and
DBA-review context before the material is refined into longer-term knowledge.

## Scope

Target tables covered by the ticket:

| Table | Local report | Current verdict |
|---|---|---|
| `t_patron_cipher` | [t_patron_cipher_archive_report.md](./t_patron_cipher_archive_report.md) | Not recommended for archive under current design |
| `t_patron_user_operation_log` | [t_patron_user_operation_log_archive_report.md](./t_patron_user_operation_log_archive_report.md) | Keep current rule: `create_time < DATE_SUB(CURDATE(), INTERVAL 179 DAY)` |
| `t_base_trans_cipher` | [t_base_trans_cipher_archive_report.md](./t_base_trans_cipher_archive_report.md) | Archivable on `update_time`, but blocked on caller-side confirmation |
| `t_patron_user_trusted_device` | [t_patron_user_trusted_device_archive_report.md](./t_patron_user_trusted_device_archive_report.md) | Not recommended for archive until 3 preconditions are met |

Scope note:
- The ticket is framed as "4 tables in the `afbet_patron`", but the
  `t_base_trans_cipher` report notes a migration pointing to
  `afbet_main.t_base_trans_cipher`. That schema discrepancy should be preserved
  when this is later moved into curated knowledge.

## Ticket-Level Outcome

### Final table-by-table judgment

| Table | Archive Rule Status | Recommended Dimension | Main blocker / reason |
|---|---|---|---|
| `t_patron_cipher` | `Not safe now` | None | `ursId` continuity and `/ms/cipher` lookup can break after archival; `update_time` and blank `user_id` are not reliable inactivity signals |
| `t_patron_user_operation_log` | `Keep current rule` | `create_time` | No hard BE blocker; remaining issues are semantics / business sign-off on a few unbounded reads |
| `t_base_trans_cipher` | `Conditionally safe` | `update_time` | Need confirmation that `/ms/bizCipher` callers can tolerate `null` and trigger re-registration |
| `t_patron_user_trusted_device` | `Not safe now` | `create_time` only if reworked | Unbounded cross-user device ownership check depends on retained history |

### Shared decision criteria used across the 4 reviews

- Archive safety was judged from actual query shape and row lifecycle, not from
  column naming alone.
- Existing indexes only answer "can DBA execute the purge efficiently"; they do
  not answer "is the predicate semantically safe".
- "Has a time column" is not enough. The chosen archive dimension must reflect
  real inactivity semantics in current code.
- "Missing row behavior" matters. If reads silently return `null` or empty, the
  archive decision depends on whether upstream callers can recover correctly.
- Unbounded historical lookups are the main reason a table remains
  non-archivable even when the table is append-only or operationally stable.

## What Was Added To Jira Description

The Jira description now contains, for each table:

- a short verdict
- the minimum reasons needed for reviewer scanability
- the current suggested next step or re-evaluation condition

That description is the short executive summary. The local markdown reports are
the evidence pack.

## Open Questions And Follow-ups

### `t_patron_cipher`

- Clarify whether `ursId` has a defined TTL, revoke flow, or explicit expiry
  contract anywhere outside this repo.
- Revisit archive only if row validity becomes explicitly bounded, or if the
  read/write contract is changed to tolerate re-issued identifiers.

### `t_patron_user_operation_log`

- Get product / risk-owner sign-off that losing `>179`-day-old device history is
  acceptable for the unbounded device-lookup paths.
- Clarify whether BO-facing "last login" style endpoints should really be
  login-only semantics or are acceptable as operation-log views.

### `t_base_trans_cipher`

- Confirm with the caller team of `/ms/bizCipher` whether `200 { data: null }`
  causes a fresh `POST /base/cipher` registration.
- If callers do not auto-recover, retention must cover the longest dormancy
  window between device re-registrations.

### `t_patron_user_trusted_device`

- Business: decide whether the cross-user device ownership check should remain
  unbounded or become time-bounded.
- Backend: confirm the effective runtime ceiling for
  `trusted.device.config.keepRecordForXDays`, not only the code fallback.
- DBA: add standalone `idx_create_time` before considering any range purge on
  this table.

## Recommended Knowledge-Base Split

When this inbox package is refined into curated notes, the cleanest split is:

1. One hub / overview note for `SPLT-679` as the cross-table archive review.
2. One permanent note per table for the archive verdict and reasoning.
3. One reusable playbook / pattern note for archive-rule review heuristics:
   query shape, row lifecycle, caller recovery, and index readiness.

## Related Files

- [t_patron_cipher_archive_report.md](./t_patron_cipher_archive_report.md)
- [t_patron_user_operation_log_archive_report.md](./t_patron_user_operation_log_archive_report.md)
- [t_base_trans_cipher_archive_report.md](./t_base_trans_cipher_archive_report.md)
- [t_patron_user_trusted_device_archive_report.md](./t_patron_user_trusted_device_archive_report.md)
