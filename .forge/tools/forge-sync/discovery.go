package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode"
)

type SourceDiscoveryConfig struct {
	Version int                   `json:"version"`
	Rules   []SourceDiscoveryRule `json:"rules"`
}

type SourceDiscoveryRule struct {
	Name             string   `json:"name"`
	Type             string   `json:"type"`
	Enabled          *bool    `json:"enabled,omitempty"`
	ExpandItems      *bool    `json:"expand_items,omitempty"`
	Topic            string   `json:"topic"`
	Folder           string   `json:"folder"`
	NotionID         string   `json:"notion_id"`
	Slug             string   `json:"slug,omitempty"`
	SyncPolicy       string   `json:"sync_policy,omitempty"`
	CacheStatus      string   `json:"cache_status,omitempty"`
	IncludeRoot      *bool    `json:"include_root,omitempty"`
	ChildFolder      string   `json:"child_folder,omitempty"`
	ChildSyncPolicy  string   `json:"child_sync_policy,omitempty"`
	ChildCacheStatus string   `json:"child_cache_status,omitempty"`
	ExcludeChildren  []string `json:"exclude_children,omitempty"`
}

type SourceStubSpec struct {
	RelPath       string
	Title         string
	Topic         string
	NotionID      string
	SourceURL     string
	SourceType    string
	SyncPolicy    string
	CacheStatus   string
	RuleName      string
	ParentRelPath string
	IndexRelPath  string
	ChildLinks    []IndexLink
}

type pathResolver struct {
	vaultRoot string
	claimed   map[string]string
}

type IndexLink struct {
	Title string
	Path  string
	URL   string
	Type  string
}

func cmdSyncSources(client *NotionClient, vaultRoot string) error {
	configPath := os.Getenv("FORGE_SYNC_SOURCE_CONFIG")
	if configPath == "" {
		configPath = filepath.Join(vaultRoot, ".forge", "source-discovery.json")
	}

	cfg, err := loadSourceDiscoveryConfig(configPath)
	if err != nil {
		return err
	}

	fmt.Printf("syncing sources from %s...\n", relPath(vaultRoot, configPath))

	resolver := &pathResolver{
		vaultRoot: vaultRoot,
		claimed:   make(map[string]string),
	}

	var failures int
	var upserts int
	var staleCount int
	var prunedCount int

	for _, rule := range cfg.Rules {
		if !rule.isEnabled() {
			continue
		}

		activePaths, ruleUpserts, err := syncRule(client, vaultRoot, resolver, rule)
		if err != nil {
			failures++
			fmt.Fprintf(os.Stderr, "error syncing rule %s: %v\n", rule.Name, err)
			continue
		}

		pruned, err := pruneGeneratedEntryStubs(vaultRoot, rule, activePaths)
		if err != nil {
			failures++
			fmt.Fprintf(os.Stderr, "error pruning generated entry stubs for %s: %v\n", rule.Name, err)
			continue
		}

		stale, err := markStaleManagedStubs(vaultRoot, rule, activePaths)
		if err != nil {
			failures++
			fmt.Fprintf(os.Stderr, "error marking stale stubs for %s: %v\n", rule.Name, err)
			continue
		}

		upserts += ruleUpserts
		staleCount += stale
		prunedCount += pruned
		fmt.Printf("  [%s] upserted %d, stale %d, pruned %d\n", rule.Name, ruleUpserts, stale, pruned)
	}

	fmt.Printf("\nupserted %d stub(s), marked %d stale, pruned %d generated entry stub(s)\n", upserts, staleCount, prunedCount)
	if err := upsertSourcesRootIndex(vaultRoot); err != nil {
		return fmt.Errorf("update 02_sources/INDEX.md: %w", err)
	}
	if failures > 0 {
		return fmt.Errorf("%d discovery rule(s) failed", failures)
	}
	return nil
}

func loadSourceDiscoveryConfig(path string) (*SourceDiscoveryConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read discovery config: %w", err)
	}

	var cfg SourceDiscoveryConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("parse discovery config: %w", err)
	}
	if len(cfg.Rules) == 0 {
		return nil, fmt.Errorf("no discovery rules found in %s", path)
	}
	return &cfg, nil
}

