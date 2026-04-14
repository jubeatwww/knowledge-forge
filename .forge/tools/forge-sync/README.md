# forge-sync

Notion → Obsidian cache sync tool.

現在有兩條路：
- `sync-sources`：從 `.forge/source-discovery.json` 自動 upsert `02_sources/`
- `pull` / `pull-all`：把 `02_sources/` 裡的 source stubs 拉到 `90_cache/`

## Setup

1. 到 https://www.notion.so/my-integrations 建立 internal integration，取得 token
2. 在 Notion 把要同步的頁面分享給該 integration
3. 設定 token

可用 shell env，或把 `.forge/forge-sync.env.example` 複製成以下任一檔：
- `.env`
- `.forge/.env`
- `.forge/forge-sync.env`

## Usage

```bash
# 先把 source discovery config 同步到 02_sources/
forge-sync sync-sources

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

Discovery config 預設讀 `.forge/source-discovery.json`。
也可以設 `FORGE_SYNC_SOURCE_CONFIG` 指到別的檔案。

常用 discovery rule：
- `page`：只建立單一 page stub
- `database`：建立 database stub；若 `expand_items: true`，再往下展開每個 entry
- `inline_databases`：建立 root page stub + child database stubs；若 `expand_items: true`，child database 也會再往下展開 entry
- `database_items`：直接把 database entries 展成一層 sources

`expand_items: true` 會讓 `02_sources/` 產生對應資料夾與 `INDEX.md`，讓你可以直接沿著索引往下走，不必先 `pull` database 才知道裡面有什麼。

Binary 放在 `.forge/bin/`。
也可以設 `VAULT_ROOT` 指定 vault 根目錄（預設從 cwd 往上找 `AGENTS.md`）。

## Build

```bash
cd .forge/tools/forge-sync
make build
make build-all
```

預設會加 `-trimpath -ldflags="-s -w"`，縮小 binary 體積。

需要 Go 1.21+，無外部依賴。
