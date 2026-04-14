# Knowledge Forge Agents

自動化 agent prompts，設計為平台無關的純指令文件。

## Agents

| Agent | 頻率 | 用途 |
|-------|------|------|
| `daily-sync.md` | 每天 | Notion → 90_cache 同步 + changelog |
| `daily-check-in.md` | 每天 | 掃描 vault + Notion 狀態，產出提醒與問題 |
| `weekly-refine.md` | 每週 | 90_cache → 03_notes/04_playbooks 知識提煉 |

## 設計原則

- **純指令**：每個 `.md` 只描述「要做什麼」，不綁定任何 CLI 或平台
- **自包含**：prompt 包含完整上下文，不依賴外部對話歷史
- **平台無關**：任何能讀 prompt + 操作檔案系統的 agent runner 都能用
- **安全**：只寫入指定目錄（`00_inbox/`、`03_notes/`、`04_playbooks/`、`90_cache/`），不刪除手動內容
- **可觀察**：每次執行產出 log 到 `00_inbox/`

## 執行順序

若同時觸發多個 agent，建議：

1. `daily-sync` → 先拉最新資料
2. `daily-check-in` → 基於最新資料產出提醒
3. `weekly-refine`（僅週觸發）→ 基於累積的 cache 做提煉

## 如何接入

這些 prompt 是純文字指令。排程器只需要：
1. 讀取對應的 `.md` 檔作為 agent prompt
2. 將 vault root 設為工作目錄
3. 確保 agent 有檔案系統讀寫權限和 Notion API 存取能力