func syncRule(client *NotionClient, vaultRoot string, resolver *pathResolver, rule SourceDiscoveryRule) (map[string]bool, int, error) {
	activePaths := make(map[string]bool)
	upserts := 0

	switch rule.Type {
	case "page":
		page, err := client.GetPage(rule.NotionID)
		if err != nil {
			return nil, 0, err
		}

		relPath := resolver.resolve(rule.rootRelPath(extractPageTitle(page)), page.ID)
		if err := upsertSourceStub(vaultRoot, SourceStubSpec{
			RelPath:     relPath,
			Title:       extractPageTitle(page),
			Topic:       rule.Topic,
			NotionID:    page.ID,
			SourceURL:   page.URL,
			SourceType:  "page",
			SyncPolicy:  rule.rootSyncPolicy(),
			CacheStatus: rule.rootCacheStatus(),
			RuleName:    rule.Name,
		}); err != nil {
			return nil, 0, err
		}
		activePaths[filepath.Join(vaultRoot, "02_sources", relPath)] = true
		upserts++

	case "database":
		db, err := client.GetDatabase(rule.NotionID)
		if err != nil {
			return nil, 0, err
		}

		var childLinks []IndexLink
		relPath := resolver.resolve(rule.rootRelPath(extractDatabaseTitle(db)), db.ID)
		spec := SourceStubSpec{
			RelPath:     relPath,
			Title:       extractDatabaseTitle(db),
			Topic:       rule.Topic,
			NotionID:    db.ID,
			SourceURL:   db.URL,
			SourceType:  "database",
			SyncPolicy:  rule.rootSyncPolicy(),
			CacheStatus: rule.rootCacheStatus(),
			RuleName:    rule.Name,
		}
		if rule.shouldExpandItems() {
			spec.IndexRelPath = indexRelPathForStub(relPath)
		}
		if err := upsertSourceStub(vaultRoot, spec); err != nil {
			return nil, 0, err
		}
		activePaths[filepath.Join(vaultRoot, "02_sources", relPath)] = true
		upserts++
		if rule.shouldExpandItems() {
			var childUpserts int
			childLinks, childUpserts, err = expandDatabaseItems(client, vaultRoot, rule, relPath, relPath, db.ID, extractDatabaseTitle(db), activePaths)
			if err != nil {
				return nil, 0, err
			}
			upserts += childUpserts
			if err := upsertSourceStub(vaultRoot, SourceStubSpec{
				RelPath:      relPath,
				Title:        extractDatabaseTitle(db),
				Topic:        rule.Topic,
				NotionID:     db.ID,
				SourceURL:    db.URL,
				SourceType:   "database",
				SyncPolicy:   rule.rootSyncPolicy(),
				CacheStatus:  rule.rootCacheStatus(),
				RuleName:     rule.Name,
				IndexRelPath: indexRelPathForStub(relPath),
				ChildLinks:   childLinks,
			}); err != nil {
				return nil, 0, err
			}
		}

	case "inline_databases":
		page, err := client.GetPage(rule.NotionID)
		if err != nil {
			return nil, 0, err
		}
		rootTitle := extractPageTitle(page)
		rootRelPath := rule.rootRelPath(rootTitle)
		parentRelPath := ""
		childFolder := rule.childFolder(rootTitle, page.ID)
		childFolderRelPath := filepath.Join(rule.Folder, childFolder)
		folderIndexRelPath := filepath.Join(childFolderRelPath, "INDEX.md")
		var childLinks []IndexLink
		if rule.shouldIncludeRoot(true) {
			relPath := resolver.resolve(rootRelPath, page.ID)
			rootRelPath = relPath
			parentRelPath = relPath
			if err := upsertSourceStub(vaultRoot, SourceStubSpec{
				RelPath:      relPath,
				Title:        rootTitle,
				Topic:        rule.Topic,
				NotionID:     page.ID,
				SourceURL:    page.URL,
				SourceType:   "page",
				SyncPolicy:   rule.rootSyncPolicy(),
				CacheStatus:  rule.rootCacheStatus(),
				RuleName:     rule.Name,
				IndexRelPath: folderIndexRelPath,
			}); err != nil {
				return nil, 0, err
			}
			activePaths[filepath.Join(vaultRoot, "02_sources", relPath)] = true
			upserts++
		}

		blocks, err := client.GetBlockChildren(rule.NotionID)
		if err != nil {
			return nil, 0, err
		}

		for _, block := range blocks {
			if block.Type != "child_database" || block.ChildDatabase == nil {
				continue
			}

			title := block.ChildDatabase.Title
			if rule.shouldExcludeChild(title) {
				continue
			}
			desired := filepath.Join(rule.Folder, childFolder, slugify(title, shortID(block.ID))+".md")
			relPath := resolver.resolve(desired, block.ID)
			spec := SourceStubSpec{
				RelPath:       relPath,
				Title:         title,
				Topic:         rule.Topic,
				NotionID:      block.ID,
				SourceURL:     notionURLFromID(block.ID),
				SourceType:    "database",
				SyncPolicy:    rule.childSyncPolicy(),
				CacheStatus:   rule.childCacheStatus(),
				RuleName:      rule.Name,
				ParentRelPath: parentRelPath,
				IndexRelPath:  folderIndexRelPath,
			}
			if rule.shouldExpandItems() {
				spec.IndexRelPath = indexRelPathForStub(relPath)
			}
			if err := upsertSourceStub(vaultRoot, spec); err != nil {
				return nil, 0, err
			}
			activePaths[filepath.Join(vaultRoot, "02_sources", relPath)] = true
			childLinks = append(childLinks, IndexLink{Title: title, Path: relPath, Type: "database"})
			upserts++
			if rule.shouldExpandItems() {
				entryLinks, childUpserts, err := expandDatabaseItems(client, vaultRoot, rule, relPath, relPath, block.ID, title, activePaths)
				if err != nil {
					return nil, 0, err
				}
				upserts += childUpserts
				if err := upsertSourceStub(vaultRoot, SourceStubSpec{
					RelPath:       relPath,
					Title:         title,
					Topic:         rule.Topic,
					NotionID:      block.ID,
					SourceURL:     notionURLFromID(block.ID),
					SourceType:    "database",
					SyncPolicy:    rule.childSyncPolicy(),
					CacheStatus:   rule.childCacheStatus(),
					RuleName:      rule.Name,
					ParentRelPath: parentRelPath,
					IndexRelPath:  indexRelPathForStub(relPath),
					ChildLinks:    entryLinks,
				}); err != nil {
					return nil, 0, err
				}
			}
		}

		if err := upsertFolderIndex(vaultRoot, childFolderRelPath, rootTitle+" Sources", parentRelPath, childLinks); err != nil {
			return nil, 0, err
		}
		if rule.shouldIncludeRoot(true) {
			if err := upsertSourceStub(vaultRoot, SourceStubSpec{
				RelPath:      rootRelPath,
				Title:        rootTitle,
				Topic:        rule.Topic,
				NotionID:     page.ID,
				SourceURL:    page.URL,
				SourceType:   "page",
				SyncPolicy:   rule.rootSyncPolicy(),
				CacheStatus:  rule.rootCacheStatus(),
				RuleName:     rule.Name,
				IndexRelPath: folderIndexRelPath,
				ChildLinks:   childLinks,
			}); err != nil {
				return nil, 0, err
			}
		}

	case "database_items":
		db, err := client.GetDatabase(rule.NotionID)
		if err != nil {
			return nil, 0, err
		}

		dbTitle := extractDatabaseTitle(db)
		rootRelPath := rule.rootRelPath(dbTitle)
		parentRelPath := ""
		childFolder := rule.childFolder(dbTitle, db.ID)
		childFolderRelPath := filepath.Join(rule.Folder, childFolder)
		folderIndexRelPath := filepath.Join(childFolderRelPath, "INDEX.md")
		var childLinks []IndexLink
		if rule.shouldIncludeRoot(false) {
			relPath := resolver.resolve(rootRelPath, db.ID)
			rootRelPath = relPath
			parentRelPath = relPath
			if err := upsertSourceStub(vaultRoot, SourceStubSpec{
				RelPath:      relPath,
				Title:        dbTitle,
				Topic:        rule.Topic,
				NotionID:     db.ID,
				SourceURL:    db.URL,
				SourceType:   "database",
				SyncPolicy:   rule.rootSyncPolicy(),
				CacheStatus:  rule.rootCacheStatus(),
				RuleName:     rule.Name,
				IndexRelPath: folderIndexRelPath,
			}); err != nil {
				return nil, 0, err
			}
			activePaths[filepath.Join(vaultRoot, "02_sources", relPath)] = true
			upserts++
		}

		entries, err := client.QueryDatabase(rule.NotionID)
		if err != nil {
			return nil, 0, err
		}
		localPaths := loadLocalSourceStubMap(vaultRoot, childFolderRelPath)

		for _, entry := range entries {
			title := extractEntryTitle(entry)
			link := IndexLink{Title: title, URL: entry.URL, Type: "page"}
			if relPath, ok := localPaths[cleanNotionID(entry.ID)]; ok {
				link.Path = relPath
				link.URL = ""
			}
			childLinks = append(childLinks, link)
		}

		if err := upsertFolderIndex(vaultRoot, childFolderRelPath, dbTitle+" Index", parentRelPath, childLinks); err != nil {
			return nil, 0, err
		}
		activePaths[filepath.Join(vaultRoot, "02_sources", folderIndexRelPath)] = true
		if rule.shouldIncludeRoot(false) {
			if err := upsertSourceStub(vaultRoot, SourceStubSpec{
				RelPath:      rootRelPath,
				Title:        dbTitle,
				Topic:        rule.Topic,
				NotionID:     db.ID,
				SourceURL:    db.URL,
				SourceType:   "database",
				SyncPolicy:   rule.rootSyncPolicy(),
				CacheStatus:  rule.rootCacheStatus(),
				RuleName:     rule.Name,
				IndexRelPath: folderIndexRelPath,
				ChildLinks:   childLinks,
			}); err != nil {
				return nil, 0, err
			}
		}

	default:
		return nil, 0, fmt.Errorf("unsupported rule type: %s", rule.Type)
	}

	return activePaths, upserts, nil
}

