---
description: Manually trigger the Knowledge Forge weekly-refine agent (90_cache + 00_inbox → notes/playbooks/projects + habit-game weekly snapshot)
argument-hint: [optional scope hint — e.g. "cache only", "inbox only", "skip habit", 特定檔名 / 關鍵字]
---

# /refine

手動觸發 `.forge/agents/weekly-refine.md` 定義的提煉流程。
agent 設計成週排程跑；在還沒接排程的時候，這個 command 就是手動入口。

規格涵蓋三件事：
1. 掃 `90_cache/` 把值得的 Notion 內容提煉到 `03_notes/` / `04_playbooks/`。
2. 整理 `00_inbox/` — 子資料夾歸位到 `05_projects/`、單檔提煉或歸檔。
3. 產 Habit Game weekly snapshot。

## Input
使用者 scope hint（可選）：$ARGUMENTS

## Vault Resolution（必做第一步）

這個 command 只在 Knowledge Forge vault 內有意義。從 cwd 往上找 vault 根：
同時存在 `AGENTS.md`、`00_inbox/`、`90_cache/`、`02_sources/` 才算。

- 找到 → 用那個路徑當 working root。
- 找不到 → 回報 `not inside Knowledge Forge vault — cd into it first` 並結束，
  不要亂寫檔。

## Steps

1. 解析 vault root（見上）。
2. 讀 `<vault>/.forge/agents/weekly-refine.md`，把它當作這次要執行的**完整 spec**。
   規格裡的 step 1–7、寫入格式、Rules 都要照做。
3. 如果 `.forge/agents/weekly-refine.md` 不存在，回報 `missing weekly-refine spec`
   並結束。
4. 如果 `$ARGUMENTS` 非空，視為 scope hint 縮小範圍。支援的 hint：
   - `cache only` → 只跑 source A（90_cache），跳過 inbox 掃描與 habit snapshot
   - `inbox only` → 只跑 source B（00_inbox），跳過 cache 與 habit snapshot
   - `skip habit` → 跑 cache + inbox，但不產 habit-game weekly snapshot
   - 特定路徑 / 關鍵字 → 只處理 match 的檔案
   - 其他 → 當作一般過濾條件帶入
5. 嚴格照 weekly-refine.md 執行，包括：
   - 掃 `90_cache/` 最近 7 天變動（source A）
   - 掃 `00_inbox/` root 檔（排除 log 類）+ 子資料夾（source B）
   - 套 Capture Rules（四個問題）
   - 寫 `03_notes/` / `04_playbooks/` / `06_skills/`，照規格 frontmatter
   - Inbox 子資料夾用 `git mv` 整組搬到 `05_projects/<domain>/`
   - Inbox 單檔視情況提煉（`git rm` 原檔）或歸檔（`git mv` 到 `00_inbox/_archive/`）
   - 更新 `01_hubs/` 與 `05_projects/<domain>/INDEX.md` 連結
   - 產 refine log 到 `00_inbox/refine-log-YYYY-MM-DD.md`
   - （除非被 hint 排除）產 habit-game weekly snapshot
6. 完成後回報：
   - Refined / Moved / Archived 各段的檔案清單（列路徑，不貼內容）
   - Skipped 清單（一句原因）
   - weekly-refine.md 的 Suggestions 區塊要有什麼
   - 如果 hint 縮了範圍，說明這次實際跑的 scope

## Rules

- 不修改 `90_cache/` 和 `02_sources/`。
- 一次提煉不超過 5 個 note/playbook，品質優先；搬遷 / 歸檔不設上限。
- 搬遷一律 `git mv`，不要 cp + rm。
- 不動 `00_inbox/checkin-*.md` 和 log 類檔。
- refine log 要寫 — 即使完全沒動作也要產（記錄「這週沒值得提煉的」也是資訊）。
- 空輸入是 OK 的，直接跑全量 weekly-refine。
