---
title: Habit Game Schema
kind: skill
topic: life
tags:
  - habit-game
  - schema
  - vault-native
---

# Habit Game Schema

Vault 是 source of truth。Sessions / Habits / Units / Loops 全部用 markdown。
不再依賴 Notion API。

## 目錄結構

```
05_projects/habit-game/
├── INDEX.md              # 專案入口
├── roadmap.md            # 未完成工作
├── weekly-template.md    # 週快照格式
├── sessions/
│   └── YYYY-MM-DD.md     # 每日一份，當日所有 session 條目
└── weekly-YYYY-WW.md     # 週快照（weekly-refine 產出）

06_skills/habit-game/
├── INDEX.md
├── intent.md             # 身份驅動
├── behaviors.md          # 當前優先級 + 偏離規則（Habits/Units/Loops 定義）
├── schema.md             # 本文件
└── agent-protocol.md     # agent 操作流程
```

## Daily Session 檔案格式

`05_projects/habit-game/sessions/2026-04-14.md`：

```markdown
---
title: Habit Sessions 2026-04-14
kind: habit-sessions
date: 2026-04-14
total_xp: 23
---

# Habit Sessions 2026-04-14

## 運動 — 重訓 30min
- time: 19:30
- habit: 運動
- unit: 重訓
- xp: 15
- status: done
- notes: 下班後硬撐起來做的

## 喝水 — 500ml
- time: 20:15
- habit: 健康追蹤
- unit: 喝水
- xp: 3
- status: done
- notes:

## 口說（中文）— skipped
- time: 22:00
- habit: 口說
- unit: 中文
- xp: 0
- status: skipped
- notes: 太累，明天補
```

規則：
- 每個 session 是一個 `## {habit} — {unit or brief}` 章節
- 屬性用 markdown list
- `total_xp` 在 frontmatter，是當日所有 done session 加總
- 一天沒任何 session 就不建檔（不要塞 placeholder）

## Habits / Units / Loops 定義位置

這些不需要獨立 DB — 定義都寫在 `06_skills/habit-game/behaviors.md` 的優先級表：
- Habit = 優先級表裡的「行為」欄（運動、健康追蹤、口說、冥想、...）
- Unit = 具體子項（重訓 / 有氧 / 喝水 / 蛋白質 / 中文 / 英文 / ...）
- Loop = 不明確建檔。Daily = 每個 session 檔；Weekly = `weekly-YYYY-WW.md`；Monthly 用到時再加

## XP 計算（agent 即時判斷）

基礎 XP：
- 低能量日完成簡單事：5
- 中能量日：10
- 高能量日高價值任務：15

加成（agent 依 notes 判斷）：
- 難度 / 品質 / 投入時間 / streak / 超出預期 → +1 ~ +10
- 低能量日完成 P0/P1 → +3 ~ +5（鼓勵）

## Query 邏輯（agent 用）

```
最近 N 天 sessions：讀 05_projects/habit-game/sessions/{YYYY-MM-DD}.md
streak：從今天往前推 done 連續天數
偏離：按 behaviors.md 的偏離規則對 sessions 比對
週彙整：讀該週 7 份 session 檔聚合
```

所有操作都是 filesystem + grep，不需要 API。

## Related
- [[behaviors]]
- [[agent-protocol]]