# Discovery Workflow

## 1. Gather Context

At minimum, capture the table name.

Recommended fields:

| Input                        | Required | Default                                                             |
|------------------------------|----------|---------------------------------------------------------------------|
| Table name                   | yes      | none                                                                |
| Jira ticket URL              | no       | none                                                                |
| Archive condition / column   | no       | none                                                                |
| Existing archive rule (days) | no       | none known                                                          |
| Confluence SOP URL           | no       | `https://opennetltd.atlassian.net/wiki/spaces/DBA/pages/4252532749` |

If Jira or Confluence URLs are provided, extract:
- scope
- country
- database name

If archive condition / column or retention days are missing:
- define a working assumption before evaluating any path
- carry that assumption into the final report
- label the final recommendation as `preliminary` until confirmed

## 2. Codebase Discovery

Use the fastest reliable local method to gather evidence for the target table.
The shell snippets below are examples, not required commands. If another tool
is more effective on the current host, use it.

Replace `<TABLE>` with the actual table name if you reuse the examples below.

```bash
# Example A — all Java files that reference the table
rg -l --glob '*.java' '<TABLE>' service-patron/src/main/

# Example B — DDL from migration files
rg -n -A 35 'CREATE TABLE `<TABLE>`' \
  service-patron/src/test/resources/db/migration/

# Example C — any UPDATE against the table
rg -n -i --glob '*.java' 'update.*<TABLE>' service-patron/src/main/
```

Record:
- DDL columns, types, comments
- primary key
- existing indexes
- mapper files that directly reference the table
- whether `idx_create_time` already exists
- whether any `UPDATE` was found
- which time column is the best archive candidate from the actual schema / SQL

If the DDL snippet is too short, widen the migration read instead of guessing.

## 3. Trace the Call Chain

Use any dependable code-navigation method to trace mapper -> service ->
controller / consumer paths. The examples below are optional.

For each mapper class, for example:

```bash
rg -l --glob '*.java' '<MapperClassName>' service-patron/src/main/
```

For each service class, for example:

```bash
rg -l --glob '*.java' '<ServiceClassName>' service-patron/src/main/
```

Read the relevant files and emit one path object per public flow touching the
table.

```text
path_id:          e.g. "Write", "A", "B1"
path_name:        human-readable path name
entry_point:      controller endpoint, handler, or scheduled entry
service:          ServiceClass.method()
mapper:           MapperClass.method()
sql_type:         INSERT / SELECT / SELECT DISTINCT / SELECT COUNT / SELECT MAX
business_key:     business key proving "latest for X" semantics, or "none"
key_columns:      selected or inserted columns
where_cols:       WHERE clause columns
order_limit:      e.g. "ORDER create_time DESC LIMIT 1"
archive_dimension: the time field this path actually depends on, or "none"
effective_lookback: latest-only / bounded window / unbounded
history_requirement: latest-only / recent-window / partial-history-ok / full-history
is_mq:            true if the write passes through RocketMQ
mq_producer:      producer class name if present
mq_topic:         topic constant if present
mq_consumer:      consumer class name if present
is_transactional: true if @Transactional wraps cross-table writes
side_effects:     additional table updates or writes, or "none"
stability_risk:   replay / reconciliation / delayed-update / backfill / none / unknown
evidence:         short SQL or code cue supporting the judgment
db_role:          Master DB or Slave DB
```

## 4. Generate Diagrams After Path Objects Are Complete

Once the full path list is complete, choose the generation mode:
- preferred: launch 1 overall diagram plus 1 per dependency path in parallel
- fallback: draw the Mermaid diagrams in the main thread if the current host
  lacks subagent support or its policy requires delegation approval that has
  not been obtained

If delegated generation is used, launch the diagram workers **all at once in a
single batch**. Do not wait between spawns.

Main thread responsibilities:
- finish DDL extraction
- finish mapper to service to entry tracing
- normalize all path objects
- decide whether delegation is actually allowed under the current host / policy
- fan out workers when delegation is allowed
- collect returned Mermaid blocks if delegation is used
- assemble the final report

If delegation is unavailable:
- say so explicitly if host policy blocks delegation or subagents are missing
- generate the diagrams locally as the default path

### Optional Delegated Fan-out

- `Subagent A` — one overall Mermaid diagram using **all** path objects
- `Subagent B..N` — one Mermaid diagram per path, one subagent per path

