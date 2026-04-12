package main

import (
	"fmt"
	"strings"
	"time"
)

// RenderPage converts a fetched Notion page into markdown with frontmatter.
func RenderPage(page *Page, blocks []Block, dbSections []DatabaseSection) string {
	var sb strings.Builder

	// Frontmatter
	title := extractPageTitle(page)
	sb.WriteString("---\n")
	sb.WriteString(fmt.Sprintf("notion_id: %s\n", page.ID))
	sb.WriteString(fmt.Sprintf("source_url: %s\n", page.URL))
	sb.WriteString(fmt.Sprintf("fetched_at: %s\n", time.Now().Format("2006-01-02")))
	sb.WriteString("---\n\n")

	sb.WriteString("# " + title + "\n\n")

	// Render blocks
	renderBlocks(&sb, blocks, 0)

	// Render database sections
	for _, ds := range dbSections {
		sb.WriteString("\n## 📊 " + ds.Title + "\n\n")
		renderDatabaseEntries(&sb, ds.Entries)
	}

	return sb.String()
}

func renderBlocks(sb *strings.Builder, blocks []Block, indent int) {
	prefix := strings.Repeat("\t", indent)
	numberedIdx := 1

	for i, b := range blocks {
		// Reset numbered list counter when type changes
		if b.Type != "numbered_list_item" {
			numberedIdx = 1
		}

		switch b.Type {
		case "paragraph":
			if b.Paragraph != nil {
				text := renderRichText(b.Paragraph.RichText)
				if text != "" {
					sb.WriteString(prefix + text + "\n")
				}
				sb.WriteString("\n")
			}

		case "heading_1":
			if b.Heading1 != nil {
				sb.WriteString(prefix + "## " + renderRichText(b.Heading1.RichText) + "\n\n")
			}

		case "heading_2":
			if b.Heading2 != nil {
				sb.WriteString(prefix + "### " + renderRichText(b.Heading2.RichText) + "\n\n")
			}

		case "heading_3":
			if b.Heading3 != nil {
				sb.WriteString(prefix + "#### " + renderRichText(b.Heading3.RichText) + "\n\n")
			}

		case "bulleted_list_item":
			if b.BulletedListItem != nil {
				sb.WriteString(prefix + "- " + renderRichText(b.BulletedListItem.RichText) + "\n")
				if len(b.BulletedListItem.Children) > 0 {
					renderBlocks(sb, b.BulletedListItem.Children, indent+1)
				}
				// Add blank line after last list item
				if i+1 >= len(blocks) || blocks[i+1].Type != "bulleted_list_item" {
					sb.WriteString("\n")
				}
			}

		case "numbered_list_item":
			if b.NumberedListItem != nil {
				sb.WriteString(fmt.Sprintf("%s%d. %s\n", prefix, numberedIdx, renderRichText(b.NumberedListItem.RichText)))
				numberedIdx++
				if len(b.NumberedListItem.Children) > 0 {
					renderBlocks(sb, b.NumberedListItem.Children, indent+1)
				}
				if i+1 >= len(blocks) || blocks[i+1].Type != "numbered_list_item" {
					sb.WriteString("\n")
				}
			}

		case "toggle":
			if b.Toggle != nil {
				summary := renderRichText(b.Toggle.RichText)
				sb.WriteString(prefix + "<details>\n")
				sb.WriteString(prefix + "<summary>" + summary + "</summary>\n\n")
				if len(b.Toggle.Children) > 0 {
					renderBlocks(sb, b.Toggle.Children, indent)
				}
				sb.WriteString(prefix + "</details>\n\n")
			}

		case "quote":
			if b.Quote != nil {
				text := renderRichText(b.Quote.RichText)
				for _, line := range strings.Split(text, "\n") {
					sb.WriteString(prefix + "> " + line + "\n")
				}
				sb.WriteString("\n")
			}

		case "callout":
			if b.Callout != nil {
				icon := ""
				if b.Callout.Icon != nil && b.Callout.Icon.Emoji != "" {
					icon = b.Callout.Icon.Emoji + " "
				}
				text := renderRichText(b.Callout.RichText)
				sb.WriteString(prefix + "> " + icon + text + "\n\n")
			}

		case "code":
			if b.Code != nil {
				lang := b.Code.Language
				if lang == "plain text" {
					lang = ""
				}
				sb.WriteString(prefix + "```" + lang + "\n")
				sb.WriteString(renderRichText(b.Code.RichText) + "\n")
				sb.WriteString(prefix + "```\n\n")
			}

		case "divider":
			sb.WriteString(prefix + "---\n\n")

		case "child_database":
			// Handled separately in dbSections
			continue

		case "table":
			if b.Table != nil {
				renderTable(sb, b.Table, prefix)
			}

		case "image":
			if b.Image != nil {
				url := ""
				if b.Image.File != nil {
					url = b.Image.File.URL
				} else if b.Image.External != nil {
					url = b.Image.External.URL
				}
				caption := renderRichText(b.Image.Caption)
				if caption == "" {
					caption = "image"
				}
				sb.WriteString(fmt.Sprintf("%s![%s](%s)\n\n", prefix, caption, url))
			}

		case "bookmark":
			if b.Bookmark != nil {
				caption := renderRichText(b.Bookmark.Caption)
				if caption == "" {
					caption = b.Bookmark.URL
				}
				sb.WriteString(fmt.Sprintf("%s[%s](%s)\n\n", prefix, caption, b.Bookmark.URL))
			}

		default:
			// Unknown block type — skip silently
		}
	}
}

