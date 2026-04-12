---
notion_id: 411b499d-9c6d-4371-81de-30d9ce5e761d
source_url: https://www.notion.so/411b499d9c6d437181de30d9ce5e761d
parent_database: Scalability
sub_topic: Distributed Messaging
reading_progress: AI Q&A initial understanding
original_link: https://netflixtechblog.com/timestone-netflixs-high-throughput-low-latency-priority-queueing-system-with-built-in-support-1abf249ba95f
fetched_at: 2026-04-12
---

# System Design 學習筆記：Netflix Timestone

**主題：** Timestone: Netflix's High-Throughput, Low-Latency Priority Queueing System
**學習日期：** 2025/12/09
**核心概念：** Priority Queue, Linearizable Consistency, Exclusive Queue, Redis + Lua, CQRS

## 導讀：為什麼我們在這裡？(Context)

Netflix 的媒體編碼平台 (Cosmos) 是一個巨大的影片加工廠。
- **輸入：** 片商提供的高畫質原始檔。
- **過程：** 轉檔、壓縮、切割（非常消耗算力與時間）。
- **問題：** 需要一個調度系統（輸送帶）來管理成千上萬個編碼任務。
- **現狀：** 現有的 Queue (Kafka, SQS) 無法滿足特定需求，因此 Netflix 造了 **Timestone**。

## 第一階段：需求分析 (Why build it?)

### 核心提問
**Q1: Netflix 提到現有 Queue 無法滿足 "Linearizable Consistency" 和 "Non-parallelizable work"。這兩個痛點具體是什麼？**

### 你的思考與回答
- Netflix 需要 Message Queue 的功能。
- 但目前的 Solution 無法保證 **Exactly Once**。
- 也無法限制 **只有一個** Consumer **讀取單個 Task**。

### 導師解析與修正
你的直覺是對的，我們將其轉化為更精確的 System Design 術語：
1. **Linearizable Consistency (線性一致性) vs. Exactly Once**
	- **痛點：** 一般 Queue 是最終一致性 (Eventually Consistent)。因為 Replication Lag，可能導致 Worker A 和 Worker B 同時拿到同一個任務。
	- **後果：** 影片編碼極其昂貴。重複派發 (Double Delivery) = 浪費大量算力與金錢。Netflix **無法承受**這種浪費。
2. **Exclusive Queue (獨占隊列) vs. Single Consumer**
	- **痛點：** 不只是「一個任務給一個人」，而是「**鎖住一整組相關任務**」。
	- **場景：** 決策引擎 (Plato) 正在處理 Project A 的邏輯時，必須確保沒有其他 Worker 能碰 Project A 的任何任務，否則狀態會錯亂（就像兩個醫生不能同時對同一個病人開刀）。

## 第二階段：架構設計 (System Architecture)

### 核心提問
**Q2: 為了實現上述的強一致性與原子性操作，System of Record (SoR) 選用了什麼資料庫？又是如何保證並發安全的？**

### 你的思考與回答
1. **資料庫：** Redis Cluster。
2. **並發機制：** Lua Script (Redis 的 atomic 腳本)。

### 導師解析
這是滿分的架構選型答案。
- **Redis + Lua Script = Lightweight Transaction.**
- Redis 執行 Lua 是單執行緒的 (Single-threaded execution)。
- 這保證了在同一微秒內，只有一個腳本能修改 Queue 的狀態，完美解決了 Race Condition，實現了強一致性。

## 第三階段：資料結構與索引 (Data Structures & CQRS)

### 核心提問
**Q3: (1) Redis 內部用什麼結構做優先級排序？ (2) Redis 外部如何處理複雜查詢（如 Metadata 過濾）？**

### 你的思考與回答
1. **內部結構：** Sorted Set。
2. **外部查詢：** 透過 Flink Jobs 處理。

### 導師解析
1. **Sorted Set (ZSET):** 正確。`Score` = Timestamp (Priority), `Member` = Message ID。存取效率 O(log N)。
2. **CQRS (Command Query Responsibility Segregation):**
	- 你的回答點出了處理過程，完整的資料流是：
	  `Redis (寫入/核心)` -> `Kafka` -> `Flink` -> `Elasticsearch (讀取/搜尋)`
	- **設計哲學：** 讓 Redis 專注於高吞吐量的隊列操作，讓 Elasticsearch 處理複雜的 Metadata 搜尋。

## 第四階段：核心邏輯 - 獨占隊列 (Exclusive Queues)

