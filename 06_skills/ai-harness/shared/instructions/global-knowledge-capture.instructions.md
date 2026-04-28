# Global Knowledge Forge Integration

## Core Behavior

### 在 Vault 內
- 檢測到知識完成（問題解決、決策做出、工作流驗證、學習成果）
- **自動存進 vault**，告訴用戶「✓ 已存」

### 不在 Vault 內
- 檢測到知識
- **問一次**：「要存進知識庫嗎？vault 在哪裡？」
- 用戶回答 → 存 或跳過
- 用戶說「不要」→ 當沒有，繼續

## What Gets Captured

1. **問題解答** — bug 修復、debug 結論、技術方案驗證
2. **決策** — 架構決策、技術選型、工作流決策 + 理由
3. **工作流程** — 可重用操作步驟、最佳實踐、SOP
4. **研究筆記** — 新技術學習、API 文檔提煉、調查發現
5. **文件摘要** — 複雜文件的精簡版、架構圖說明

## Vault Detection

**啟動時檢查**（看是否在 Knowledge Forge vault 內）：
```
同時存在：
- AGENTS.md
- 00_inbox/
- 02_sources/
- 90_cache/
```

- ✓ 都存在 → 在 vault 內，使用「自動存」模式
- ✗ 不都存在 → 不在 vault 內，使用「問一次」模式

## Auto-Save (在 Vault 內)

當對話中出現知識完成點：
1. 自動判斷類型（問題解答 / 決策 / 工作流程 / 研究筆記 / 文件摘要）
2. 自動選位置（預設 00_inbox/capture-YYYY-MM-DD-HHmmss.md）
3. 自動存檔
4. 簡短回報：`✓ 已存：[知識類型] 存進 00_inbox/`

## Ask Once (不在 Vault 內)

當對話中出現知識完成點，問一次：

> 💾 要存進知識庫嗎？你的 vault 在哪裡？

- 用戶提供路徑 → 存進去
- 用戶說「不要」/ 無回應 → 當沒有，繼續聊
- 同一對話中**不重複問**

## Never Ask If

- 用戶已明確說過「不要」「先放著」
- 對話在修改 Knowledge Forge 本身
- 純代碼補全或臨時測試
- 對話進行中未結束

## File Format

```yaml
---
title: <自動生成的簡潔標題>
kind: capture
date: <YYYY-MM-DD>
types: [問題解答, 決策]  # 實際類型
---

## 摘要
<一句話要點>

## 內容
<整理後的知識>

---
*存檔於 Copilot 對話*
```

## Summary

| 場景 | 行為 |
|------|------|
| 在 vault 內，知識完成 | 自動存，說「✓ 已存」 |
| 不在 vault，知識完成 | 問一次「要存嗎？路徑？」|
| 用戶說「不要」| 當沒有，往前走 |
| 對話進行中 | 等結束點再動作 |
