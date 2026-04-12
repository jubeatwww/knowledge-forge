# forge-sync

Notion → Obsidian cache sync tool.
讀取 `02_sources/` 下的 source stubs，透過 Notion API 拉內容存到 `90_cache/`。

## Setup

1. 到 https://www.notion.so/my-integrations 建立 internal integration，取得 token
2. 在 Notion 把要同步的頁面分享給該 integration
3. 設定環境變數：`export NOTION_TOKEN=ntn_xxx`

## Usage

```bash
# 列出所有 sources（不需要 token）
forge-sync list

# 拉一個 source stub 對應的頁面
forge-sync pull 02_sources/system-design/system-design-reading-tracker.md

# 拉所有 sync_policy=on-demand 的 sources
forge-sync pull-all

# 直接用 notion_id 拉一個頁面到指定路徑
forge-sync pull-page <notion-id> <output-path>

# 查看某頁底下有哪些 child databases
forge-sync index <notion-page-id>
```

Binary 在 `.forge/bin/forge-sync.exe`，可直接執行。
也可以設 `VAULT_ROOT` 環境變數指定 vault 根目錄（預設從 cwd 往上找 `AGENTS.md`）。

## Build

```bash
cd .forge/tools/forge-sync
go build -o ../../bin/forge-sync.exe .
```

需要 Go 1.21+，無外部依賴。