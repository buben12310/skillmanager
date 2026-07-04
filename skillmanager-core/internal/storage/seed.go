package storage

import (
	"database/sql"
	"time"
)

// SeedIfEmpty 当 agents 表为空时插入预设数据 + 对应 skills/mcps
// 路径已根据各 agent 官方文档校验:
// - Codex: ~/.codex/skills/ (官方 skills 目录,非 prompts/)
// - Hermes: ~/.hermes/skills/ (Windows 原生在 %LOCALAPPDATA%\hermes\,由扫描逻辑多候选检测)
// 所有预设 agent 初始状态为 unconfigured (未安装),扫描后按实际检测结果更新
func SeedIfEmpty(db *sql.DB) error {
	var count int
	if err := db.QueryRow(`SELECT COUNT(*) FROM agents`).Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil
	}
	now := time.Now().UTC().Format(time.RFC3339)
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	type seedAgent struct {
		id, name, icon, color, skillPath, mcpPath, status, format string
	}
	agents := []seedAgent{
		{NewID(), "Claude Code", "CC", "#534AB7", "~/.claude/skills/", "~/.claude/mcp/", "unconfigured", "claude-code"},
		{NewID(), "Codex", "CX", "#185FA5", "~/.codex/skills/", "~/.codex/mcp/", "unconfigured", "codex"},
		{NewID(), "OpenCode", "OC", "#0F6E56", "~/.config/opencode/skills/", "~/.config/opencode/mcp/", "unconfigured", "opencode"},
		{NewID(), "Hermes", "HE", "#E24B4A", "~/.hermes/skills/", "~/.hermes/mcp/", "unconfigured", "hermes"},
		{NewID(), "Trae", "TR", "#7C3AED", "~/.trae-cn/skills/", "~/.trae-cn/mcp/", "unconfigured", "trae"},
		{NewID(), "ZCode", "ZC", "#2563EB", "~/.zcode/skills/", "~/.zcode/mcp/", "unconfigured", "zcode"},
		{NewID(), "WorkBuddy", "WB", "#059669", "~/.workbuddy/skills/", "~/.workbuddy/mcp/", "unconfigured", "workbuddy"},
	}
	for _, a := range agents {
		_, err := tx.Exec(`INSERT INTO agents (id, name, icon, icon_color, skill_path, mcp_path, status, format, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?)`,
			a.id, a.name, a.icon, a.color, a.skillPath, a.mcpPath, a.status, a.format, now, now)
		if err != nil {
			return err
		}
	}

	// 为 Claude Code 加 3 个 Skill + 2 个 MCP
	a0 := agents[0]
	skills := []struct {
		name, version, author, source, sourceURL, path, format string
		enabled bool
	}{
		{"agent-skills", "1.0.0", "Addy Osmani", "marketplace", "github.com/addyosmani/agent-skills", a0.skillPath + "agent-skills/", "claude-code", true},
		{"obsidian-retrieval", "2.1.0", "本地", "local", "", a0.skillPath + "obsidian-retrieval/", "claude-code", false},
		{"wb-finance-skill", "1.2.0", "Builtin", "builtin", "", a0.skillPath + "wb-finance-skill/", "claude-code", true},
	}
	for _, s := range skills {
		_, err := tx.Exec(`INSERT INTO skills (id, agent_id, name, version, author, source, source_url, path, enabled, format, dependencies, installed_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`,
			NewID(), a0.id, s.name, s.version, s.author, s.source, s.sourceURL, s.path, boolToInt(s.enabled), s.format, "[]", now)
		if err != nil {
			return err
		}
	}

	mcps := []struct {
		name, command, args, path string
		connected                bool
		tools                     string
	}{
		{"obsidian", "npx", `["-y","@anthropic/mcp-obsidian"]`, a0.mcpPath + "obsidian.json", true, `["read_note","write_note","search_notes"]`},
		{"filesystem", "npx", `["-y","@modelcontextprotocol/server-filesystem"]`, a0.mcpPath + "filesystem.json", false, "[]"},
	}
	for _, m := range mcps {
		_, err := tx.Exec(`INSERT INTO mcps (id, agent_id, name, command, args, path, connected, tools, last_tested_at) VALUES (?,?,?,?,?,?,?,?,NULL)`,
			NewID(), a0.id, m.name, m.command, m.args, m.path, boolToInt(m.connected), m.tools)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}
