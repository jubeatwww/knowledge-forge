---
title: Habit Game Agent Protocol
kind: skill
topic: life
tags:
  - habit-game
  - agent
  - protocol
---

# Habit Game Agent Protocol

定義 agent 如何處理 habit game 互動。所有寫入都是 vault 檔案，**無 Notion API 依賴**。

## 四種互動模式

### 1. 被動記錄（使用者主動報告）
使用者說「剛做完 X」「喝了 500ml 水」「練了 30 分鐘吉他」

**Agent 動作**：
1. 判斷對應 Habit / Unit（用 [[behaviors]] 優先級表比對）
2. 估算 XP（用 [[schema]] 的 XP 規則，問使用者當下能量 or 從對話脈絡推測）
3. 寫入 `05_projects/habit-game/sessions/{今日 YYYY-MM-DD}.md`：
   - 檔案不存在：建立新檔，frontmatter 包含 `total_xp`
   - 檔案已存在：append 新 session 章節，更新 frontmatter 的 `total_xp`
4. 回覆：`✅ {habit} +{xp} XP — {一句話評語}`

### 2. 主動推薦（使用者問「該做什麼」或「空轉」）
**Agent 動作**：
1. 判斷當前時段（早 / 中午 / 下班後 / 深夜）
2. 問或推測能量等級
3. 讀最近 3-7 天 sessions 檔，找出哪些行為偏離（套用 [[behaviors]] 偏離規則）
4. 從 [[behaviors]] 能量 × 時段推薦池給 3 個最划算的下一步
5. 明確告訴使用者「為什麼是這 3 個」（偏離了什麼、跨域加成是什麼）

### 3. 主動提醒（偏離偵測，由 daily check-in 觸發）
**Agent 動作**：
1. daily-check-in agent 執行時，讀 [[behaviors]] 的偏離偵測規則
2. 對每條規則掃描 sessions 檔檢查
3. 只有真的偏離才在 check-in 輸出提到，不要每天重複同樣的話
4. 提醒語氣依 [[intent]] 的「鼓勵 > 懲罰」原則

### 4. 回顧查詢（使用者問「這週做了什麼」「streak 多少」）
**Agent 動作**：
1. 讀對應範圍的 sessions 檔
2. 彙整：總 XP、各 habit 完成次數、streak、偏離項
3. 用 [[behaviors]] 的跨域加成，指出一兩個值得注意的趨勢

## 寫入 session 的精確格式

當使用者說「我剛做了 X」，寫入 `05_projects/habit-game/sessions/{today}.md`：

```markdown
## {habit} — {unit 或 brief description}
- time: HH:MM
- habit: {habit name from behaviors.md}
- unit: {unit name, optional}
- xp: {number}
- status: done | skipped
- notes: {使用者說的上下文}
```

建立新檔時，frontmatter：
```yaml
---
title: Habit Sessions YYYY-MM-DD
kind: habit-sessions
date: YYYY-MM-DD
total_xp: {當日累積}
---

# Habit Sessions YYYY-MM-DD
```

## 不該做的事
- 不要假裝寫入成功但實際沒寫（檔案寫失敗要明確回報）
- 不要替使用者決定「這個不算 session」（他說做了就記，品質由 notes 反映）
- 不要一次推薦超過 3 個下一步
- 不要在使用者低能量時用負面語氣
- **不要呼叫 Notion API 寫 habit sessions**（Notion 端已退役）

## Related
- [[intent]]
- [[behaviors]]
- [[schema]]