func upsertSourceStub(vaultRoot string, spec SourceStubSpec) error {
	absPath := filepath.Join(vaultRoot, "02_sources", spec.RelPath)
	if err := os.MkdirAll(filepath.Dir(absPath), 0755); err != nil {
		return err
	}

	now := time.Now().Format("2006-01-02")
	fields := []FrontmatterField{
		{Key: "title", Value: spec.Title},
		{Key: "kind", Value: "source"},
		{Key: "topic", Value: spec.Topic},
		{Key: "source", Value: "notion"},
		{Key: "source_type", Value: spec.SourceType},
		{Key: "notion_id", Value: cleanNotionID(spec.NotionID)},
		{Key: "source_url", Value: spec.SourceURL},
		{Key: "sync_policy", Value: spec.SyncPolicy},
		{Key: "cache_status", Value: spec.CacheStatus},
		{Key: "generated_by", Value: "forge-sync"},
		{Key: "discovery_rule", Value: spec.RuleName},
		{Key: "discovery_state", Value: "active"},
		{Key: "last_discovered", Value: now},
	}

	managed := renderManagedSection(vaultRoot, absPath, spec)

	if _, err := os.Stat(absPath); err == nil {
		data, err := os.ReadFile(absPath)
		if err != nil {
			return err
		}

		content := updateFrontmatterContent(string(data), fields)
		if strings.Contains(content, managedSectionBegin) && strings.Contains(content, managedSectionEnd) {
			content = replaceManagedSection(content, managed)
		} else {
			content = strings.TrimRight(content, "\n") + "\n\n" + managed + "\n"
		}
		return os.WriteFile(absPath, []byte(content), 0644)
	}

	body := renderNewSourceStubBody(spec, managed)
	content := renderFrontmatter(fields) + "\n" + body
	return os.WriteFile(absPath, []byte(content), 0644)
}