### Overall Diagram Rules

- use `flowchart TD`
- do **not** use `sequenceDiagram`, `graph`, `stateDiagram`, `journey`, or any Mermaid type other than `flowchart`
- central DB node: `TABLE[("t_table_name")]`
- group write paths under `✏️ 寫入路徑`
- group read paths under `📖 讀取路徑 X — <name>`
- path shape: `EntryPoint -> Service -> Mapper -> TABLE`
- MQ write shape: `EntryPoint -> Service -> MQ -> Consumer -> Mapper -> TABLE`
- annotate the final edge with SQL type
- mapper labels end with `← Master DB` or `← Slave DB`

### Overall Diagram Prompt

```text
Generate a single Mermaid overview diagram showing ALL call paths for table <TABLE_NAME>.

The diagram must:
- Use `flowchart TD`
- Do **not** use `sequenceDiagram`; this report standard is always `flowchart`
- Node labels use <br> for line breaks, not \n
- Place the DB table as the central destination: TABLE[("<TABLE_NAME>")]
- Group write-path nodes in a subgraph labeled "✏️ 寫入路徑"
- Group read-path nodes in subgraphs labeled "📖 讀取路徑 X — <name>" (one subgraph per path)
- Show each path as: EntryPoint -> Service -> Mapper -> TABLE
- For write paths with MQ: EntryPoint -> Service -> MQ[["RocketMQ<br>TOPIC"]] -> Consumer -> Mapper -> TABLE
- Annotate the final arrow into TABLE with SQL type
- Master DB mappers: label ends "← Master DB"
- Slave DB mappers: label ends "← Slave DB"

Paths to include:
<paste all path objects here>

Output: only the mermaid code block, nothing else.
If you catch yourself producing `sequenceDiagram`, discard it and regenerate as `flowchart TD`.
```

### Per-Path Diagram Rules

- use `flowchart TD` for write paths
- use `flowchart LR` for read paths
- do **not** use `sequenceDiagram`, even for MQ / async paths
- use `<br>` for line breaks, never `\n`
- keep node labels to four lines or fewer
- for `@Transactional` side effects, draw dashed arrows to side-effect tables
- annotate the final edge with SQL type plus key fields

### Per-Path Diagram Prompt

```text
Generate a single Mermaid flowchart for ONE DB call path.

Path details:
  name: <PATH_NAME>
  entry: <ENTRY_CLASS>.<METHOD_OR_ENDPOINT>
  service: <SERVICE_CLASS>.<METHOD>
  mapper: <MAPPER_CLASS>.<METHOD>
  db: <TABLE_NAME>
  sql_type: <INSERT|SELECT|...>
  key_columns: <comma-separated>
  where_cols: <comma-separated>
  order_limit: <e.g. "ORDER create_time DESC LIMIT 1">
  is_mq: <true|false>
  mq_producer / mq_topic / mq_consumer: <if is_mq>
  is_transactional: <true|false>
  side_effects: <e.g. "also updates t_patron_user.last_login_time" or "none">

Rules:
- Use `flowchart LR` for read paths, `flowchart TD` for write paths
- Do **not** use `sequenceDiagram`; convert every path into a `flowchart`
- Node labels use <br> for line breaks, not \n
- DB node: TABLE[("<TABLE_NAME>")]
- Write path with MQ: Entry -> Service -> PRODUCER["ProducerClass<br>send()"] --> MQ[["RocketMQ<br>TOPIC"]] --> CONSUMER["ConsumerClass"] --> SERVICE2["Service<br>flushLog()"] --> MAPPER["MapperClass<br>insert() ← Master DB"] --> TABLE
- For @Transactional with side effects: add dashed arrow `-.->` from tx node to the side-effect table node
- Annotate the last arrow into TABLE with SQL type and key fields, keep it short
- Master DB mapper label ends "← Master DB"
- Slave DB mapper label ends "← Slave DB"
- Max 4 lines per node label

Output: only the mermaid code block, nothing else.
If the first draft comes out as `sequenceDiagram`, regenerate it as the required `flowchart`.
```

## 5. Field-Touch Summary

For each path, keep a compact summary of:
- touched columns
- WHERE columns
- ordering / limit behavior
- effective lookback and archive-dimension match
- side effects
- consumer-visible purpose
