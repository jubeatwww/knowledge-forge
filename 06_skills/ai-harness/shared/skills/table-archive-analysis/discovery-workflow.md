# Discovery Workflow

## 1. Gather Context

At minimum, capture the table name.

Recommended fields:

| Input                        | Required | Default                                                             |
|------------------------------|----------|---------------------------------------------------------------------|
| Table name                   | yes      | none                                                                |
| Jira ticket URL              | no       | none                                                                |
| Existing archive rule (days) | no       | none known                                                          |
| Confluence SOP URL           | no       | `https://opennetltd.atlassian.net/wiki/spaces/DBA/pages/4252532749` |

If Jira or Confluence URLs are provided, extract:
- scope
- country
- database name

## 2. Codebase Discovery

Replace `<TABLE>` with the actual table name.

```bash
# A — all Java files that reference the table
rg -l --glob '*.java' '<TABLE>' service-patron/src/main/

# B — DDL from migration files
rg -n -A 35 'CREATE TABLE `<TABLE>`' \
  service-patron/src/test/resources/db/migration/

# C — any UPDATE against the table
rg -n -i --glob '*.java' 'update.*<TABLE>' service-patron/src/main/
```

Record:
- DDL columns, types, comments
- primary key
- existing indexes
- mapper files that directly reference the table
- whether `idx_create_time` already exists
- whether any `UPDATE` was found

If the DDL snippet is too short, widen the migration read instead of guessing.

## 3. Trace the Call Chain

For each mapper class:

```bash
rg -l --glob '*.java' '<MapperClassName>' service-patron/src/main/
```

For each service class:

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
key_columns:      selected or inserted columns
where_cols:       WHERE clause columns
order_limit:      e.g. "ORDER create_time DESC LIMIT 1"
is_mq:            true if the write passes through RocketMQ
mq_producer:      producer class name if present
mq_topic:         topic constant if present
mq_consumer:      consumer class name if present
is_transactional: true if @Transactional wraps cross-table writes
side_effects:     additional table updates or writes, or "none"
db_role:          Master DB or Slave DB
```

## 4. Spawn All Diagram Subagents in One Turn

Once the full path list is complete, the intended workflow is:
- 1 subagent for the overall Mermaid overview
- 1 subagent per dependency path

Launch them **all at once in a single batch**. Do not wait between spawns, and
do not draw the per-path diagrams in the main thread unless the host genuinely
lacks subagent support.

Main thread responsibilities:
- finish DDL extraction
- finish mapper to service to entry tracing
- normalize all path objects
- fan out subagents
- collect returned Mermaid blocks
- assemble the final report

If the host genuinely lacks subagent capability:
- say so explicitly
- generate the same artifacts sequentially as a fallback

### Required Fan-out

- `Subagent A` — one overall Mermaid diagram using **all** path objects
- `Subagent B..N` — one Mermaid diagram per path, one subagent per path

### Overall Diagram Rules

- use `flowchart TD`
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
```

### Per-Path Diagram Rules

- use `flowchart TD` for write paths
- use `flowchart LR` for read paths
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
- Node labels use <br> for line breaks, not \n
- DB node: TABLE[("<TABLE_NAME>")]
- Write path with MQ: Entry -> Service -> PRODUCER["ProducerClass<br>send()"] --> MQ[["RocketMQ<br>TOPIC"]] --> CONSUMER["ConsumerClass"] --> SERVICE2["Service<br>flushLog()"] --> MAPPER["MapperClass<br>insert() ← Master DB"] --> TABLE
- For @Transactional with side effects: add dashed arrow `-.->` from tx node to the side-effect table node
- Annotate the last arrow into TABLE with SQL type and key fields, keep it short
- Master DB mapper label ends "← Master DB"
- Slave DB mapper label ends "← Slave DB"
- Max 4 lines per node label

Output: only the mermaid code block, nothing else.
```

## 5. Field-Touch Summary

For each path, keep a compact summary of:
- touched columns
- WHERE columns
- ordering / limit behavior
- side effects
- consumer-visible purpose
