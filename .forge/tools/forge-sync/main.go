package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

const usage = `forge-sync — Notion → Obsidian cache sync tool

Usage:
  forge-sync pull [source-stub-path...]   Pull specific sources into 90_cache/
  forge-sync pull-all                     Pull all sources with sync_policy=on-demand
  forge-sync pull-page <notion-id> <out>  Pull a single Notion page to a file
  forge-sync list                         List all sources and cache status
  forge-sync index <notion-page-id>       Fetch a Notion page and print its child databases

Environment:
  NOTION_TOKEN    Notion integration token (required)
  VAULT_ROOT      Vault root directory (default: current directory)
`

func main() {
	if len(os.Args) < 2 {
		fmt.Print(usage)
		os.Exit(1)
	}

	vaultRoot := os.Getenv("VAULT_ROOT")
	if vaultRoot == "" {
		var err error
		vaultRoot, err = findVaultRoot()
		if err != nil && os.Args[1] != "index" {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
	}

	// Commands that don't need Notion API
	switch os.Args[1] {
	case "list":
		if err := cmdList(vaultRoot); err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
		return
	}

	// Commands below require NOTION_TOKEN
	token := os.Getenv("NOTION_TOKEN")
	if token == "" {
		fmt.Fprintln(os.Stderr, "error: NOTION_TOKEN environment variable is required")
		fmt.Fprintln(os.Stderr, "  Get one at: https://www.notion.so/my-integrations")
		os.Exit(1)
	}
	client := &NotionClient{Token: token}

	switch os.Args[1] {
	case "pull":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "error: pull requires at least one source stub path")
			os.Exit(1)
		}
		for _, path := range os.Args[2:] {
			if err := cmdPull(client, vaultRoot, path); err != nil {
				fmt.Fprintf(os.Stderr, "error pulling %s: %v\n", path, err)
			}
		}
	case "pull-all":
		if err := cmdPullAll(client, vaultRoot); err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
	case "pull-page":
		if len(os.Args) < 4 {
			fmt.Fprintln(os.Stderr, "error: pull-page requires <notion-id> <output-path>")
			os.Exit(1)
		}
		if err := cmdPullPage(client, os.Args[2], os.Args[3]); err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
	case "index":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "error: index requires a Notion page ID")
			os.Exit(1)
		}
		if err := cmdIndex(client, os.Args[2]); err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
	default:
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", os.Args[1])
		fmt.Print(usage)
		os.Exit(1)
	}
}

// findVaultRoot walks up from cwd looking for AGENTS.md (vault marker).
func findVaultRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "AGENTS.md")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return "", fmt.Errorf("cannot find vault root (no AGENTS.md found). Set VAULT_ROOT or run from inside the vault")
}

func cmdPull(client *NotionClient, vaultRoot, stubPath string) error {
	// Make path absolute if relative
	if !filepath.IsAbs(stubPath) {
		stubPath = filepath.Join(vaultRoot, stubPath)
	}

	stub, err := ParseSourceStub(stubPath)
	if err != nil {
		return fmt.Errorf("parse stub: %w", err)
	}

	if stub.NotionID == "" {
		return fmt.Errorf("no notion_id in %s", stubPath)
	}

	fmt.Printf("pulling %s (notion_id: %s)...\n", stub.Title, stub.NotionID)

	// Fetch the page
	page, err := client.GetPage(stub.NotionID)
	if err != nil {
		return fmt.Errorf("fetch page: %w", err)
	}

	// Fetch child blocks
	blocks, err := client.GetBlockChildren(stub.NotionID)
	if err != nil {
		return fmt.Errorf("fetch blocks: %w", err)
	}

	// Check for child databases — if present, also fetch their entries
	var dbSections []DatabaseSection
	for _, b := range blocks {
		if b.Type == "child_database" {
			dbID := b.ID
			title := b.ChildDatabase.Title
			fmt.Printf("  fetching database: %s...\n", title)
			entries, err := client.QueryDatabase(dbID)
			if err != nil {
				fmt.Fprintf(os.Stderr, "  warning: could not query database %s: %v\n", title, err)
				continue
			}
			dbSections = append(dbSections, DatabaseSection{
				Title:   title,
				ID:      dbID,
				Entries: entries,
			})
		}
	}

	// Convert to markdown
	md := RenderPage(page, blocks, dbSections)

	// Determine cache path
	cachePath := stubToCachePath(vaultRoot, stubPath, stub)
	cacheDir := filepath.Dir(cachePath)
	if err := os.MkdirAll(cacheDir, 0755); err != nil {
		return fmt.Errorf("create cache dir: %w", err)
	}

	if err := os.WriteFile(cachePath, []byte(md), 0644); err != nil {
		return fmt.Errorf("write cache: %w", err)
	}

	// Update stub metadata
	if err := UpdateStubStatus(stubPath, "cached"); err != nil {
		fmt.Fprintf(os.Stderr, "  warning: could not update stub status: %v\n", err)
	}

	fmt.Printf("  cached → %s\n", relPath(vaultRoot, cachePath))
	return nil
}