func renderNewSourceStubBody(spec SourceStubSpec, managed string) string {
	var sb strings.Builder
	sb.WriteString("# " + spec.Title + "\n\n")
	sb.WriteString("## Summary\n")
	sb.WriteString("Auto-generated source stub from Notion discovery. Add curated notes here if this source becomes important.\n\n")
	sb.WriteString(managed + "\n")
	return sb.String()
}

func renderManagedSection(vaultRoot, absPath string, spec SourceStubSpec) string {
	cachePath := stubToCachePath(vaultRoot, absPath, nil)
	relCache := relPath(filepath.Dir(absPath), cachePath)

	var sb strings.Builder
	sb.WriteString(managedSectionBegin + "\n")
	sb.WriteString("## Generated Index\n")
	sb.WriteString("- Managed by `forge-sync sync-sources`\n")
	sb.WriteString(fmt.Sprintf("- Rule: `%s`\n", spec.RuleName))
	sb.WriteString(fmt.Sprintf("- Source type: `%s`\n", spec.SourceType))
	sb.WriteString(fmt.Sprintf("- Source URL: `%s`\n", spec.SourceURL))
	if spec.ParentRelPath != "" {
		parentAbs := filepath.Join(vaultRoot, "02_sources", spec.ParentRelPath)
		sb.WriteString(fmt.Sprintf("- Parent: %s\n", markdownLink(absPath, parentAbs, strings.TrimSuffix(filepath.Base(spec.ParentRelPath), filepath.Ext(spec.ParentRelPath)))))
	}
	if spec.IndexRelPath != "" {
		indexAbs := filepath.Join(vaultRoot, "02_sources", spec.IndexRelPath)
		sb.WriteString(fmt.Sprintf("- Folder index: %s\n", markdownLink(absPath, indexAbs, "INDEX")))
	}
	if len(spec.ChildLinks) > 0 {
		if len(spec.ChildLinks) > 20 {
			sb.WriteString(fmt.Sprintf("- Discovered children: %d item(s); see folder index for full list\n", len(spec.ChildLinks)))
		} else {
			sb.WriteString("- Discovered children:\n")
			for _, child := range spec.ChildLinks {
				sb.WriteString(fmt.Sprintf("  - %s (`%s`)\n", renderIndexLink(vaultRoot, absPath, child), child.Type))
			}
		}
	}
	sb.WriteString("\n## Cache\n")
	sb.WriteString(fmt.Sprintf("- `%s`\n", relCache))
	sb.WriteString(managedSectionEnd)
	return sb.String()
}

