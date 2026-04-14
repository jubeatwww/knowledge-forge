---
notion_id: 2911cb73-7bce-8023-998d-fb7cd6563732
source_url: https://app.notion.com/p/2911cb737bce8023998dfb7cd6563732
fetched_at: 2026-04-14
---

# 後端面試題庫

## 一般技術面試問題


> ⚡ 操作速查：新增材料 → 建題並連材料 → 把追問掛到 Parent item → 用 Kanban 與 Review Calendar 推進

> 本頁目標：讓你能快速「蒐集材料 → 建課次 → 建題與追問 → 練習與回顧」，並支援「材料 ↔ 課次 ↔ 題目」三向檢索。

---

#### 快速開始

- 第 1 步：把剛看完的內容新增到「學習材料與筆記」，填 Type、Source URL、重點 Notes，打上 Tags、Area、Subtopic。
- 第 2 步：若是系列課，改在「課程」建立章節卡（Series、Lesson No.、Source URL、Notes、Next Review）。
- 第 3 步：在「面試題練習」建立對應題目與追問（Parent item 連主題），並用 Relation 連回材料或課次。
- 第 4 步：用 Kanban 管理進度，用 Review／Calendar 視圖安排回顧。

> 🧭 善用三個資料庫的 Relation：

### 內容

#### 📚 學習材料與筆記

---

#### 🎓 課程

---

#### 🧪 面試題練習

---

### 附錄

#### 常用操作範本

#### 新增材料（Article / Video / Paper / Doc / Talk / Spec）

#### 新增題目（Fundamentals / Redis / Trade-offs）

---

#### 使用小技巧

- 建立追問時，直接在 Follow-ups 視圖新增，Parent item 會更直覺。
- 回顧節奏建議：新題 3-7-14 天；困難題可在 Reviewing 狀態下加密回顧。
- 連結多個材料到同一題目，方便交叉比對不同觀點。

---

#### 題目圖示對應表

> 🧭 之後新增題目時，我會依下表自動套用圖示。若要微調，告訴我即可。

| Category | Icon | 說明 |
| --- | --- | --- |
| Fundamentals | 📘 | 基礎概念與通用原理 |
| Trade-offs | ⚖️ | 權衡、取捨、場景選型 |
| Redis | 🧰 | Redis 機制與實務（可改成你偏好的符號） |
| Consensus／Paxos | 🗳️ | 共識演算法、選舉與提交規則 |



## 📊 學習材料與筆記

