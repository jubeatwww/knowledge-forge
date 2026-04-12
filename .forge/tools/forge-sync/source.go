package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type SourceStub struct {
	Title       string
	Source      string
	NotionID    string
	SyncPolicy  string
	CacheStatus string
	FilePath    string
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
		case "notion_id":
			stub.NotionID = val
		case "sync_policy":
			stub.SyncPolicy = val
		case "cache_status":
			stub.CacheStatus = val
		}
	}

	return stub, scanner.Err()
}

func parseFrontmatterLine(line string) (string, string) {
	// Simple "key: value" parser, ignoring nested YAML
	if strings.HasPrefix(line, "  ") || strings.HasPrefix(line, "\t") {
		return "", "" // skip nested
	}
	idx := strings.Index(line, ":")
	if idx < 0 {
		return "", ""
	}
	key := strings.TrimSpace(line[:idx])
	val := strings.TrimSpace(line[idx+1:])
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
	return stubs, err
}

// UpdateStubStatus updates cache_status and adds last_synced in the frontmatter.
func UpdateStubStatus(path, status string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}

	content := string(data)
	now := time.Now().Format("2006-01-02")

	// Update cache_status
	if strings.Contains(content, "cache_status:") {
		lines := strings.Split(content, "\n")
		for i, line := range lines {
			if strings.HasPrefix(strings.TrimSpace(line), "cache_status:") {
				lines[i] = "cache_status: " + status
			}
		}
		content = strings.Join(lines, "\n")
	}

	// Add or update last_synced
	if strings.Contains(content, "last_synced:") {
		lines := strings.Split(content, "\n")
		for i, line := range lines {
			if strings.HasPrefix(strings.TrimSpace(line), "last_synced:") {
				lines[i] = "last_synced: " + now
			}
		}
		content = strings.Join(lines, "\n")
	} else {
		// Insert last_synced before the closing ---
		content = insertBeforeClosingFrontmatter(content, "last_synced: "+now)
	}

	return os.WriteFile(path, []byte(content), 0644)
}

func insertBeforeClosingFrontmatter(content, line string) string {
	lines := strings.Split(content, "\n")
	fmStart := false
	for i, l := range lines {
		trimmed := strings.TrimSpace(l)
		if trimmed == "---" {
			if !fmStart {
				fmStart = true
				continue
			}
			// This is the closing ---
			result := make([]string, 0, len(lines)+1)
			result = append(result, lines[:i]...)
			result = append(result, line)
			result = append(result, lines[i:]...)
			return strings.Join(result, "\n")
		}
	}
	// Fallback: no frontmatter found, prepend
	return fmt.Sprintf("---\n%s\n---\n%s", line, content)
}