func upsertFolderIndex(vaultRoot, folderRelPath, title, parentRelPath string, childLinks []IndexLink) error {
	absPath := filepath.Join(vaultRoot, "02_sources", folderRelPath, "INDEX.md")
	if err := os.MkdirAll(filepath.Dir(absPath), 0755); err != nil {
		return err
	}

	var sb strings.Builder
	sb.WriteString("# " + title + "\n\n")
	sb.WriteString("Auto-generated by `forge-sync sync-sources`.\n\n")
	if parentRelPath != "" {
		parentAbs := filepath.Join(vaultRoot, "02_sources", parentRelPath)
		sb.WriteString("## Parent\n")
		sb.WriteString("- " + markdownLink(absPath, parentAbs, strings.TrimSuffix(filepath.Base(parentRelPath), filepath.Ext(parentRelPath))) + "\n\n")
	}
	sb.WriteString("## Sources\n")
	if len(childLinks) == 0 {
		sb.WriteString("- (empty)\n")
	} else {
		for _, child := range childLinks {
			sb.WriteString(fmt.Sprintf("- %s (`%s`)\n", renderIndexLink(vaultRoot, absPath, child), child.Type))
		}
	}
	sb.WriteString("\n")

	return os.WriteFile(absPath, []byte(sb.String()), 0644)
}

func markStaleManagedStubs(vaultRoot string, rule SourceDiscoveryRule, activePaths map[string]bool) (int, error) {
	sourcesDir := filepath.Join(vaultRoot, "02_sources")
	stubs, err := FindSourceStubs(sourcesDir)
	if err != nil {
		return 0, err
	}

	now := time.Now().Format("2006-01-02")
	staleCount := 0
	for _, path := range stubs {
		stub, err := ParseSourceStub(path)
		if err != nil {
			continue
		}
		if stub.GeneratedBy != "forge-sync" || stub.DiscoveryRule != rule.Name {
			continue
		}
		if shouldPruneGeneratedEntryStub(sourcesDir, path, stub) {
			continue
		}
		if activePaths[path] {
			continue
		}

		if err := UpdateFrontmatterFields(path, []FrontmatterField{
			{Key: "discovery_state", Value: "stale"},
			{Key: "last_discovered", Value: now},
		}); err != nil {
			return staleCount, err
		}
		staleCount++
	}
	return staleCount, nil
}

