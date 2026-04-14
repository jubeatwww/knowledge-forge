package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

const notionAPIBase = "https://api.notion.com/v1"
const notionVersion = "2022-06-28"

type NotionClient struct {
	Token string
}

// --- API Response Types ---

type DatabaseMeta struct {
	ID          string     `json:"id"`
	URL         string     `json:"url"`
	Title       []RichText `json:"title"`
	Description []RichText `json:"description,omitempty"`
}

type Page struct {
	ID          string                 `json:"id"`
	URL         string                 `json:"url"`
	Properties  map[string]interface{} `json:"properties"`
	CreatedTime string                 `json:"created_time"`
}

type BlockList struct {
	Results    []Block `json:"results"`
	HasMore    bool    `json:"has_more"`
	NextCursor string  `json:"next_cursor"`
}

type Block struct {
	ID          string `json:"id"`
	Type        string `json:"type"`
	HasChildren bool   `json:"has_children"`

	// Block type payloads
	Paragraph        *TextBlock     `json:"paragraph,omitempty"`
	Heading1         *TextBlock     `json:"heading_1,omitempty"`
	Heading2         *TextBlock     `json:"heading_2,omitempty"`
	Heading3         *TextBlock     `json:"heading_3,omitempty"`
	BulletedListItem *TextBlock     `json:"bulleted_list_item,omitempty"`
	NumberedListItem *TextBlock     `json:"numbered_list_item,omitempty"`
	Toggle           *TextBlock     `json:"toggle,omitempty"`
	Quote            *TextBlock     `json:"quote,omitempty"`
	Callout          *CalloutBlock  `json:"callout,omitempty"`
	Code             *CodeBlock     `json:"code,omitempty"`
	Divider          *struct{}      `json:"divider,omitempty"`
	ChildDatabase    *ChildDB       `json:"child_database,omitempty"`
	Table            *TableBlock    `json:"table,omitempty"`
	TableRow         *TableRowBlock `json:"table_row,omitempty"`
	Image            *FileBlock     `json:"image,omitempty"`
	Bookmark         *BookmarkBlock `json:"bookmark,omitempty"`
}

type TextBlock struct {
	RichText []RichText `json:"rich_text"`
	Children []Block    `json:"children,omitempty"` // populated manually for toggles
}

type CalloutBlock struct {
	RichText []RichText `json:"rich_text"`
	Icon     *Icon      `json:"icon,omitempty"`
}

type Icon struct {
	Emoji string `json:"emoji,omitempty"`
}

type CodeBlock struct {
	RichText []RichText `json:"rich_text"`
	Language string     `json:"language"`
}

type ChildDB struct {
	Title string `json:"title"`
}

type TableBlock struct {
	TableWidth      int     `json:"table_width"`
	HasColumnHeader bool    `json:"has_column_header"`
	HasRowHeader    bool    `json:"has_row_header"`
	Rows            []Block `json:"-"` // populated by GetBlockChildren
}

type TableRowBlock struct {
	Cells [][]RichText `json:"cells"`
}

type FileBlock struct {
	Type     string     `json:"type"`
	File     *FileURL   `json:"file,omitempty"`
	External *FileURL   `json:"external,omitempty"`
	Caption  []RichText `json:"caption,omitempty"`
}

type FileURL struct {
	URL string `json:"url"`
}

type BookmarkBlock struct {
	URL     string     `json:"url"`
	Caption []RichText `json:"caption,omitempty"`
}

type RichText struct {
	Type        string       `json:"type"`
	PlainText   string       `json:"plain_text"`
	Text        *TextContent `json:"text,omitempty"`
	Annotations *Annotations `json:"annotations,omitempty"`
	Href        string       `json:"href,omitempty"`
}

type TextContent struct {
	Content string   `json:"content"`
	Link    *LinkObj `json:"link,omitempty"`
}

type LinkObj struct {
	URL string `json:"url"`
}

type Annotations struct {
	Bold          bool   `json:"bold"`
	Italic        bool   `json:"italic"`
	Strikethrough bool   `json:"strikethrough"`
	Underline     bool   `json:"underline"`
	Code          bool   `json:"code"`
	Color         string `json:"color"`
}

