# Discovery Workflow

## §1 — Gather Context

At minimum, capture the target symbol and confirm scope before searching.

| Input        | Required | Default              |
|--------------|----------|----------------------|
| target       | yes      | none                 |
| scope        | no       | repo root            |
| direction    | no       | `callers`            |
| depth        | no       | unlimited            |
| output path  | ask      | none                 |

Restate the understood parameters to the user before Phase 2.

If the target is a class method, confirm the exact signature or class name to
avoid ambiguous grep matches.

---

## §2 — Shallow Discovery

Use the fastest reliable method to find all direct references within scope.
The examples below use `rg` (ripgrep), but any tool that gets to evidence
fastest on the current host is acceptable.

```bash
# All files that mention the symbol
rg -l '<target>' <scope>

# All call sites with context
rg -n --context 3 '<target>' <scope>

# Narrow to specific extension
rg -l --glob '*.java' '<target>' <scope>
rg -l --glob '*.py'   '<target>' <scope>
rg -l --glob '*.ts'   '<target>' <scope>
```

Record for each direct reference:
- file path
- line number
- how it's used (call site, import, annotation, config, test)
- which layer it appears to belong to (heuristic from file path / class name)

Group the references by layer:

| Layer tag     | Heuristic signals                                    |
|---------------|------------------------------------------------------|
| `api`         | `Controller`, `Router`, `Route`, `Resource`, `Rest`  |
| `service`     | `Service`, `UseCase`, `Manager`, `Facade`            |
| `repository`  | `Repo`, `Repository`, `Dao`, `Mapper`, `Store`       |
| `handler`     | `Handler`, `Processor`, `Consumer`, `Listener`       |
| `scheduler`   | `Job`, `Task`, `Scheduled`, `Cron`                   |
| `middleware`  | `Middleware`, `Filter`, `Interceptor`, `Guard`       |
| `test`        | `Test`, `Spec`, `Mock`, `Fixture`                    |
| `util`        | `Util`, `Helper`, `Utils`                            |

If no layer can be inferred, tag as `unknown`.

---

## §3 — Deep Trace and Path Objects

For each caller identified in §2, trace upward to find its entry point (for
direction=callers). For callees, trace downward to find leaf nodes.

Spawn one subagent per caller cluster (or per direct caller for small targets).
Each subagent should:

1. Read the caller file.
2. Find the method/function that calls the target.
3. Search for callers of *that* method.
4. Repeat upward until reaching an entry point (API endpoint, scheduler,
   event consumer, main function, public interface with no callers inside scope).
5. Return one normalized path object per distinct flow.

### Path Object Schema

```
path_id:          short ID, e.g. "A", "B", "C1", "Write-1"
path_name:        human-readable description of what this path does
direction:        callers | callees
entry_point:      topmost caller or leaf node (class.method or endpoint)
call_chain:       ordered list ["Entry.method()", "...", "Target.method()"]
target:           the symbol being traced
call_type:        sync | async | callback | event | scheduled
async_mechanism:  none | future | thread | message-queue | event-bus | cron | webhook
conditional:      true | false
condition_hint:   brief description of condition gate (if conditional=true)
layer_sequence:   e.g. [api, service, repository] or [scheduler, handler, service]
side_effects:     other functions or resources modified in this path, or "none"
error_propagation: exception-propagated | return-null | logged-only | silent | unknown
business_purpose: one-sentence description of what this path achieves
confidence:       high (code read) | medium (grep match) | low (inferred)
evidence:         file:line or code snippet confirming the link to target
```

### Handling Async / Event-Driven Paths

When the call crosses an async boundary (MQ, event bus, promise, thread pool,
webhook), record:
- `call_type: async`
- `async_mechanism: <type>`
- Split the chain at the boundary: show producer side and consumer side separately
- Mark the boundary node clearly in diagrams

If the consumer cannot be found within scope, mark the boundary as
`[boundary — consumer out of scope]` in the path object and flag it in harness.

### Handling Conditional Calls

If the target is called inside a guard or conditional branch, record:
- `conditional: true`
- `condition_hint`: e.g. "only when featureFlag=true", "only on error path",
  "only when user.role=ADMIN"

Flag conditional paths in the harness section as potential sources of bugs.

---

## §4 — Diagram Generation

After all path objects are validated by the harness, fan out diagram workers in
one batch.

Launch in a single turn:
- **Subagent A**: overall overview diagram (all paths, max depth 2)
- **Subagent B..N**: one per path (full chain, split if >7 nodes)

### Overview Diagram Rules

- Use `flowchart LR`
- Central node: `TARGET[("TargetSymbol")]`
- Show entry points → target at max 2 hops; replace deeper nodes with
  `...["..."]` ellipsis nodes
- Group caller paths into subgraph labeled `📞 Callers`
- Group callee paths into subgraph labeled `📤 Callees`
- Annotate edges with call_type if not sync (e.g., `-- async MQ -->`)
- Mark conditional edges with `-- [conditional] -->`
- Max 15 nodes total; split into "Part 1 / Part 2" if larger

### Per-Path Diagram Rules

- Use `flowchart LR` for caller paths, `flowchart TD` for callee paths
- Do **not** use `sequenceDiagram` — always use `flowchart`
- Show the full chain; split at node 6 if chain is longer than 7 nodes
- Node label max 4 lines, use `<br>` for line breaks, never `\n`
- Async boundary: `ASYNC[["AsyncBoundary<br>mechanism"]]`
- Conditional gate: dashed edge `--[condition]-->`
- Side-effect node: dashed arrow `-.->` to the affected resource
- Entry point shape: `ENTRY([EntryClass<br>.method()])` (stadium shape)
- Target node: `TARGET{{"TargetClass<br>.method()"}}` (hexagon)
- Leaf/terminal node: `LEAF[("LeafClass<br>.method()")]` (cylinder)

### Prompt Template for Subagent Diagram Generation

```text
Generate a single Mermaid flowchart for ONE call-chain path.

Path details:
  path_id:         <ID>
  path_name:       <NAME>
  direction:       <callers | callees>
  call_chain:      <ordered list>
  target:          <symbol>
  call_type:       <sync | async | ...>
  async_mechanism: <none | ...>
  conditional:     <true | false>
  condition_hint:  <description>
  side_effects:    <list or "none">

Rules:
- Use `flowchart LR` for callers, `flowchart TD` for callees
- Do NOT use `sequenceDiagram`
- Node labels use <br> for line breaks, never \n
- Entry point: stadium shape ([...])
- Target: hexagon shape {{...}}
- Async boundary: subroutine shape [[...]]
- Conditional edges: dashed with condition label
- Side effects: dashed arrow to resource node
- If chain > 7 nodes, split into Part 1 and Part 2 with a link node
- Max 4 lines per label

Output: only the mermaid code block, nothing else.
```