func cmdPullAll(client *NotionClient, vaultRoot string) error {
	sourcesDir := filepath.Join(vaultRoot, "02_sources")
	stubs, err := FindSourceStubs(sourcesDir)
	if err != nil {
		return err
	}

	pulled := 0
	for _, stubPath := range stubs {
		stub, err := ParseSourceStub(stubPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "skip %s: %v\n", stubPath, err)
			continue
		}
		if stub.SyncPolicy != "on-demand" {
			continue
		}
		if stub.NotionID == "" {
			continue
		}
		if err := cmdPull(client, vaultRoot, stubPath); err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
		} else {
			pulled++
		}
	}
	fmt.Printf("\npulled %d source(s)\n", pulled)
	return nil
}

func cmdList(vaultRoot string) error {
	sourcesDir := filepath.Join(vaultRoot, "02_sources")
	stubs, err := FindSourceStubs(sourcesDir)
	if err != nil {
		return err
	}

	fmt.Printf("%-40s %-15s %-12s %s\n", "TITLE", "SYNC_POLICY", "CACHE", "NOTION_ID")
	fmt.Println(strings.Repeat("-", 100))

	for _, stubPath := range stubs {
		stub, err := ParseSourceStub(stubPath)
		if err != nil {
			continue
		}
		if stub.Source != "notion" {
			continue
		}
		shortID := stub.NotionID
		if len(shortID) > 12 {
			shortID = shortID[:12] + "..."
		}
		fmt.Printf("%-40s %-15s %-12s %s\n",
			truncate(stub.Title, 39),
			stub.SyncPolicy,
			stub.CacheStatus,
			shortID,
		)
	}
	return nil
}

func cmdIndex(client *NotionClient, pageID string) error {
	pageID = strings.ReplaceAll(pageID, "-", "")

	fmt.Printf("fetching page %s...\n\n", pageID)

	blocks, err := client.GetBlockChildren(pageID)
	if err != nil {
		return err
	}

	for _, b := range blocks {
		switch b.Type {
		case "child_database":
			fmt.Printf("  [database] %s\n", b.ChildDatabase.Title)
			fmt.Printf("             id: %s\n\n", b.ID)
		}
	}
	return nil
}

func cmdPullPage(client *NotionClient, notionID, outPath string) error {
	notionID = strings.ReplaceAll(notionID, "-", "")
	fmt.Printf("pulling page %s...\n", notionID)

	page, err := client.GetPage(notionID)
	if err != nil {
		return fmt.Errorf("fetch page: %w", err)
	}

	blocks, err := client.GetBlockChildren(notionID)
	if err != nil {
		return fmt.Errorf("fetch blocks: %w", err)
	}

	md := RenderPage(page, blocks, nil)

	dir := filepath.Dir(outPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("create dir: %w", err)
	}

	if err := os.WriteFile(outPath, []byte(md), 0644); err != nil {
		return fmt.Errorf("write file: %w", err)
	}

	fmt.Printf("  → %s\n", outPath)
	return nil
}

func stubToCachePath(vaultRoot, stubPath string, stub *SourceStub) string {
	// 02_sources/system-design/foo.md → 90_cache/notion/system-design/foo.md
	rel, _ := filepath.Rel(filepath.Join(vaultRoot, "02_sources"), stubPath)
	return filepath.Join(vaultRoot, "90_cache", "notion", rel)
}

func relPath(base, path string) string {
	rel, err := filepath.Rel(base, path)
	if err != nil {
		return path
	}
	return rel
}

func truncate(s string, max int) string {
	r := []rune(s)
	if len(r) <= max {
		return s
	}
	return string(r[:max-1]) + "…"
}