- **Uber Marketplace Meetup: Using Distributed Locking to Build Reliable Systems** — Area: Scalability | Type: Talk | [link](https://www.youtube.com/watch?v=OAWBOAI3bK8) | 初步理解（Q&A） | Subtopic: Distributed Locking  ^[notion:74ee1331]
- **The Chubby lock service for loosely coupled distributed systems** — [link](https://blog.acolyer.org/2015/02/13/the-chubby-lock-service-for-loosely-coupled-distributed-systems/) | Area: Scalability | Type: Article | Subtopic: Distributed Locking | 初步理解（Q&A）  ^[notion:0e943c18]
- **The Twelve-Factor App** — [link](https://12factor.net/) | Area: Principle | Type: Article | 已完成  ^[notion:9313761a]


## 📊 課程

- **02  该如何选择消息队列？** — Done | Series: 消息队列高手课  ^[notion:f6953ccd]


## 📊 面試題練習

- **什麼是競爭條件（Race Condition）？** — To Do | Category: Fundamentals  ^[notion:b04f3954]
- **CAP 定理中的 C/A/P 是什麼？** — To Do | Category: Fundamentals  ^[notion:cdea2b9f]
- **在分散式系統中鎖（Lock）的目的是什麼？** — To Do | Category: Fundamentals  ^[notion:8355278c]
- **什麼是分片（Sharding）？一致性雜湊相對 Hash Mod 的優點？** — To Do | Category: Fundamentals  ^[notion:546b7943]
- **Primary-Replica 與 Multi-Master 的差異與故障下可靠性比較** — Category: Fundamentals | To Do  ^[notion:93632ac8]
- **如何用 Redis 實作分散式鎖？核心指令是什麼？** — To Do | Category: Redis  ^[notion:56c7d296]
- **為什麼 Redis 鎖需要 TTL？** — To Do | Category: Redis  ^[notion:35a7a640]
- **Redis Sentinel 的主要功能與解決的問題** — To Do | Category: Redis  ^[notion:95c946a2]
- **Redis 的 AOF 與 RDB 差異是什麼？** — To Do | Category: Redis  ^[notion:39f0740c]
- **記憶體型（Redis）與硬碟型（Cassandra）資料庫性能差異** — Category: Trade-offs | To Do  ^[notion:b3457ec8]
- **為何強一致場景（金融支付）可能選 Cassandra 來做鎖？** — Category: Trade-offs | To Do  ^[notion:cbdeaccb]
- **哪些業務場景適合用 Redis 來做分散式鎖？** — Category: Trade-offs | To Do  ^[notion:71b5d337]
- **當說鎖「不夠可靠」時，我們在擔心哪些風險？** — Category: Trade-offs | To Do  ^[notion:773272c6]
- **Chubby 追求高可靠性的效能權衡是什麼？適合哪一類型的鎖？** — Category: Trade-offs | To Do  ^[notion:5112ec49]
- **什麼是「腦裂（Split-Brain）」？像 Chubby 這樣的服務如何避免？** — To Do | Category: Fundamentals  ^[notion:6a51a60a]
- **在分散式系統中，為什麼需要像 Chubby 這樣的鎖服務？它解決了什麼根本性問題？** — To Do | Category: Fundamentals  ^[notion:70d25791]
- **需要極低延遲與高頻鎖操作時，是否推薦 Chubby？替代方案考量？** — To Do | Category: Trade-offs  ^[notion:abf09c76]
- **為什麼鎖服務需要共識（Paxos）？共識在 Chubby 中的關鍵性？** — To Do | Category: Fundamentals  ^[notion:b531818a]
- **如何用分散式鎖設計主節點選舉？請描述故障轉移（Failover）流程。** — To Do | Category: Fundamentals  ^[notion:cea41638]
- **相較輪詢（Polling），Chubby 提供了什麼更有效率的通知機制？** — Category: Fundamentals | To Do  ^[notion:dfd8c89c]
- **Chubby 如何偵測並處理客戶端故障？會話（Session）與租約（Lease）的角色是什麼？** — To Do | Category: Fundamentals  ^[notion:dfdb01d0]
- **什麼是「無狀態 (Stateless)」應用程式？為什麼在設計可擴展的系統時，保持無狀態是如此重要？** — Category: Fundamentals | To Do  ^[notion:3a5a3d98]
- **請解釋 CI/CD 流程中的「建構 (Build)」、「發行 (Release)」和「執行 (Run)」三個階段有何不同？為什麼嚴格區分它們很重要？** — Category: Fundamentals | To Do  ^[notion:5105e9ca]
- **「開發環境」與「生產環境」不一致最常導致什麼問題？你會如何縮小兩者之間的差距？** — To Do | Category: Fundamentals  ^[notion:573e4792]
- **為什麼現代雲端應用程式傾向於將 Log 當作「事件串流 (Event Stream)」寫入標準輸出 (stdout)，而不是自己管理日誌檔案？** — To Do | Category: Fundamentals  ^[notion:83850cfd]
- **什麼是「優雅關機 (Graceful Shutdown)」？它對於確保系統在部署更新時的穩定性有何作用？** — Category: Fundamentals | To Do  ^[notion:ab91b587]
- **描述「水平擴展 (Scaling out)」和「垂直擴展 (Scaling up)」的區別。十二因子方法論推薦哪一種，為什麼？** — To Do | Category: Fundamentals  ^[notion:b4f62bbc]
- **為什麼我們應該將資料庫密碼、API 金鑰等「設定 (Config)」從程式碼中分離，並改用環境變數來管理？** — To Do | Category: Fundamentals  ^[notion:be122f8e]
- **在微服務架構中，為什麼應該將資料庫或快取系統這類「後端服務 (Backing Services)」視為可隨時替換的「附加資源」？** — Category: Fundamentals | To Do  ^[notion:feda8fdb]
- **如果團隊需要為非核心系統快速引入 MQ，且團隊對 MQ 不太熟悉，你會推薦哪一款？理由是什麼？** — To Do | Category: Trade-offs  ^[notion:86ddc927]
- **如果首要考量是處理線上交易、要求極低的響應延遲，在 Kafka 和 RocketMQ 之間如何選擇？為什麼？** — To Do | Category: Trade-offs  ^[notion:078f675b]
- **RabbitMQ 在處理哪種特定情況時，性能會急遽下降？** — Category: Fundamentals | To Do  ^[notion:261ca197]
- **請從吞吐量（throughput）和延遲（latency）兩個維度，比較 RabbitMQ、RocketMQ 和 Kafka 的性能差異** — To Do | Category: Trade-offs  ^[notion:2cca7a04]
- **RocketMQ 主要針對哪一類的業務場景進行了優化，其最顯著的優點是什麼？** — To Do | Category: Fundamentals  ^[notion:497a13e3]
- **在 RabbitMQ 和 Kafka 之間，哪一個更適合與大數據、流計算生態（如 Flink）整合？為什麼？** — Category: Trade-offs | To Do  ^[notion:57308c8b]
- **RabbitMQ 的核心設計哲學是什麼？它最適合用在什麼樣的場景？** — To Do | Category: Fundamentals  ^[notion:99d6fbda]
- **為了達到極致的吞吐量，Kafka 在設計上做出了哪些權衡取捨？** — Category: Trade-offs | To Do  ^[notion:bd0f79b3]
- **有同事說「Kafka 不可靠、會丟失訊息」，你該如何回應這個說法？** — Category: Fundamentals | To Do  ^[notion:be3deeb5]
- **一款合格的現代消息佇列，必須具備哪三個基本特性？** — To Do | Category: Fundamentals  ^[notion:c9e4c547]
- **Kafka 最初的設計目標是什麼？這個起源如何影響它現今的核心優勢？** — To Do | Category: Fundamentals  ^[notion:df994561]
- **在節點故障時，哪種架構的可靠性更高？為什麼？** — To Do | Category: Fundamentals  ^[notion:3088edd5]
- **如果持鎖客戶端的任務執行時間超過鎖的 TTL，會發生什麼問題？** — Category: Redis | To Do  ^[notion:13b0c3d2]
- **為何在雲端系統中 P（分割容忍度）通常必須？** — Category: Fundamentals | To Do  ^[notion:47c99755]
- **你認為使用 AOF 模式的 Redis，是否就足以保證分散式鎖的絕對可靠性？請說明你的觀點** — To Do | Category: Redis  ^[notion:453174da]