func renderRichText(parts []RichText) string {
	var sb strings.Builder
	for _, rt := range parts {
		text := rt.PlainText

		if rt.Annotations != nil {
			if rt.Annotations.Code {
				text = "`" + text + "`"
			}
			if rt.Annotations.Bold {
				text = "**" + text + "**"
			}
			if rt.Annotations.Italic {
				text = "*" + text + "*"
			}
			if rt.Annotations.Strikethrough {
				text = "~~" + text + "~~"
			}
		}

		if rt.Href != "" {
			text = "[" + text + "](" + rt.Href + ")"
		}

		sb.WriteString(text)
	}
	return sb.String()
}

func renderTable(sb *strings.Builder, table *TableBlock, prefix string) {
	if len(table.Rows) == 0 {
		return
	}

	for i, row := range table.Rows {
		if row.TableRow == nil {
			continue
		}
		var cells []string
		for _, cell := range row.TableRow.Cells {
			cells = append(cells, renderRichText(cell))
		}
		sb.WriteString(prefix + "| " + strings.Join(cells, " | ") + " |\n")

		// Header separator after first row
		if i == 0 && table.HasColumnHeader {
			var sep []string
			for range cells {
				sep = append(sep, "---")
			}
			sb.WriteString(prefix + "| " + strings.Join(sep, " | ") + " |\n")
		}
	}
	sb.WriteString("\n")
}

func renderDatabaseEntries(sb *strings.Builder, entries []DatabaseEntry) {
	if len(entries) == 0 {
		sb.WriteString("(empty)\n\n")
		return
	}

	for _, entry := range entries {
		title := extractEntryTitle(entry)
		props := extractEntryProps(entry)
		sb.WriteString(fmt.Sprintf("- **%s**", title))
		if props != "" {
			sb.WriteString(" — " + props)
		}
		sb.WriteString(fmt.Sprintf("  ^[notion:%s]", shortID(entry.ID)))
		sb.WriteString("\n")
	}
	sb.WriteString("\n")
}

func extractPageTitle(page *Page) string {
	for _, prop := range page.Properties {
		p, ok := prop.(map[string]interface{})
		if !ok {
			continue
		}
		if p["type"] != "title" {
			continue
		}
		titleArr, ok := p["title"].([]interface{})
		if !ok || len(titleArr) == 0 {
			continue
		}
		first, ok := titleArr[0].(map[string]interface{})
		if !ok {
			continue
		}
		if pt, ok := first["plain_text"].(string); ok {
			return pt
		}
	}
	return "Untitled"
}

func extractEntryTitle(entry DatabaseEntry) string {
	for _, prop := range entry.Properties {
		p, ok := prop.(map[string]interface{})
		if !ok {
			continue
		}
		if p["type"] != "title" {
			continue
		}
		titleArr, ok := p["title"].([]interface{})
		if !ok || len(titleArr) == 0 {
			continue
		}
		first, ok := titleArr[0].(map[string]interface{})
		if !ok {
			continue
		}
		if pt, ok := first["plain_text"].(string); ok {
			return pt
		}
	}
	return "Untitled"
}

func extractEntryProps(entry DatabaseEntry) string {
	var parts []string
	for name, prop := range entry.Properties {
		p, ok := prop.(map[string]interface{})
		if !ok {
			continue
		}
		ptype, _ := p["type"].(string)

		switch ptype {
		case "title":
			continue // already handled
		case "status":
			if status, ok := p["status"].(map[string]interface{}); ok {
				if sname, ok := status["name"].(string); ok {
					parts = append(parts, sname)
				}
			}
		case "select":
			if sel, ok := p["select"].(map[string]interface{}); ok {
				if sname, ok := sel["name"].(string); ok {
					parts = append(parts, name+": "+sname)
				}
			}
		case "url":
			if url, ok := p["url"].(string); ok && url != "" {
				parts = append(parts, "[link]("+url+")")
			}
		}
	}
	return strings.Join(parts, " | ")
}

func shortID(id string) string {
	clean := strings.ReplaceAll(id, "-", "")
	if len(clean) > 8 {
		return clean[:8]
	}
	return clean
}