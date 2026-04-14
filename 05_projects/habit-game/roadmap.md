---
title: Habit Game Roadmap
kind: project-roadmap
topic: life
tags:
  - habit-game
  - roadmap
  - future-work
---

# Habit Game Roadmap

## Done
- [x] 2026-04-14 — 身份 / 行為 / schema / agent 協定 skill pack（`06_skills/habit-game/`）
- [x] 2026-04-14 — agent-protocol 定義四種互動模式
- [x] 2026-04-14 — Notion Habit Tracker Game 版面退役
- [x] 2026-04-14 — weekly-refine agent 加入 weekly snapshot 生成
- [x] 2026-04-14 — Sessions 改為 vault-native（markdown 檔），完全移除 Notion API 依賴

## In Progress
- （無）

## Grafana Dashboard
**狀態**：未開始。留給有空時做。

**動機**：agent on-demand query 夠用在日常對話，但長期 XP 曲線、趨勢圖、偏離警告面板在 Grafana 上看比純文字摘要直觀。

**前置條件**：
- k3s server 上跑 Grafana + Prometheus
- Prometheus exporter：從 Notion Sessions DB 定期拉數據轉 time-series
- 或：另一條路，agent 定期 export Sessions → 本地 SQLite/DuckDB → Grafana 直連

**想呈現的面板**：
- 每日 / 每週完成率曲線
- XP 累積圖
- 偏離警告面板（哪些 P0/P1 偏離了）
- 跨域加成熱圖（哪些行為在支撐哪些身份）

**先不做的理由**：
- Agent on-demand + weekly snapshot 已經能回答「現在怎樣」的問題
- Grafana infra 要花力氣維護
- 等資料累積到一定量（≥ 4-8 週 sessions）再做才有意義

## 其他未做項目
- [ ] 多 agent 架構（chief / interviewer / researcher / coder / steward）— 當前單一對話就夠用
- [ ] Home Assistant 場景自動化
- [ ] Apple Watch 健康數據同步
- [ ] 飲食照片分析（蛋白質 / 熱量估算）
- [ ] Voice wake / 躺著語音記錄

## Related
- [[INDEX]]
- [[../../02_sources/life/habit-tracker-game]]