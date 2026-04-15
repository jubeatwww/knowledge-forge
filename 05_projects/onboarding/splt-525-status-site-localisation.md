---
title: SPLT-525 Status Site Localisation
kind: project-note
tags:
  - onboarding
  - work
  - project
  - site-status
  - patron
  - localisation
---

# SPLT-525 Status Site Localisation

## Snapshot
- Date: 2026-04-15
- Status: code 已完成，但 review 尚未全部結束
- Jira: [SPLT-525](https://opennetltd.atlassian.net/browse/SPLT-525)
- PR: [sportybet-patron#2469](https://github.com/opennetltd/sportybet-patron/pull/2469)
- PR: [sportybet-site-status#3](https://github.com/opennetltd/sportybet-site-status/pull/3)

## What This Work Actually Did
這次不是單一 repo 改完就結束，而是把 site status 的在地化拆成兩層：

- `sportybet-patron` 負責產生資料與翻譯檔
- `sportybet-site-status` 負責讀取檔案並渲染成使用者看到的靜態頁

Jira 要求是替 BR / MX 提供 status page 與 announcement page 的在地化版本，而且未來要能繼續擴市場，不想每多一個市場就重做一輪。

## Repo Split
### sportybet-patron
- 這是一個多人共改的 shared backend repo。雖然不只做登入，但在目前工作脈絡裡，它就是一個核心、容易被很多 team 一起疊需求的地方。
- 這次在 `service-patron` 裡新增 `SiteStatusCmsService`，從 CMS 拉翻譯內容。
- 新增 `SiteStatusTranslationPublisher`，定期把 `translation/default.json` 與 `translation/{locale}.json` 發到既有的 S3 流程。
- `statuses.json` 也被補上 `nameKey`，讓前端可以用 key 查翻譯，而不是把各語系字串直接塞進 status payload。
- 這條流程有用 `sportybet.cms.enabled` 做 config gate，避免把 CMS flow 硬綁進所有環境。
- 實作上偏 additive，不是 refactor。原因很直接：這個 repo 太多人一起改，真正的大整理在這個情境下不現實，只能盡量疊在既有 publishing flow 上。

### sportybet-site-status
- 這是一個很單純的 static site，使用 Vite + `vite-plugin-singlefile` 打成單頁，Jenkins 再把 `dist/index.html` 上傳到 S3。
- 它本身不做複雜後端邏輯，主要是讀 status / announcements / translation JSON，然後把結果渲染給使用者。
- 這次把原本肥大的 `main.js` 拆成 `config`、`cache`、`dropdown`、`render`、`i18n`、`utils` 幾個模組，讓在地化邏輯不要繼續黏在同一支檔案裡。
- runtime i18n 會先讀 `/<region>/translation/{locale}.json`；如果 URL 上沒有 `?lang=` 或指定語系抓不到，就退回 `default.json`。
- 前端顯示 service / group 名稱時，優先用 status payload 裡的 `nameKey` 去查翻譯；如果 key 不存在，最後還是回退到 API 原本給的英文文案，避免頁面直接露出 raw key。

## Architecture Shape
- `sportybet-patron` scheduler 持續產出 `statuses.json`、`announcements.json`、`translation/*.json`
- `sportybet-site-status` 只讀這些檔案，不碰 CMS
- status page 跟 announcement page 的文案本體來自 CMS translation JSON
- service / group 顯示名稱靠 `nameKey` 對應翻譯
- 前端另外處理 region domain、infra path、`?lang=` override 與 fallback

這個切法的好處是邊界很清楚：

- backend 處理資料生成與語言檔發布
- frontend 處理呈現、fallback 與 region routing

## Why It Matters
- BR / MX 的在地化先落地，之後要擴其他市場時，理論上只要補 CMS 翻譯與語系設定，不需要再重改整個頁面
- `sportybet-patron` 雖然混亂，但這次至少把變更收斂成一條可開關、可測試的 publishing flow
- `sportybet-site-status` 的架構很簡單，適合快速交付；你自己的描述是這個站大概兩個星期做出來

## Review State On 2026-04-15
- `sportybet-patron#2469`：`REVIEW_REQUIRED` / `BLOCKED`
- `sportybet-site-status#3`：PR 已開，merge state `CLEAN`

## Related
- [[INDEX]]
- [[domain-map]]
- [[weekly-recap]]
