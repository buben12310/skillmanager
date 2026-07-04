package models

import "time"

type Agent struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Icon      string    `json:"icon"`
	IconColor string    `json:"iconColor"` // hex "#534AB7"
	SkillPath string    `json:"skillPath"`
	McpPath   string    `json:"mcpPath"`
	Status    string    `json:"status"` // active|inactive|unconfigured
	Format    string    `json:"format"` // claude-code|codex|opencode|hermes|generic
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

type Skill struct {
	ID           string    `json:"id"`
	AgentID      string    `json:"agentId"`
	Name         string    `json:"name"`
	Version      string    `json:"version"`
	Author       string    `json:"author"`
	Source       string    `json:"source"` // marketplace|local|builtin|import
	SourceURL    string    `json:"sourceUrl"`
	Path         string    `json:"path"`
	Enabled      bool      `json:"enabled"`
	Format       string    `json:"format"`
	Dependencies []string  `json:"dependencies"`
	InstalledAt  time.Time `json:"installedAt"`
}

type MCP struct {
	ID          string    `json:"id"`
	AgentID     string    `json:"agentId"`
	Name        string    `json:"name"`
	Command     string    `json:"command"`
	Args        []string  `json:"args"`
	Path        string    `json:"path"`
	Connected   bool      `json:"connected"`
	Tools       []string  `json:"tools"`
	LastTestedAt *time.Time `json:"lastTestedAt"`
}

type DiscoveredAgent struct {
	Type     string `json:"type"`
	Path     string `json:"path"`
	Existing bool   `json:"existing"`
}

type CreateAgentRequest struct {
	Name      string `json:"name"`
	Icon      string `json:"icon"`
	IconColor string `json:"iconColor"`
	SkillPath string `json:"skillPath"`
	McpPath   string `json:"mcpPath"`
	Format    string `json:"format"`
}

// Phase 3: 市场相关
type MarketplaceRepo struct {
	FullName      string   `json:"fullName"`
	Owner         string   `json:"owner"`
	Name          string   `json:"name"`
	Description   string   `json:"description"`
	Stars         int      `json:"stars"`
	Forks         int      `json:"forks"`
	Language      string   `json:"language"`
	License       string   `json:"license"`
	DefaultBranch string   `json:"defaultBranch"`
	Topics        []string `json:"topics"`
	Category      string   `json:"category"`
}

type InstallRequest struct {
	Repo    string `json:"repo"`    // "owner/name"
	AgentID string `json:"agentId"`
	SubPath string `json:"subPath"` // 可选: 子目录
	Force   bool   `json:"force"`   // 已存在时是否强制覆盖
}
