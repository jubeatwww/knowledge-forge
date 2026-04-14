---
notion_id: 2911cb73-7bce-80a8-9b3b-c7832ca9329e
source_url: https://app.notion.com/p/2911cb737bce80a89b3bc7832ca9329e
fetched_at: 2026-04-14
---

# 前端面試題庫

#### 使用說明

- 將每一道題目新增到下方資料庫
- 用「主題」「難度」「型別」做分類，搭配「狀態」與「下次複習」安排複習
- 有延伸或 follow up 就另外新增一筆題目，並在兩者的描述內互相標註關聯關鍵字

---

---


### 連結

這裡整理了一些「前端系統設計／面試／效能優化」相關的高品質資源，適合作為本題庫的延伸閱讀清單

#### 前端系統設計

- **awesome-front-end-system-design** － 前端系統設計主題彙整（含 News Feed、Autocomplete 等經典題目）
	- Github： [https://github.com/greatfrontend/awesome-front-end-system-design](https://github.com/greatfrontend/awesome-front-end-system-design)


#### 面試知識手冊

- **front-end-interview-handbook** － 深度前端面試與架構知識，由 Meta 工程師維護
	- Github： [https://github.com/yangshun/front-end-interview-handbook](https://github.com/yangshun/front-end-interview-handbook)


#### Web 效能優化

- **awesome-wpo** － 網站效能優化資源，涵蓋 HTTP/3、CRP、圖片最佳化等主題
	- Github： [https://github.com/davidsonfellipe/awesome-wpo](https://github.com/davidsonfellipe/awesome-wpo)


#### 企業級工程部落格（Real-world Case Studies）

就像 Awesome Scalability 收集 Uber、Netflix 的案例一樣，很多前端工程化的精華其實藏在大廠的 Engineering Blog 裡：

- [Airbnb Engineering &amp; Data Science](https://medium.com/airbnb-engineering) － React Native、Server-Driven UI、Design System 相關文章是業界標竿
- [Uber Engineering（Web）](https://www.uber.com/en-TW/blog/engineering/) － 特別值得看 Base Web（Design System）與 Monorepo 治理的文章
- [Vercel Blog](https://vercel.com/blog) － 以 Next.js 為主，但對 Edge Computing、Rendering Patterns 的技術分析很有前瞻性

#### 設計模式與渲染架構

- [**Patterns.dev**](http://patterns.dev/) － 前端設計模式與渲染架構
	- 網站： [https://www.patterns.dev/](https://www.patterns.dev/)
	- Github： [https://github.com/patterns-dev/patterns.dev](https://github.com/patterns-dev/patterns.dev)


---

### 如何使用這個題庫

- 新增題目時，標好主題與難度，並設定下次複習日期
- 面試常見 follow up：建議將 follow up 也獨立成一題，標註相同關鍵字以便快速搜尋
- 練習時切到「看板」視圖，依狀態拖曳移動




## 📊 前端面試題庫

- **為什麼 Vite 生產環境選擇以 Rollup 為基礎，而不是直接使用更快的 esbuild？** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:a91930d3]
- **在 Production 環境，Vite 也是不打包直接上線嗎？它的打包策略與 Webpack 有何不同？** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:6e6de62e]
- **為什麼 Vite 的 HMR 通常比 Webpack 快？** — 難度: 中等 | 待練習 | 型別: 觀念題  ^[notion:5d390c4b]
- **Vite 的開發伺服器為什麼能做到幾乎秒開？它背後的關鍵技術是什麼？** — 待練習 | 型別: 觀念題 | 難度: 中等  ^[notion:1daead6e]
- **請簡述一下 Webpack 和 Vite 最主要的差別是什麼？** — 待練習 | 型別: 觀念題 | 難度: 中等  ^[notion:9b7633bf]
- **如何說服成熟專案導入？可能阻力** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:16dc7946]
- **什麼是 Story？如何為元件撰寫？** — 難度: 中等 | 待練習 | 型別: 觀念題  ^[notion:c5474ea6]
- **如何進行自動化測試？** — 難度: 中等 | 待練習 | 型別: 觀念題  ^[notion:c9b42a28]
- **為什麼導入？它解決了什麼問題？** — 待練習 | 型別: 觀念題 | 難度: 中等  ^[notion:f54517e8]
- **「Tree-shaking」的原理是什麼？它為什麼依賴 ES Modules？** — 難度: 中等 | 待練習 | 型別: 觀念題  ^[notion:ba2b7c19]
- **為什麼 Vue 3 改用 Proxy 實作響應式？和 Vue 2 的 Object.defineProperty 有什麼差異？** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:70be2ddb]
- **Virtual Scroll 面試重點**  ^[notion:32a1cb73]
- **Vue 2 Reactive Form — 面試重點整理** — 待練習 | 型別: 觀念題  ^[notion:32a1cb73]
- **SEO 排名追蹤 SaaS｜技術深度介紹框架** — 難度: 中等 | 待練習 | 型別: 觀念題  ^[notion:32f1cb73]
- **Nuxt SSR 核心概念（面試題整理）** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:32f1cb73]
- **nextTick**  ^[notion:33b1cb73]
- **ssrRef  vs  ref**  ^[notion:33c1cb73]
- **useFetch**  ^[notion:33c1cb73]
- **Untitled**  ^[notion:33c1cb73]
- **在什麼情況下你仍然會考慮選擇 Webpack？** — 待練習 | 型別: 系統設計 | 難度: 中等  ^[notion:af106d94]
- **客製化 main.js：動機與設定** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:3f1dc95b]
- **如何維持 stories 與程式碼長期同步** — 待練習 | 型別: 觀念題 | 難度: 中等  ^[notion:892f4c71]
- **效能優化：專案龐大、啟動與載入變慢時** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:b1e378c6]
- **常用 Addons（除 Controls、Actions 之外）** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:caaf7773]
- **什麼是元件驅動開發（CDD）？與 Storybook 的關係？** — 難度: 中等 | 待練習 | 型別: 觀念題  ^[notion:0b368a35]
- **什麼是互動測試？與 Jest/RTL 差異** — 難度: 中等 | 待練習 | 型別: 觀念題  ^[notion:1cfcc225]
- **什麼是 Decorators？常見使用情境** — 待練習 | 型別: 觀念題 | 難度: 中等  ^[notion:336ca532]
- **什麼是視覺化迴歸測試？原理** — 待練習 | 型別: 觀念題 | 難度: 中等  ^[notion:56813592]
- **如何改善開發者、設計與 PM 的協作？** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:8bcb73de]
- **Controls 與 Actions 的用途與範例** — 待練習 | 型別: 觀念題 | 難度: 中等  ^[notion:96831b4b]
- **如何展示內部狀態與非同步資料** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:9c427368]
- **Vite 為什麼要對 node_modules 進行預先建置（Pre-bundling）？** — 型別: 觀念題 | 難度: 中等 | 待練習  ^[notion:efbc0b12]
- **「程式碼分割 (Code Splitting)」的目的是什麼？它和 Tree-shaking 有何不同？** — 待練習 | 型別: 觀念題 | 難度: 中等  ^[notion:0091b3bd]

