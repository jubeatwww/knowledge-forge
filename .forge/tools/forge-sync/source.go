package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const (
	managedSectionBegin = "<!-- forge-sync:begin -->"
	managedSectionEnd   = "<!-- forge-sync:end -->"
)

type SourceStub struct {
	Title          string
	Source         string
	SourceType     string
	NotionID       string
	SyncPolicy     string
	CacheStatus    string
	FilePath       string
	GeneratedBy    string
	DiscoveryRule  string
	DiscoveryState string
}

type FrontmatterField struct {
	Key   string
	Value string
}

// ParseSourceStub reads a markdown file and extracts YAML frontmatter fields.
// This is a minimal parser — no YAML library needed.
func ParseSourceStub(path string) (*SourceStub, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	stub := &SourceStub{FilePath: path}
	scanner := bufio.NewScanner(f)
	inFrontmatter := false
	lineNum := 0

	for scanner.Scan() {
		line := scanner.Text()
		lineNum++

		if lineNum == 1 && strings.TrimSpace(line) == "---" {
			inFrontmatter = true
			continue
		}
		if inFrontmatter && strings.TrimSpace(line) == "---" {
			break
		}
		if !inFrontmatter {
			continue
		}

		key, val := parseFrontmatterLine(line)
		switch key {
		case "title":
			stub.Title = val
		case "source":
			stub.Source = val
		case "source_type":
			stub.SourceType = val
		case "notion_id":
			stub.NotionID = val
		case "sync_policy":
			stub.SyncPolicy = val
		case "cache_status":
			stub.CacheStatus = val
		case "generated_by":
			stub.GeneratedBy = val
		case "discovery_rule":
			stub.DiscoveryRule = val
		case "discovery_state":
			stub.DiscoveryState = val
		}
	}

	return stub, scanner.Err()
}

func parseFrontmatterLine(line string) (string, string) {
	// Simple "key: value" parser, ignoring nested YAML.
	if strings.HasPrefix(line, "  ") || strings.HasPrefix(line, "\t") {
		return "", ""
	}
	idx := strings.Index(line, ":")
	if idx < 0 {
		return "", ""
	}
	key := strings.TrimSpace(line[:idx])
	val := normalizeFrontmatterValue(strings.TrimSpace(line[idx+1:]))
	return key, val
}

// FindSourceStubs walks a directory and returns paths of all .md files.
func FindSourceStubs(dir string) ([]string, error) {
	var stubs []string
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // skip errors
		}
		if !info.IsDir() && strings.HasSuffix(path, ".md") {
			stubs = append(stubs, path)
		}
		return nil
	})
	sort.Strings(stubs)
	return stubs, err
}

// UpdateStubStatus updates cache_status and adds last_synced in the frontmatter.
func UpdateStubStatus(path, status string) error {
	now := time.Now().Format("2006-01-02")
	return UpdateFrontmatterFields(path, []FrontmatterField{
		{Key: "cache_status", Value: status},
		{Key: "last_synced", Value: now},
	})
}

func UpdateFrontmatterFields(path string, fields []FrontmatterField) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	content := updateFrontmatterContent(string(data), fields)
	return os.WriteFile(path, []byte(content), 0644)
}

func updateFrontmatterContent(content string, fields []FrontmatterField) string {
	frontmatter, body, hasFrontmatter := splitFrontmatter(content)
	if !hasFrontmatter {
		return renderFrontmatter(fields) + body
	}

	lines := strings.Split(frontmatter, "\n")
	seen := make(map[string]bool)

	for i, line := range lines {
		key, _ := parseFrontmatterLine(line)
		if key == "" {
			continue
		}
		for _, field := range fields {
			if key == field.Key {
				lines[i] = fmt.Sprintf("%s: %s", field.Key, formatFrontmatterValue(field.Value))
				seen[field.Key] = true
				break
			}
		}
	}

	for _, field := range fields {
		if seen[field.Key] {
			continue
		}
		lines = append(lines, fmt.Sprintf("%s: %s", field.Key, formatFrontmatterValue(field.Value)))
	}

	return "---\n" + strings.Join(lines, "\n") + "\n---\n" + body
}

func splitFrontmatter(content string) (frontmatter string, body string, hasFrontmatter bool) {
	if !strings.HasPrefix(content, "---\n") {
		return "", content, false
	}

	rest := content[len("---\n"):]
	idx := strings.Index(rest, "\n---\n")
	if idx < 0 {
		return "", content, false
	}

	frontmatter = rest[:idx]
	body = rest[idx+len("\n---\n"):]
	return frontmatter, body, true
}

func renderFrontmatter(fields []FrontmatterField) string {
	var sb strings.Builder
	sb.WriteString("---\n")
	for _, field := range fields {
		sb.WriteString(fmt.Sprintf("%s: %s\n", field.Key, formatFrontmatterValue(field.Value)))
	}
	sb.WriteString("---\n")
	return sb.String()
}

func replaceManagedSection(content, replacement string) string {
	start := strings.Index(content, managedSectionBegin)
	end := strings.Index(content, managedSectionEnd)
	if start < 0 || end < 0 || end < start {
		return content
	}
	end += len(managedSectionEnd)
	return content[:start] + replacement + content[end:]
}

func formatFrontmatterValue(value string) string {
	if value == "" {
		return `""`
	}
	if strings.ContainsAny(value, ":#[]{}&*!|>'\"%@`\n") || strings.HasPrefix(value, " ") || strings.HasSuffix(value, " ") {
		return "'" + strings.ReplaceAll(value, "'", "''") + "'"
	}
	return value
}

func normalizeFrontmatterValue(value string) string {
	if len(value) >= 2 {
		if strings.HasPrefix(value, "'") && strings.HasSuffix(value, "'") {
			return strings.ReplaceAll(value[1:len(value)-1], "''", "'")
		}
		if strings.HasPrefix(value, `"`) && strings.HasSuffix(value, `"`) {
			return value[1 : len(value)-1]
		}
	}
	return value
}
