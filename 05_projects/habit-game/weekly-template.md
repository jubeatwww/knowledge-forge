---
title: Weekly Snapshot Template
kind: template
topic: life
tags:
  - habit-game
  - template
---

# Weekly Snapshot Template

weekly-refine agent 產出 `weekly-YYYY-WW.md` 時使用此格式。
資料來源：`05_projects/habit-game/sessions/{YYYY-MM-DD}.md`（該週 7 份）。

---

```markdown
---
title: Weekly Snapshot YYYY-WW
kind: habit-weekly-snapshot
period_start: YYYY-MM-DD
period_end: YYYY-MM-DD
total_xp: N
total_sessions: N
generated: true
---

# Weekly Snapshot YYYY-WW

## Period
YYYY-MM-DD → YYYY-MM-DD（7 days）

## Totals
- Sessions: N
- Total XP: N
- Active habits: N / all P0-P1

## By Habit
| Habit | Done | Skipped | Streak | Status |
|---|---|---|---|---|
| 運動 | 3 | 0 | 5d | ✅ on track |
| 喝水追蹤 | 6 | 1 | 2d | ⚠️ 1 skip |
| ... | | | | |

## Deviations
- （只列出當週真的偏離的項目，套用 behaviors.md 的偏離規則）
- 沒偏離就寫「本週無偏離」

## Cross-Domain Highlights
- （觀察到的行為跨域連動，例如「冥想頻率提升後 notes 裡的狀態描述變正向」）
- 沒觀察到就略過這段

## Observations
- （2-4 句話的整體評價，語氣參考 intent.md 的鼓勵 > 懲罰原則）

## Next Week Suggestion
- （最多 3 個建議，針對偏離項或下階段推動的行為）

## Related
- [[INDEX]]
- [[../../06_skills/habit-game/behaviors]]
```