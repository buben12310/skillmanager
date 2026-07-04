package agent

import (
	"skillmanager-core/pkg/models"
)

// 内置模板,路径已根据各 agent 官方文档校验
// Codex: ~/.codex/skills/ (官方 skills 目录,非 prompts/)
// Hermes: ~/.hermes/skills/ (WSL2/Linux/macOS/手动安装;Windows 原生在 %LOCALAPPDATA%\hermes\,由扫描逻辑多候选检测)
// Trae: ~/.trae-cn/skills/ (TRAE IDE 目录,TRAE CLI 兼容读取)
func Templates() []models.CreateAgentRequest {
	return []models.CreateAgentRequest{
		{Name: "Claude Code", Icon: "CC", IconColor: "#534AB7", SkillPath: "~/.claude/skills/", McpPath: "~/.claude/mcp/", Format: "claude-code"},
		{Name: "Codex", Icon: "CX", IconColor: "#185FA5", SkillPath: "~/.codex/skills/", McpPath: "~/.codex/mcp/", Format: "codex"},
		{Name: "OpenCode", Icon: "OC", IconColor: "#0F6E56", SkillPath: "~/.config/opencode/skills/", McpPath: "~/.config/opencode/mcp/", Format: "opencode"},
		{Name: "Hermes", Icon: "HE", IconColor: "#E24B4A", SkillPath: "~/.hermes/skills/", McpPath: "~/.hermes/mcp/", Format: "hermes"},
		{Name: "Trae", Icon: "TR", IconColor: "#7C3AED", SkillPath: "~/.trae-cn/skills/", McpPath: "~/.trae-cn/mcp/", Format: "trae"},
		{Name: "ZCode", Icon: "ZC", IconColor: "#2563EB", SkillPath: "~/.zcode/skills/", McpPath: "~/.zcode/mcp/", Format: "zcode"},
		{Name: "WorkBuddy", Icon: "WB", IconColor: "#059669", SkillPath: "~/.workbuddy/skills/", McpPath: "~/.workbuddy/mcp/", Format: "workbuddy"},
	}
}