func pruneGeneratedEntryStubs(vaultRoot string, rule SourceDiscoveryRule, activePaths map[string]bool) (int, error) {
	sourcesDir := filepath.Join(vaultRoot, "02_sources")
	stubs, err := FindSourceStubs(sourcesDir)
	if err != nil {
		return 0, err
	}

	pruned := 0
	for _, path := range stubs {
		stub, err := ParseSourceStub(path)
		if err != nil {
			continue
		}
		if stub.GeneratedBy != "forge-sync" || stub.DiscoveryRule != rule.Name {
			continue
		}
		if activePaths[path] {
			continue
		}
		if !shouldPruneGeneratedEntryStub(sourcesDir, path, stub) {
			continue
		}
		if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
			return pruned, err
		}
		pruned++
	}

	return pruned, nil
}

func (r SourceDiscoveryRule) isEnabled() bool {
	if r.Enabled == nil {
		return true
	}
	return *r.Enabled
}

func (r SourceDiscoveryRule) shouldIncludeRoot(defaultValue bool) bool {
	if r.IncludeRoot == nil {
		return defaultValue
	}
	return *r.IncludeRoot
}

func (r SourceDiscoveryRule) shouldExpandItems() bool {
	if r.ExpandItems == nil {
		return false
	}
	return *r.ExpandItems
}

func (r SourceDiscoveryRule) rootSyncPolicy() string {
	if r.SyncPolicy == "" {
		return "on-demand"
	}
	return r.SyncPolicy
}

func (r SourceDiscoveryRule) rootCacheStatus() string {
	if r.CacheStatus == "" {
		return "missing"
	}
	return r.CacheStatus
}

func (r SourceDiscoveryRule) childSyncPolicy() string {
	if r.ChildSyncPolicy == "" {
		return r.rootSyncPolicy()
	}
	return r.ChildSyncPolicy
}

func (r SourceDiscoveryRule) childCacheStatus() string {
	if r.ChildCacheStatus == "" {
		return r.rootCacheStatus()
	}
	return r.ChildCacheStatus
}

func (r SourceDiscoveryRule) rootRelPath(title string) string {
	slug := r.Slug
	if slug == "" {
		slug = slugify(title, shortID(r.NotionID))
	}
	return filepath.Join(r.Folder, slug+".md")
}

func (r SourceDiscoveryRule) childFolder(title, notionID string) string {
	if r.ChildFolder != "" {
		return r.ChildFolder
	}
	if r.Slug != "" {
		return r.Slug
	}
	return slugify(title, shortID(notionID))
}

func (r SourceDiscoveryRule) shouldExcludeChild(title string) bool {
	for _, candidate := range r.ExcludeChildren {
		if strings.EqualFold(strings.TrimSpace(candidate), strings.TrimSpace(title)) {
			return true
		}
	}
	return false
}

func (p *pathResolver) resolve(relPath, notionID string) string {
	current := relPath
	for {
		if claimedID, ok := p.claimed[current]; ok && cleanNotionID(claimedID) != cleanNotionID(notionID) {
			current = appendShortID(current, notionID)
			continue
		}

		absPath := filepath.Join(p.vaultRoot, "02_sources", current)
		if _, err := os.Stat(absPath); err == nil {
			stub, parseErr := ParseSourceStub(absPath)
			if parseErr == nil && cleanNotionID(stub.NotionID) == cleanNotionID(notionID) {
				p.claimed[current] = notionID
				return current
			}
			current = appendShortID(current, notionID)
			continue
		}

		p.claimed[current] = notionID
		return current
	}
}

func appendShortID(relPath, notionID string) string {
	ext := filepath.Ext(relPath)
	dir := filepath.Dir(relPath)
	base := strings.TrimSuffix(filepath.Base(relPath), ext)
	name := base + "-" + shortID(notionID) + ext
	if dir == "." {
		return name
	}
	return filepath.Join(dir, name)
}

func cleanNotionID(id string) string {
	return strings.ReplaceAll(id, "-", "")
}

func notionURLFromID(id string) string {
	return "https://www.notion.so/" + cleanNotionID(id)
}

