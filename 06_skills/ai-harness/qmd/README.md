---
title: qmd Harness
kind: skill-index
tags:
  - qmd
  - search
  - mcp
  - index
---

# qmd — Knowledge Forge Search Harness

本地 hybrid search（BM25 + vector + LLM rerank）搭 Claude Code MCP，給 vault
內提煉過的內容用。qmd 是全域安裝的 CLI，這個目錄只負責「這個 vault 怎麼用 qmd」
的那一層。

- Upstream：<https://github.com/tobi/qmd>
- Named index：`knowledge-forge`（SQLite 在 `~/.cache/qmd/knowledge-forge.sqlite`，
  不 commit）
- MCP 設定：repo root 的 [`.mcp.json`](../../../.mcp.json)，Claude Code 啟動時
  自動拉起 `qmd mcp --index knowledge-forge`

## Indexed Folders

只 index **curated** 區域。各資料夾的語意以 [[../../../AGENTS|AGENTS]] 為準。

| Collection | Path | 為什麼 index |
|------------|------|--------------|
| `hubs` | `01_hubs/` | 主題入口 |
| `notes` | `03_notes/` | 提煉後的 evergreen knowledge |
| `playbooks` | `04_playbooks/` | 可執行流程 |
| `projects` | `05_projects/` | 活躍 project context |
| `skills` | `06_skills/` | AI-facing 主題包 |
| `context-packs` | `07_context-packs/` | 打包好的 context |

**不 index**：

- `00_inbox/` — 原始輸入，人工 triage 之後才算有價值。等 inbox-triage agent 上線
  後再考慮 index `00_inbox/_processed/`。
- `02_sources/` — 只是指向 Notion 的 stub。
- `90_cache/` — 生成的 Notion 快照。
- `91_exports/`, `99_templates/`, `.forge/` — 非知識。

## Setup（首次 / 新機器）

```bash
# 前置：先裝 qmd（globally），並確認 ~/.cache/ 可寫。
qmd --version

# 在 vault 任何子路徑下：
cd /path/to/knowledge-forge
bash 06_skills/ai-harness/qmd/bootstrap.sh
```

首次 `qmd embed` 會拉 GGUF 模型到 `~/.cache/qmd/models/`，吃一點頻寬與硬碟。
後續只是增量更新。

## 日常維護

```bash
# vault 有新/改內容後：
qmd --index knowledge-forge update

# 看目前狀態：
qmd --index knowledge-forge status

# 清除重建（極少用到）：
qmd --index knowledge-forge cleanup
```

## Claude Code 整合

repo root 的 `.mcp.json` 註冊了 qmd MCP server。Claude Code 在 vault 內開啟時
會自動拉起它（首次需要使用者同意），然後就有 qmd 相關 tool 可以叫。

搜 vault 時優先用 qmd MCP；只有在找特定字串或檔名時才退回 `grep` / `rg`。

## Troubleshooting

- **`qmd: command not found`** — qmd 不是 repo 的依賴，需要全域安裝。
- **MCP server 沒出現** — 確認 Claude Code 已經重啟並同意 `.mcp.json` 的 server。
- **索引結果舊** — 跑 `qmd --index knowledge-forge update` 或 `embed -f`（force）。
- **想換 index 名稱** — 設 `QMD_INDEX=my-name` 再跑 `bootstrap.sh`；`.mcp.json`
  的 `--index` 參數也要同步改。

## Related

- [[../INDEX]] — ai-harness 整體
- [[../claude/INDEX]] — Claude Code harness
- [[../../../CLAUDE]] — 專案指令，有提到 qmd 的搜尋順位
