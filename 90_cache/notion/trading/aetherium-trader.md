---
notion_id: 2af1cb73-7bce-80bf-a9b9-d9a52728df09
source_url: https://www.notion.so/Aetherium-Trader-2af1cb737bce80bfa9b9d9a52728df09
fetched_at: 2026-04-14
---

# Aetherium Trader

#### 文件版本（Version Docs）

> 用這個資料庫管理同一個專案的不同版本設計文件，例如 v0.1 / v0.2 / v1.0。

---

#### 1. 專案簡介

- 專案名稱：Aetherium Trader
- 背景：為了練習與驗證各種交易策略（特別是手動操作與交易決策），需要一個可控、可回放、且不受實際券商限制的交易模擬與回測環境，同時又要能在真實資料源（例如 IB）嚴格限流的情況下穩定擷取行情。
- 目標：設計並實作一個高效能、具分散式擴展能力的交易模擬與回測平台，初期聚焦在「手動練習」體驗與「資料擷取的健壯性」，後續可擴充自動化策略與更多資料源。
- 成功指標（metrics）：
	- 在練習模式下，Tick 串流與下單互動延遲維持在可接受範圍（人眼感受接近即時，無明顯卡頓）。
	- 在券商 API 嚴格 Rate Limit（例如 60 req/10 分鐘）的前提下，分散式擷取仍能長時間穩定運作，錯誤可恢復且不遺漏資料。
	- 系統架構可平行擴展（擷取 Worker 與後端節點可水平擴充），不被單一服務綁死。

- 範圍：
	- In scope：
		- 建立分散式資料擷取平台（Scheduler / Worker / Token Bucket / Checkpoint 機制）。
		- 設計 Tick/MarketData 的儲存與載入流程（Parquet + ClickHouse + NAS/S3）。
		- 實作 TradingCore（交易核心）與 SimulationBackend（模擬後端）的主要互動流程。
		- 提供手動練習用的基本前端介面（K 線、下單、回放控制）。

	- Out of scope：
		- 真實金流結算與接券商實單下單（目前僅限模擬環境）。
		- 複雜風控規則、合規性檢查與多帳戶資金管理。
		- 多租戶 SaaS 化與對外商用部署（當前僅為個人/實驗性質系統）。



---

#### 2. 高層設計概觀

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

#### 3. 詳細設計

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

#### 4. 非功能需求

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

#### 5. 設計決策紀錄（ADR）

> 每個重大決策可以用列表或子頁表示

- 決策 1：主題
	- 背景：
	- 考慮過的選項：
	- 最後選擇：
	- 理由：

- 決策 2：主題
	- …


---

#### 6. 風險與未解問題

- 已知風險：
- 未解問題 / 待確認事項：
- 之後可能的擴充方向：

---

#### 7. 里程碑與實作連結

- Milestones：
	- M1：設計完成 & Review
	- M2：第一階段上線
	- …

- Issue / 任務連結：
	- GitHub / Jira / 個人任務中心連結



## 📊 系統設計文件

- **v1.2** — Stage: Draft  ^[notion:2af1cb73]


## 📊 Ingestion Platform

- **2.4** — Stage: Final  ^[notion:2af1cb73]
- **2.3** — Stage: Draft  ^[notion:895ee4e8]
- **2.2** — Stage: Draft  ^[notion:a91e8c70]
- **2.1**  ^[notion:2af1cb73]

