---
title: Domain Map
kind: project-note
tags:
  - onboarding
  - domain
  - work
---

# Domain Map

## Product / Business
先回答：

- 這個團隊實際在解哪個問題？
- 使用者是誰？
- 成功指標是什麼？
- 目前最重要的 trade-off 是什麼？

## Team Map
- Team / Squad:
- Manager:
- Key peers:
- Cross-functional partners:
- 最懂歷史脈絡的人:
- 最懂系統細節的人:

## System Map
列出最重要的系統與它們的關係：

- `sportybet-patron`
  role: shared backend repo；多人一起改，這次也負責產出 site status 需要的 `statuses.json`、`announcements.json`、`translation/*.json`
  input / output: 吃 CMS translation、service health 與既有狀態資料，輸出給前端讀取的 JSON 檔
  critical dependency: scheduler、CMS、S3 uploader
  common failure mode: shared ownership 太重，真正 refactor 成本高，很多需求最後只能 additive 地疊進去

- `sportybet-site-status`
  role: static frontend status site；讀 JSON 後渲染 status / announcements 頁面
  input / output: 吃 `statuses.json`、`announcements.json`、`translation/*.json`，輸出使用者可直接打開的狀態頁
  critical dependency: S3 上的靜態檔與 region / infra path mapping
  common failure mode: region mapping、locale fallback、資料檔路徑對不上時，畫面會退回英文或直接載入失敗

- 關聯筆記：[[splt-525-status-site-localisation]]

每個系統至少補這些欄位：

- owner
- role
- input / output
- critical dependency
- common failure mode

## Vocabulary
記錄新工作裡高頻出現的詞：

- `nameKey`
  meaning: status payload 裡給 frontend 查翻譯的 key
  why it matters: 讓 frontend 能用 key lookup 吃多語系，而不是把各語系字串直接寫死在 status JSON

- `translation/default.json`
  meaning: 沒有指定 `?lang=` 或指定語系抓不到時的 fallback translation 檔
  why it matters: 決定在地化失敗時頁面會怎麼退回預設語系

## Unknowns
目前還不清楚，但會影響判斷的東西：

- 

## Related
- [[INDEX]]
- [[question-log]]
