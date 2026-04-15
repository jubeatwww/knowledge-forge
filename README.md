# Knowledge Forge

Obsidian vault 作為 Notion 之上的本地知識層。
Notion 是 source of truth（原始資料、任務、dashboard），這裡存提煉後的可重用知識。

靈感來自 [Karpathy 的 LLM knowledge base 概念](https://academy.dair.ai/blog/llm-knowledge-bases-karpathy) 和 [tobi/qmd](https://github.com/tobi/qmd) 的 context 壓縮思路。

## Architecture

```
Notion (source of truth)
  ↓ forge-sync sync-sources
02_sources/   ← index stubs (只存 metadata + notion_id，不存內容)
  ↓ forge-sync pull / pull-page
90_cache/     ← Notion 內容快照 (機器產生，不手改)
  ↓ 人工或 AI 提煉
03_notes/     ← evergreen notes (可重用的知識單元)
04_playbooks/ ← 可執行手冊 (step-by-step 操作流程)
06_skills/    ← 主題化知識包 (給 AI agent 使用)
07_context-packs/ ← 預組裝的上下文包
```

## Folder Guide

| Folder | 可編輯 | 說明 |
|--------|--------|------|
| `00_inbox/` | ✓ | 尚未分類的內容 |
| `01_hubs/` | ✓ | 每個 domain 的入口頁 |
| `02_sources/` | ✓ | Notion 來源索引 stub（frontmatter 含 `notion_id`）|
| `03_notes/` | ✓ | 提煉後的 evergreen notes |
| `04_playbooks/` | ✓ | 可執行手冊 |
| `05_projects/` | ✓ | 專案型資料 |
| `06_skills/` | ✓ | 給 AI/agent 的主題包 |
| `07_context-packs/` | ✓ | 預組裝的上下文包 |
| `90_cache/` | ✗ | forge-sync 產生的快照，不手動修改 |
| `91_exports/` | ✗ | 匯出用 |
| `99_templates/` | ✓ | 模板 |

## Domains

| Domain | Hub | 主要 Sources |
|--------|-----|-------------|
| system-design | `01_hubs/system-design.md` | Reading Tracker, 後端面試題庫, 設計文件中心 |
| frontend | `01_hubs/frontend.md` | 前端面試題庫 |
| trading | `01_hubs/trading.md` | 交易日誌, Aetherium Trader |
| english | `01_hubs/english.md` | （無獨立來源，整合在 MVA 中）|
| life | `01_hubs/life.md` | 個人任務中心, Habit Tracker, 零散資料紀錄 |

## Source Stubs

`02_sources/` 下的每個 `.md` 檔是一個 Notion 頁面或 database 的索引 stub；database 型來源可以再往下展開成資料夾和 `INDEX.md`，但不需要為每個 entry 各建一個 `.md`。`02_sources/` 應該維持索引層，不是 page mirror。只有真的值得留下的 entry，再用 `forge-sync promote` 單獨升成 local source stub。frontmatter 包含：

```yaml
notion_id: <uuid>           # Notion page/database ID
sync_policy: on-demand      # on-demand | index-only | manual
cache_status: missing       # missing | cached | optional
```

## forge-sync

Go 寫的 CLI 工具，用來從 Notion 拉內容到 `90_cache/`。
也可用 discovery config 自動維護 `02_sources/`，不用手動整理每個 source stub。
Source code 在 `.forge/tools/forge-sync/`，compiled binary 在 `.forge/bin/`。

詳見 [.forge/tools/forge-sync/README.md](.forge/tools/forge-sync/README.md)。

## Start Here
1. 先看 `INDEX.md`
2. 依主題進入 `01_hubs/`
3. 要找可直接使用的知識，優先看 `03_notes/` 與 `04_playbooks/`
