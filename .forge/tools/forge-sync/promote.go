package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func cmdPromote(client *NotionClient, vaultRoot, indexPath, notionRef string) error {
	indexAbsPath, folderRelPath, err := resolveFolderIndexPath(vaultRoot, indexPath)
	if err != nil {
		return err
	}

	notionID := parseNotionID(notionRef)
	if notionID == "" {
		return fmt.Errorf("cannot parse notion id from %q", notionRef)
	}

	page, err := client.GetPage(notionID)
	if err != nil {
		return fmt.Errorf("fetch page: %w", err)
	}

	topic := topLevelFolder(folderRelPath)
	parentRelPath := inferParentStubRelPath(vaultRoot, indexAbsPath)
	resolver := &pathResolver{
		vaultRoot: vaultRoot,
		claimed:   make(map[string]string),
	}
	indexRelPath, err := filepath.Rel(filepath.Join(vaultRoot, "02_sources"), indexAbsPath)
	if err != nil {
		return err
	}
	indexRelPath = filepath.ToSlash(indexRelPath)

	desiredRelPath := filepath.Join(folderRelPath, slugify(extractPageTitle(page), shortID(page.ID))+".md")
	relPath := resolver.resolve(desiredRelPath, page.ID)
	if err := upsertPromotedSourceStub(vaultRoot, PromoteStubSpec{
		RelPath:        relPath,
		Title:          extractPageTitle(page),
		Topic:          topic,
		NotionID:       page.ID,
		SourceURL:      page.URL,
		ParentRelPath:  parentRelPath,
		IndexRelPath:   indexRelPath,
		PromotedFrom:   indexRelPath,
		PromotedByCmd:  "forge-sync promote",
		PromotedAtDate: time.Now().Format("2006-01-02"),
	}); err != nil {
		return err
	}

	if err := rewriteIndexEntryAsLocalLink(indexAbsPath, extractPageTitle(page), page.URL, filepath.Join(vaultRoot, "02_sources", relPath)); err != nil {
		return err
	}

	fmt.Printf("promoted %s\n", relPath)
	return nil
}

type PromoteStubSpec struct {
	RelPath        string
	Title          string
	Topic          string
	NotionID       string
	SourceURL      string
	ParentRelPath  string
	IndexRelPath   string
	PromotedFrom   string
	PromotedByCmd  string
	PromotedAtDate string
}

func upsertPromotedSourceStub(vaultRoot string, spec PromoteStubSpec) error {
	absPath := filepath.Join(vaultRoot, "02_sources", spec.RelPath)
	if err := os.MkdirAll(filepath.Dir(absPath), 0755); err != nil {
		return err
	}

	fields := []FrontmatterField{
		{Key: "title", Value: spec.Title},
		{Key: "kind", Value: "source"},
		{Key: "topic", Value: spec.Topic},
		{Key: "source", Value: "notion"},
		{Key: "source_type", Value: "page"},
		{Key: "notion_id", Value: cleanNotionID(spec.NotionID)},
		{Key: "source_url", Value: spec.SourceURL},
		{Key: "sync_policy", Value: "on-demand"},
		{Key: "cache_status", Value: "missing"},
		{Key: "generated_by", Value: "forge-sync-promote"},
		{Key: "promoted_from", Value: spec.PromotedFrom},
		{Key: "last_promoted", Value: spec.PromotedAtDate},
	}

	managed := renderPromotedManagedSection(vaultRoot, absPath, spec)
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

	var sb strings.Builder
	sb.WriteString(renderFrontmatter(fields))
	sb.WriteString("\n# " + spec.Title + "\n\n")
	sb.WriteString("## Summary\n")
	sb.WriteString("Promoted from a generated source index. Add curated notes here when this entry becomes worth keeping locally.\n\n")
	sb.WriteString(managed + "\n")
	return os.WriteFile(absPath, []byte(sb.String()), 0644)
}

