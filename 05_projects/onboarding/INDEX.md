---
title: Onboarding
kind: project
tags:
  - onboarding
  - work
  - project
---

# Onboarding

## Purpose
這個專案收納與目前工作 onboarding 直接相關的內容。

它處理的是短中期有效、與當前公司 / 團隊 /系統綁定的資訊，
不是長期 evergreen knowledge。

## What Goes Here
- 30-60-90 目標
- 團隊、產品、系統理解
- 名詞、流程、角色對應
- 尚未解答的問題
- 每週 recap 與阻塞

## Working Rule
先把與新工作直接相關的資訊放這裡。

如果某個模式重複出現，且已經不只屬於這家公司或這份職位，
再升級到 `04_playbooks/` 或 `03_notes/`。

## Start Here
- [[30-60-90]]
- [[domain-map]]
- [[question-log]]
- [[weekly-recap]]

## Recent Delivery Notes
- [[splt-525-status-site-localisation]] — BR / MX status page 與 announcement page 在地化，橫跨 `sportybet-patron` 與 `sportybet-site-status`

## Active Investigations
- [[2fa-device-swap-investigation]] — 兩位 user 的 app 登入失敗追查；含 SPLT-648 (Nigeria app access) 與另一位疑似換裝置 + 2FA 阻擋的 case
- [[SPLT-697-device-id-investigation/SPLT-697-device-id-investigation|SPLT-697 device_id investigation]] — device_id 產生邏輯與格式差異追查（Fraud tracking 用），含 `deviceIdSc` / fingerprint 寫入路徑
- [[archiving-rules-4-tables-in-afbet-patron/INDEX|SPLT-679 archive rule review]] — 4 個 `afbet_patron` 表格的 archive rule 可行性評估（DBA review 證據包）

## Promotion Rule
符合以下條件時，從 project 升級出去：

- 已經重複出現兩次以上
- 未來換團隊或換專案仍然有用
- 可以被寫成 checklist / decision rule / reusable pattern

## Related
- [[../../01_hubs/_now]]
- [[../../04_playbooks/core/weekly-alignment-review]]
- [[../../04_playbooks/work/manager-1on1-prep]]