func markdownLink(fromAbsPath, toAbsPath, label string) string {
	rel := relPath(filepath.Dir(fromAbsPath), toAbsPath)
	rel = filepath.ToSlash(rel)
	if strings.Contains(rel, " ") {
		rel = "<" + rel + ">"
	}
	return fmt.Sprintf("[%s](%s)", label, rel)
}

func indexRelPathForStub(stubRelPath string) string {
	return filepath.Join(strings.TrimSuffix(stubRelPath, filepath.Ext(stubRelPath)), "INDEX.md")
}

func expandDatabaseItems(client *NotionClient, vaultRoot string, rule SourceDiscoveryRule, parentRelPath, dbStubRelPath, dbID, dbTitle string, activePaths map[string]bool) ([]IndexLink, int, error) {
	entries, err := client.QueryDatabase(dbID)
	if err != nil {
		return nil, 0, err
	}

	folderRelPath := strings.TrimSuffix(dbStubRelPath, filepath.Ext(dbStubRelPath))
	folderIndexRelPath := filepath.Join(folderRelPath, "INDEX.md")
	localPaths := loadLocalSourceStubMap(vaultRoot, folderRelPath)
	childLinks := make([]IndexLink, 0, len(entries))

	for _, entry := range entries {
		title := extractEntryTitle(entry)
		link := IndexLink{Title: title, URL: entry.URL, Type: "page"}
		if relPath, ok := localPaths[cleanNotionID(entry.ID)]; ok {
			link.Path = relPath
			link.URL = ""
		}
		childLinks = append(childLinks, link)
	}

	if err := upsertFolderIndex(vaultRoot, folderRelPath, dbTitle+" Index", parentRelPath, childLinks); err != nil {
		return nil, 0, err
	}
	activePaths[filepath.Join(vaultRoot, "02_sources", folderIndexRelPath)] = true

	return childLinks, 0, nil
}

func renderIndexLink(vaultRoot, fromAbsPath string, link IndexLink) string {
	if link.Path != "" {
		linkAbs := filepath.Join(vaultRoot, "02_sources", link.Path)
		return markdownLink(fromAbsPath, linkAbs, link.Title)
	}
	if link.URL != "" {
		return fmt.Sprintf("[%s](%s)", link.Title, link.URL)
	}
	return link.Title
}

func shouldPruneGeneratedEntryStub(sourcesDir, path string, stub *SourceStub) bool {
	if stub.Source != "notion" || stub.SourceType != "page" {
		return false
	}
	rel, err := filepath.Rel(sourcesDir, path)
	if err != nil {
		return false
	}
	parts := strings.Split(filepath.ToSlash(rel), "/")
	return len(parts) > 2
}

func loadLocalSourceStubMap(vaultRoot, folderRelPath string) map[string]string {
	dir := filepath.Join(vaultRoot, "02_sources", folderRelPath)
	entries, err := os.ReadDir(dir)
	if err != nil {
		return map[string]string{}
	}

	localPaths := make(map[string]string)
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !strings.HasSuffix(name, ".md") || name == "INDEX.md" {
			continue
		}
		absPath := filepath.Join(dir, name)
		stub, err := ParseSourceStub(absPath)
		if err != nil || stub.Source != "notion" || stub.SourceType != "page" {
			continue
		}
		relPath, err := filepath.Rel(filepath.Join(vaultRoot, "02_sources"), absPath)
		if err != nil {
			continue
		}
		localPaths[cleanNotionID(stub.NotionID)] = filepath.ToSlash(relPath)
	}

	return localPaths
}

func slugify(input, fallback string) string {
	var b strings.Builder
	prevDash := false

	for _, r := range strings.TrimSpace(input) {
		switch {
		case unicode.IsLetter(r) || unicode.IsDigit(r):
			b.WriteRune(unicode.ToLower(r))
			prevDash = false
		case unicode.IsSpace(r) || r == '-' || r == '_' || r == '/':
			if b.Len() > 0 && !prevDash {
				b.WriteRune('-')
				prevDash = true
			}
		default:
			if b.Len() > 0 && !prevDash {
				b.WriteRune('-')
				prevDash = true
			}
		}
	}

	slug := strings.Trim(b.String(), "-")
	if slug == "" {
		if fallback == "" {
			return "untitled"
		}
		return fallback
	}
	return slug
}