// --- Database Query Types ---

type DatabaseQueryResult struct {
	Results    []DatabaseEntry `json:"results"`
	HasMore    bool            `json:"has_more"`
	NextCursor string          `json:"next_cursor"`
}

type DatabaseEntry struct {
	ID         string                 `json:"id"`
	URL        string                 `json:"url"`
	Properties map[string]interface{} `json:"properties"`
}

type DatabaseSection struct {
	Title   string
	ID      string
	Entries []DatabaseEntry
}

// --- API Methods ---

func (c *NotionClient) doRequest(method, path string, body io.Reader) ([]byte, error) {
	url := notionAPIBase + path
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+c.Token)
	req.Header.Set("Notion-Version", notionVersion)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("notion API %d: %s", resp.StatusCode, string(data))
	}
	return data, nil
}

func (c *NotionClient) GetPage(pageID string) (*Page, error) {
	pageID = strings.ReplaceAll(pageID, "-", "")
	data, err := c.doRequest("GET", "/pages/"+pageID, nil)
	if err != nil {
		return nil, err
	}
	var page Page
	if err := json.Unmarshal(data, &page); err != nil {
		return nil, err
	}
	return &page, nil
}

func (c *NotionClient) GetDatabase(dbID string) (*DatabaseMeta, error) {
	dbID = strings.ReplaceAll(dbID, "-", "")
	data, err := c.doRequest("GET", "/databases/"+dbID, nil)
	if err != nil {
		return nil, err
	}
	var db DatabaseMeta
	if err := json.Unmarshal(data, &db); err != nil {
		return nil, err
	}
	return &db, nil
}

func (c *NotionClient) GetBlockChildren(blockID string) ([]Block, error) {
	blockID = strings.ReplaceAll(blockID, "-", "")
	var all []Block
	cursor := ""

	for {
		path := "/blocks/" + blockID + "/children?page_size=100"
		if cursor != "" {
			path += "&start_cursor=" + cursor
		}

		data, err := c.doRequest("GET", path, nil)
		if err != nil {
			return nil, err
		}

		var result BlockList
		if err := json.Unmarshal(data, &result); err != nil {
			return nil, err
		}

		all = append(all, result.Results...)

		if !result.HasMore {
			break
		}
		cursor = result.NextCursor
	}

	// Recursively fetch children for blocks that have them (toggles, etc.)
	for i := range all {
		if all[i].HasChildren && all[i].Type != "child_database" && all[i].Type != "table" {
			children, err := c.GetBlockChildren(all[i].ID)
			if err != nil {
				continue
			}
			switch all[i].Type {
			case "toggle":
				if all[i].Toggle != nil {
					all[i].Toggle.Children = children
				}
			case "bulleted_list_item":
				if all[i].BulletedListItem != nil {
					all[i].BulletedListItem.Children = children
				}
			case "numbered_list_item":
				if all[i].NumberedListItem != nil {
					all[i].NumberedListItem.Children = children
				}
			case "quote":
				if all[i].Quote != nil {
					all[i].Quote.Children = children
				}
			case "callout":
				// Store children separately — we'll handle inline
			}
		}
		// For tables, fetch rows
		if all[i].Type == "table" && all[i].HasChildren {
			rows, err := c.GetBlockChildren(all[i].ID)
			if err == nil {
				all[i].Table.Rows = rows
			}
		}
	}

	return all, nil
}

func (c *NotionClient) QueryDatabase(dbID string) ([]DatabaseEntry, error) {
	dbID = strings.ReplaceAll(dbID, "-", "")
	var all []DatabaseEntry
	cursor := ""

	for {
		body := `{"page_size": 100`
		if cursor != "" {
			body += `,"start_cursor":"` + cursor + `"`
		}
		body += `}`

		data, err := c.doRequest("POST", "/databases/"+dbID+"/query", strings.NewReader(body))
		if err != nil {
			return nil, err
		}

		var result DatabaseQueryResult
		if err := json.Unmarshal(data, &result); err != nil {
			return nil, err
		}

		all = append(all, result.Results...)

		if !result.HasMore {
			break
		}
		cursor = result.NextCursor
	}

	return all, nil
}