### 核心提問
**Q4: 假設 Worker 1 鎖住了 Project Foo。Worker 2 來請求任務，隊列頭部是 Project Foo 的任務，第二個才是 Project Bar。Worker 2 會拿到誰？這是否符合業務邏輯？**

### 你的思考與回答
- 會拿到 Project Bar 的任務 (`msg_2`)。
- 但在 Plato 的情境裡，這是不被允許的（這裡存在誤解）。

### 導師解析
這是一個關鍵的觀念轉折點。
- **行為：** Worker 2 跳過 `msg_1` (Foo)，拿到 `msg_2` (Bar)。這部分正確。
- **業務邏輯修正：** 這在 Plato 情境裡**是完全允許且被鼓勵的**。
	- **比喻：** 醫生 A 正在開病人 Foo（鎖住）。醫生 B 進來，系統叫他不要碰病人 Foo，去開旁邊的病人 Bar。
	- **精髓：** **Serial execution per key (針對特定 Key 序列化)** + **Parallel execution across keys (跨 Key 並行化)**。既保證安全，又維持工廠產能。

## 第五階段：狀態機與容錯 (Fault Tolerance)

### 核心提問
**Q5: 如果 Worker 拿了任務卻當機 (Crash)，任務會怎樣？**

### 你的思考與回答
1. 狀態變為 **Running**。
2. 超時沒有 Completed 就丟回 Queue。
3. 重試多次失敗進入 **ERRORED**。

### 導師解析
完全正確，這是標準的容錯機制：
- **Lease Mechanism (租約機制):** 保證 **At-least-once delivery**。Worker 死了，租約過期，任務自動復活 (變成 Pending)。
- **Dead Letter Queue (DLQ):** 無限失敗的任務移入 Errored 狀態，防止毒藥訊息 (Poison Pill) 卡死系統。

## 第六階段：深度探討與 Trade-offs (Deep Dive)

### 核心提問
**Q6:** (1) Redis 做為 SoR 會有掉資料風險嗎？ (2) Exclusive Queue 會造成 Head-of-Line Blocking 嗎？

### 你的思考與回答
1. **Redis 風險：** 有風險，但文件說有 Write-Ahead Log (WAL) 且寫入硬碟才回傳成功，所以有後備。
2. **Blocking 問題：** 會發生，代表整部影片要重來，不能平行化。但預處理任務不需要那麼及時（Latency 不敏感），正確性更重要。

### 導師解析
非常有深度的 Trade-off 分析。
1. **Latency vs. Durability:**
	- Netflix 強制 Redis 做 **Synchronous Persistence** (寫入硬碟才算成功)。
	- **代價：** 犧牲了 Write Latency (寫入變慢)。
	- **獲益：** 換取了 Durability (資料不丟失)，符合「昂貴任務」的業務需求。
2. **Throughput vs. Latency:**
	- Exclusive Queue 確實造成了針對單一 Project 的 **Head-of-Line Blocking**。
	- 但這是一個 **Throughput-oriented** 的系統。只要整體產出高，單一專案排隊久一點是可以接受的。

## 第七階段：未來優化 (Future Works)

### 核心提問
**Q7: Netflix 提到了哪兩個未來的瓶頸與解法？**

### 你的思考與回答
1. **Sharding** (解決單一 Queue 太大的問題)。
2. **改用字典序 (Lexicographical Ordering)** 來排序 Message (解決 Metadata 索引太大的問題)。

### 導師解析
1. **Queue Sharding:**
	- 解決 Hot Queue 撐爆單節點記憶體的問題。
	- **挑戰：** 跨 Shard 後，原本依賴的 Lua Script 原子性會失效，複雜度大增。
2. **Lexicographical Ordering:**
	- 原本多屬性過濾導致 O(2^n) 索引爆炸。
	- 解法：將屬性拼成字串 (e.g., `region:us:device:tv`)，利用 Redis ZSET 的 `ZRANGEBYLEX` 功能，將複雜度降回線性。

## 總結 (Key Takeaways)

在設計類似 Timestone 的高一致性隊列時：
1. **核心技術棧：** Redis (Storage) + Lua (Atomicity) + Sorted Set (Priority)。
2. **關鍵模式：**
	- **Exclusive Locking:** 用於保護業務邏輯狀態。
	- **CQRS:** 分離寫入 (Redis) 與查詢 (Elasticsearch)。
	- **Lease/DLQ:** 處理分佈式系統中的節點故障。
3. **取捨 (Trade-offs):** 為了資料不丟失 (Durability) 和狀態正確性 (Consistency)，可以犧牲寫入延遲 (Latency) 和部分並行度 (Parallelism)。