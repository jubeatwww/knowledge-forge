---
title: Habit Game Project
kind: project
topic: life
tags:
  - habit-game
  - project
---

# Habit Game Project

此專案放 habit tracker 的衍生輸出：每日 sessions、週快照、個人 XP 記錄。
**意圖、行為定義、agent 協定都在 [[../../06_skills/habit-game/INDEX]]**。

## Source of Truth
`05_projects/habit-game/sessions/YYYY-MM-DD.md` — 每日 sessions，vault-native。
Agent 直接讀寫 markdown，無 Notion API 依賴。

## Progress Views

### A — On-demand Query（隨時可用）
直接跟 agent 對話：
- 「這週做了什麼？」
- 「streak 多少？」
- 「我最近哪項偏離了？」

Agent 從 sessions 檔彙整，產出即時摘要。

### B — Weekly Snapshot（每週產出）
路徑：`05_projects/habit-game/weekly-YYYY-WW.md`
由 weekly-refine agent 每週自動產出。
格式參考 [[weekly-template]]。

### C — Grafana Dashboard（未做，有空再做）
見 [[roadmap#grafana-dashboard]]。

## Files
- [[roadmap]] — 未完成的進度視覺化工作（C）
- [[weekly-template]] — weekly snapshot 格式
- `sessions/YYYY-MM-DD.md` — 每日 sessions
- `weekly-YYYY-WW.md` — 每週快照（generated）

## Related
- [[../../06_skills/habit-game/INDEX]]
- [[../../01_hubs/life]]