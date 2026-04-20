# Report Template

Use the following shape for the final report. Do **not** wrap the entire report
in a fenced `markdown` block, and do **not** wrap the final recommendation in a
generic `text` block.

# `<TABLE_NAME>` 依賴路徑報告

## 背景

- Table: `<TABLE_NAME>`
- Jira: `<JIRA_URL or none>`
- Database: `<DB_NAME>`
- Existing archive rule: `<N days or unknown>`

## 表結構 (DDL)

```sql
<DDL>
```

## 基本判斷

- idx_create_time: `yes / no`
- write-once: `yes / no`
- direct mapper count: `<N>`
- total path count: `<N>`

## Mermaid 總覽圖

<overall mermaid block>

## 各路徑詳細說明

### ✏️ 寫入路徑

<per-path mermaid block>

| 步驟 | 元件 | 說明 | 觸碰 DB 欄位 |
|----|----|----|----------|
| 1  |    |    |          |

### 📖 讀取路徑 A — <name>

<per-path mermaid block>

路徑摘要:
- `<entry> -> <service> -> <mapper>`
- `SQL: <type> <key fields / WHERE conditions>`

回傳用途:
- `<why this path exists>`

## 欄位存取矩陣

| 路徑 | 方向   | 觸碰欄位 | WHERE 條件欄位 |
|----|------|------|------------|
| A  | read |      |            |

## Archive Rule 評估

### Q1 to Q4 決策矩陣

<evaluation table>

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

## Mermaid Cheatsheet

| Element                  | Format                      |
|--------------------------|-----------------------------|
| line break in label      | `<br>` only                 |
| table node               | `TABLE[("t_table_name")]`   |
| MQ node                  | `MQ[["RocketMQ<br>TOPIC"]]` |
| master mapper            | label ends `← Master DB`    |
| slave mapper             | label ends `← Slave DB`     |
| dashed side-effect arrow | `-.->`                      |
| read path direction      | `flowchart LR`              |
| write path direction     | `flowchart TD`              |