func renderPromotedManagedSection(vaultRoot, absPath string, spec PromoteStubSpec) string {
	cachePath := stubToCachePath(vaultRoot, absPath, nil)
	relCache := relPath(filepath.Dir(absPath), cachePath)

	var sb strings.Builder
	sb.WriteString(managedSectionBegin + "\n")
	sb.WriteString("## Generated Index\n")
	sb.WriteString(fmt.Sprintf("- Promoted by `%s`\n", spec.PromotedByCmd))
	sb.WriteString(fmt.Sprintf("- Source URL: `%s`\n", spec.SourceURL))
	if spec.ParentRelPath != "" {
		parentAbs := filepath.Join(vaultRoot, "02_sources", spec.ParentRelPath)
		sb.WriteString(fmt.Sprintf("- Parent: %s\n", markdownLink(absPath, parentAbs, strings.TrimSuffix(filepath.Base(spec.ParentRelPath), filepath.Ext(spec.ParentRelPath)))))
	}
	if spec.IndexRelPath != "" {
		indexAbs := filepath.Join(vaultRoot, "02_sources", spec.IndexRelPath)
		sb.WriteString(fmt.Sprintf("- Folder index: %s\n", markdownLink(absPath, indexAbs, "INDEX")))
	}
	sb.WriteString("\n## Cache\n")
	sb.WriteString(fmt.Sprintf("- `%s`\n", relCache))
	sb.WriteString(managedSectionEnd)
	return sb.String()
}

func resolveFolderIndexPath(vaultRoot, input string) (string, string, error) {
	indexPath := input
	if !filepath.IsAbs(indexPath) {
		indexPath = filepath.Join(vaultRoot, indexPath)
	}

	if info, err := os.Stat(indexPath); err == nil && info.IsDir() {
		indexPath = filepath.Join(indexPath, "INDEX.md")
	}
	if filepath.Base(indexPath) != "INDEX.md" {
		return "", "", fmt.Errorf("promote requires a folder INDEX.md path, got %s", input)
	}
	if _, err := os.Stat(indexPath); err != nil {
		return "", "", fmt.Errorf("open index %s: %w", input, err)
	}

	sourcesDir := filepath.Join(vaultRoot, "02_sources")
	rel, err := filepath.Rel(sourcesDir, indexPath)
	if err != nil {
		return "", "", err
	}
	rel = filepath.ToSlash(rel)
	if strings.HasPrefix(rel, "../") || rel == "INDEX.md" {
		return "", "", fmt.Errorf("%s is not a source folder index under 02_sources", input)
	}
	return indexPath, filepath.ToSlash(filepath.Dir(rel)), nil
}

func inferParentStubRelPath(vaultRoot, indexAbsPath string) string {
	folderAbs := filepath.Dir(indexAbsPath)
	parentDir := filepath.Dir(folderAbs)
	candidate := filepath.Join(parentDir, filepath.Base(folderAbs)+".md")
	if _, err := os.Stat(candidate); err != nil {
		return ""
	}
	rel, err := filepath.Rel(filepath.Join(vaultRoot, "02_sources"), candidate)
	if err != nil {
		return ""
	}
	return filepath.ToSlash(rel)
}

func rewriteIndexEntryAsLocalLink(indexAbsPath, title, notionURL, promotedAbsPath string) error {
	data, err := os.ReadFile(indexAbsPath)
	if err != nil {
		return err
	}

	oldLink := fmt.Sprintf("[%s](%s)", title, notionURL)
	newLink := markdownLink(indexAbsPath, promotedAbsPath, title)
	updated := strings.Replace(string(data), oldLink, newLink, 1)
	if updated == string(data) {
		return nil
	}
	return os.WriteFile(indexAbsPath, []byte(updated), 0644)
}

func parseNotionID(input string) string {
	value := strings.TrimSpace(input)
	if value == "" {
		return ""
	}

	if strings.Contains(value, "notion.so/") {
		value = value[strings.LastIndex(value, "/")+1:]
		if idx := strings.Index(value, "?"); idx >= 0 {
			value = value[:idx]
		}
		if idx := strings.Index(value, "#"); idx >= 0 {
			value = value[:idx]
		}
		parts := strings.Split(value, "-")
		value = parts[len(parts)-1]
	}

	value = strings.ReplaceAll(value, "-", "")
	if len(value) != 32 {
		return ""
	}
	for _, r := range value {
		if !strings.ContainsRune("0123456789abcdefABCDEF", r) {
			return ""
		}
	}
	return value
}

func topLevelFolder(relPath string) string {
	parts := strings.Split(filepath.ToSlash(relPath), "/")
	if len(parts) == 0 {
		return ""
	}
	return parts[0]
}
