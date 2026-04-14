---
title: Aetherium Trader
kind: source
topic: trading
source: notion
source_type: page
notion_id: 2af1cb737bce80bfa9b9d9a52728df09
source_url: 'https://www.notion.so/Aetherium-Trader-2af1cb737bce80bfa9b9d9a52728df09'
sync_policy: on-demand
cache_status: missing
tags:
  - source
  - notion
  - trading
  - side-project
  - system-design
generated_by: forge-sync
discovery_rule: aetherium-trader
discovery_state: active
last_discovered: 2026-04-14
---

# Aetherium Trader

## Summary
交易模擬與回測平台的系統設計文件。
目標：建立一個可控、可回放的交易模擬環境，用於練習與驗證手動交易策略。

核心模組：
- 分散式資料擷取平台（Scheduler / Worker / Token Bucket / Checkpoint）
- Tick/MarketData 儲存（Parquet + ClickHouse + NAS/S3）
- TradingCore + SimulationBackend
- 手動練習前端（K 線、下單、回放控制）

## Why this source matters
兼具兩個面向的價值：
1. **Trading**：交易練習工具的設計思路
2. **System Design**：分散式系統實戰（rate limiting、checkpoint、CQRS 等 pattern）

面試時可作為「自己的 project」的 talking point 來源。

## Use This Source When
- 想回看這個 project 的架構決策
- 想從中抽出 system design 面試素材
- 想整理交易模擬系統的 trade-offs

## Suggested Derived Notes
- `rate-limiting-token-bucket`
- `checkpoint-recovery-pattern`
- `market-data-storage-tradeoffs`

## Links
- [[../../01_hubs/trading]]
- [[../../01_hubs/system-design]]
- [[../system-design/system-design-doc-center]]

## Cache
- `../../90_cache/notion/trading/aetherium-trader.md`

<!-- forge-sync:begin -->
## Generated Index
- Managed by `forge-sync sync-sources`
- Rule: `aetherium-trader`
- Source type: `page`
- Source URL: `https://www.notion.so/Aetherium-Trader-2af1cb737bce80bfa9b9d9a52728df09`

## Cache
- `../../90_cache/notion/trading/aetherium-trader.md`
<!-- forge-sync:end -->
