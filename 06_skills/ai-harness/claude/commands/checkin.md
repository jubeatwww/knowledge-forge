---
description: Append today's free-form log entry to the Knowledge Forge vault's 00_inbox/checkin-<date>.md
argument-hint: <自由輸入 — 今天做了什麼 / 想到什麼>
---

# /checkin

把使用者的輸入寫進 Knowledge Forge vault 今日 check-in 檔案。允許少量澄清問題，
幫使用者補上未來看得懂的 context。

## Input
使用者輸入：$ARGUMENTS

## Vault Resolution（必做第一步）

這個 command 只在 Knowledge Forge vault 內有意義。從 cwd 往上找 vault 根：
同時存在 `AGENTS.md`、`00_inbox/`、`90_cache/`、`02_sources/` 才算。

- 找到 → 用那個路徑當寫入根。
- 找不到 → 回報 `not inside Knowledge Forge vault — cd into it first` 並結束，不要亂寫。

## Steps

1. 解析 vault root（見上）。
2. 檢查輸入完整度，決定要不要問問題（見下方 "Clarification Policy"）。
3. 有需要就問 1–2 個精準的問題，等使用者回答後再寫入。
4. 取得今天日期（絕對日期 `YYYY-MM-DD`）。用環境 context 提供的 `Today's date`。
5. 目標檔案：`<vault-root>/00_inbox/checkin-<YYYY-MM-DD>.md`
6. 判斷檔案是否存在：
   - 不存在：建立 + frontmatter + 第一筆條目。
   - 已存在：append 到檔尾，不動 frontmatter。
7. 條目格式：
   ```
   ## <HH:MM>
   <整合後的內容>
   ```
   時間 24 小時制，本地時間。
8. Frontmatter（僅新檔案）：
   ```yaml
   ---
   title: Check-in <YYYY-MM-DD>
   kind: checkin
   date: <YYYY-MM-DD>
   ---
   ```

## Clarification Policy

**目的**：避免三個月後回看完全看不懂自己寫了什麼。但不要把快速捕捉變成訪談。

**問問題的情境**：
- 代名詞沒交代（「那個 bug」「那個 PR」「他」）→ 問是哪個。
- 事件沒結果（「debug 了一下」「看了文件」）→ 問結論或是否解決。
- 有情緒 / 判斷但沒有事由（「今天很亂」「覺得卡住」）→ 問是因為什麼事。
- 提到任務 / 交付但沒指名（「推了一個 PR」「開了個 ticket」）→ 問編號或標題。

**不問的情境**：
- 輸入已經完整自洽 → 直接存。
- 使用者明顯只想快速 dump（輸入很長、細節多）→ 直接存。
- 問題已超過 2 個 → 停，用手上已有的資訊寫入，不要追問第三個。

**問法**：一次只問一個，精簡，不要解釋為什麼問。

範例：
- 使用者：「debug 了一個 k8s 問題」
  → 問：「哪個問題？DNS、scheduling 還是其他？有解嗎？」
- 使用者：「早上 onboarding meeting，下午看了 service A 的 code，晚上整理筆記」
  → 不問，直接存。

## Writing Rules

- 整合使用者原文 + 回答後的補充，組成通順的一段，但保留使用者的語感（不過度改寫、不翻譯）。
- **不主動提煉**到 `03_notes/` 或 `04_playbooks/`。這個 command 只負責捕捉。
  提煉留給 weekly-refine 或使用者明確要求時。
- 寫完後回報：檔案路徑 + 時間戳，不貼整段內容。
- 空輸入 → 報錯：`/checkin <內容>`。