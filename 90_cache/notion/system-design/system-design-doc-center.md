---
notion_id: 2af1cb73-7bce-8074-ae83-ca8a0bdf7852
source_url: https://app.notion.com/p/2af1cb737bce8074ae83ca8a0bdf7852
fetched_at: 2026-04-14
---

# 系統設計文件中心

這個 workspace 用來集中管理所有專案的設計文件與相關說明。

---

#### 如何使用這個空間

1. 在下方 **🧩 Projects** 資料庫中新增一筆專案。
2. 為每個專案建立一個專屬頁面（主設計文件），並把連結填到 `Main Doc` 欄位。
3. 在專案頁面裡撰寫系統設計、API 規格、資料庫設計、流程圖、非功能需求等內容。
4. 透過 `Status`、`Priority`、`Tag` 來管理與篩選專案。

> 建議把真的會長期維護的專案都放進來，這裡可以當成你的「設計文件首頁」。

---

#### 專案清單

---

#### 推薦的專案頁結構（可以複製到新專案頁）

```markdown
### 1. 專案簡介

- 背景：
- 目標：
- 成功指標（metrics）：
- 範圍：
  - In scope：
  - Out of scope：

---

### 2. 高層設計概觀

- 系統架構圖：
  - （貼圖片或連結）
- 主要模組：
  - 模組 A：職責 / 介面簡述
  - 模組 B：職責 / 介面簡述
- 主要資料流 / User flow：
  - Flow 1：簡述
  - Flow 2：簡述
- 依賴服務 / 外部系統：
  - 服務名稱、用途、風險

---

### 3. 詳細設計

#### 3.1 API 設計

- 服務名稱：
- 主要 API 列表（可用表格或子頁）
  - Method / Path / 說明
  - Request schema
  - Response schema
  - Error code

#### 3.2 資料庫與資料模型

- 主要資料表 / Collection：
  - Table: xxx
    - 欄位、型別、約束
- Index / Query pattern：
- 一致性與交易考量：

#### 3.3 流程與時序

- 關鍵流程時序圖：
  - 建議用圖，文字補充 edge cases
- 失敗與重試策略：
- 併發與鎖定策略（如果有）：

---

### 4. 非功能需求

- 效能：
  - QPS / 延遲目標：
  - 預估流量與容量：
- 可用性與容錯：
  - SLA 目標：
  - Failover / 災難復原策略：
- 安全性：
  - 身分驗證 / 授權：
  - 資料加密與隱私：
- 可觀察性：
  - Log / Metrics / Tracing 設計：

---

### 5. 設計決策紀錄（ADR）

- 決策 1：主題
  - 背景：
  - 考慮過的選項：
  - 最後選擇：
  - 理由：
- 決策 2：主題
  - …

---

### 6. 風險與未解問題

- 已知風險：
- 未解問題 / 待確認事項：
- 之後可能的擴充方向：

---

### 7. 里程碑與實作連結

- Milestones：
  - M1：設計完成 & Review
  - M2：第一階段上線
  - …
- Issue / 任務連結：
  - GitHub / Jira / 個人任務中心連結
```



## 📊 Projects

- **Aetherium Trader**  ^[notion:2af1cb73]
- **字耕者**  ^[notion:2e91cb73]
- **Ranking App**  ^[notion:2ee1cb73]
- **晴貓代購**  ^[notion:3181cb73]

