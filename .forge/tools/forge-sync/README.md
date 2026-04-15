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

# 從某個 database 的 INDEX.md 挑一筆 entry，升成可本地維護的 source stub
forge-sync promote 02_sources/system-design/system-design-reading-tracker/scalability/INDEX.md https://www.notion.so/...

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
- `database`：建立 database stub；若 `expand_items: true`，再額外產生 entry 清單的 `INDEX.md`
- `inline_databases`：建立 root page stub + child database stubs；若 `expand_items: true`，child database 也會再額外產生 entry 清單的 `INDEX.md`
- `database_items`：直接把 database entries 寫進一個 folder `INDEX.md`

`expand_items: true` 只會展開索引，不會再為每個 entry 建一個 `.md`。`02_sources/` 會保留 root/database stub 與對應資料夾的 `INDEX.md`，讓你可以直接沿著索引往下走，不必先 `pull` database，也不會把 vault 膨脹成 page mirror。

如果某筆 entry 值得留下本地 stub，再用 `forge-sync promote <index> <notion-url-or-id>` 單獨升級。被 promote 的 entry 之後會優先連到本地 stub，而不是 Notion URL。

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
