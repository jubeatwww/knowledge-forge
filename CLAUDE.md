# Claude Code Context

This is **Knowledge Forge** — an Obsidian vault over Notion. Notion 是 source of truth，這裡存提煉後的可重用知識。

## Before Acting
1. 用 `mcp__qmd__query` 搜尋與任務相關的關鍵字，取得 vault 中已有的 context（skills、playbooks、notes、projects）。
2. 讀 `AGENTS.md` 取得完整 reading priority 與 writing rules（此檔是濃縮版）。
3. 讀 `01_hubs/_now.md` 了解 current focus（階段目標會隨時間變動）。

## Reading Priority（摘自 AGENTS.md）
`06_skills/` → `07_context-packs/` → `04_playbooks/` → `03_notes/` → `01_hubs/` → `02_sources/` → `90_cache/`

## Landing Zones for New Input
| 輸入類型 | 目的地 |
|---------|--------|
| 每日紀錄 / check-in / 隨手輸入 | `00_inbox/checkin-YYYY-MM-DD.md`（同日 append）|
| Agent 產出 log | `00_inbox/` |
| 可重用 evergreen 知識 | `03_notes/` |
| Step-by-step 操作流程 | `04_playbooks/` |
| 未分類、暫存 | `00_inbox/` |

預設把不確定分類的輸入丟進 `00_inbox/`，之後再提煉。不要為了當下這條輸入新建 top-level 資料夾。

## Hard Rules
- 不要編輯 `90_cache/` — 那是 forge-sync 產生的快照。
- 不要編輯 `.forge/` 內部狀態檔（除非明確在處理工具本身）。
- `02_sources/` 是 index stub 層，不是 page mirror — 不要把內容倒進去。
- 所有日期用絕對日期（`2026-04-18`），不用 `今天` / `週四`。

## Useful Slash Commands
- `/checkin <free-form>` — 把今日紀錄 append 到 `00_inbox/checkin-<today>.md`。
  定義在 `06_skills/ai-harness/claude/commands/checkin.md`，
  透過 `sync.sh` / `sync.ps1` 安裝到 `~/.claude/commands/`（user-scope，跨裝置同步）。

## Tools
- `forge-sync`（Go CLI，位於 `.forge/bin/`）— Notion ↔ vault 同步。詳見 `.forge/tools/forge-sync/README.md`。