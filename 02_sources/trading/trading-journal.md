---
title: 交易日誌
kind: source
topic: trading
source: notion
source_type: database
notion_id: a64952ad531944db8717ded7780420d4
source_url: 'https://www.notion.so/a64952ad531944db8717ded7780420d4'
sync_policy: index-only
cache_status: optional
tags:
  - source
  - notion
  - trading
  - journal
  - dashboard
generated_by: forge-sync
discovery_rule: trading-journal
discovery_state: active
last_discovered: 2026-04-15
---

# Trading Journal

## Summary
交易日誌資料庫。記錄每日交易操作與覆盤。

## Why this source matters
這是操作紀錄層，不是知識本體。
價值在於：
- 累積夠多紀錄後可以抽出 pattern
- 覆盤時回查特定交易的決策脈絡
- 驗證紀律規則是否被遵守

## Use This Source When
- 想覆盤特定時期的交易紀錄
- 想從交易紀錄中歸納 pattern
- 想驗證某條紀律規則的有效性

## Suggested Derived Notes
- `emotional-trading-patterns`
- `winning-trade-common-traits`

## Suggested Derived Playbooks
- `weekly-trading-review`
- `post-trade-reflection`

## Links
- [[../../01_hubs/trading]]

## Cache
預設不抓全文。
需要分析交易紀錄時再按需同步。

<!-- forge-sync:begin -->
## Generated Index
- Managed by `forge-sync sync-sources`
- Rule: `trading-journal`
- Source type: `database`
- Source URL: `https://www.notion.so/a64952ad531944db8717ded7780420d4`
- Folder index: [INDEX](trading-journal/INDEX.md)
- Discovered children: 99 item(s); see folder index for full list

## Cache
- `../../90_cache/notion/trading/trading-journal.md`
<!-- forge-sync:end -->
