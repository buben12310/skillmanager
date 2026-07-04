package agent

import (
	"database/sql"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"skillmanager-core/internal/storage"
	"skillmanager-core/pkg/models"
)

type Repository struct{ db *sql.DB }

func NewRepository(db *sql.DB) *Repository { return &Repository{db: db} }

func (r *Repository) List() ([]models.Agent, error) {
	rows, err := r.db.Query(`SELECT id, name, icon, icon_color, skill_path, mcp_path, status, format, created_at, updated_at FROM agents ORDER BY created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []models.Agent{}
	for rows.Next() {
		var a models.Agent
		var createdAt, updatedAt string
		if err := rows.Scan(&a.ID, &a.Name, &a.Icon, &a.IconColor, &a.SkillPath, &a.McpPath, &a.Status, &a.Format, &createdAt, &updatedAt); err != nil {
			return nil, err
		}
		a.CreatedAt, _ = time.Parse(time.RFC3339, createdAt)
		a.UpdatedAt, _ = time.Parse(time.RFC3339, updatedAt)
		out = append(out, a)
	}
	return out, nil
}

func (r *Repository) Get(id string) (*models.Agent, error) {
	var a models.Agent
	var createdAt, updatedAt string
	err := r.db.QueryRow(`SELECT id, name, icon, icon_color, skill_path, mcp_path, status, format, created_at, updated_at FROM agents WHERE id=?`, id).
		Scan(&a.ID, &a.Name, &a.Icon, &a.IconColor, &a.SkillPath, &a.McpPath, &a.Status, &a.Format, &createdAt, &updatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	a.CreatedAt, _ = time.Parse(time.RFC3339, createdAt)
	a.UpdatedAt, _ = time.Parse(time.RFC3339, updatedAt)
	return &a, nil
}

func (r *Repository) Create(req models.CreateAgentRequest) (*models.Agent, error) {
	now := time.Now().UTC()
	status := "active"
	if req.SkillPath == "" {
		status = "unconfigured"
	}
	a := &models.Agent{
		ID:        storage.NewID(),
		Name:      req.Name,
		Icon:      req.Icon,
		IconColor: req.IconColor,
		SkillPath: req.SkillPath,
		McpPath:   req.McpPath,
		Status:    status,
		Format:    req.Format,
		CreatedAt: now,
		UpdatedAt: now,
	}
	_, err := r.db.Exec(`INSERT INTO agents (id, name, icon, icon_color, skill_path, mcp_path, status, format, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?)`,
		a.ID, a.Name, a.Icon, a.IconColor, a.SkillPath, a.McpPath, a.Status, a.Format, now.Format(time.RFC3339), now.Format(time.RFC3339))
	if err != nil {
		return nil, err
	}
	return a, nil
}

func (r *Repository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM agents WHERE id=?`, id)
	return err
}

// agentCandidate 描述一个预设 agent 的检测信息
type agentCandidate struct {
	format     string   // claude-code | codex | opencode | hermes | trae | zcode | workbuddy
	name       string   // 显示名
	icon       string   // 图标 (2 字母缩写)
	color      string   // 图标颜色
	skillPath  string   // 默认 skill 路径 (写入数据库,~/... 或绝对路径)
	mcpPath    string   // 默认 mcp 路径
	configDirs []string // 候选配置目录,任一存在即视为已安装
	skillDirs  []string // 候选 skill 目录,扫描 skill 时按序尝试
	exes       []string // 候选可执行文件名,用于 PATH 检测
}

// presetCandidates 返回 7 个预设 agent 的检测信息
// 路径已根据各 agent 官方文档校验:
// - Codex: ~/.codex/skills/ (官方 skills 目录)
// - Hermes: 同时检测 ~/.hermes/ (WSL2/Linux/macOS) 和 %LOCALAPPDATA%\hermes\ (Windows 原生)
// - Trae: 同时检测 ~/.traecli/ (CLI 原生) 和 ~/.trae-cn/ (TRAE IDE,CLI 兼容)
func presetCandidates() []agentCandidate {
	traeSkill := "~/.trae-cn/skills/"
	traeMcp := "~/.trae-cn/mcp/"
	// Hermes 候选目录: ~/.hermes/ (WSL2/Linux/macOS/手动安装) + %LOCALAPPDATA%\hermes\ (Windows 原生)
	hermesConfigDirs := []string{"~/.hermes/"}
	hermesSkillDirs := []string{"~/.hermes/skills/"}
	if local := os.Getenv("LOCALAPPDATA"); local != "" {
		winHermes := filepath.ToSlash(filepath.Join(local, "hermes")) + "/"
		hermesConfigDirs = append(hermesConfigDirs, winHermes)
		hermesSkillDirs = append(hermesSkillDirs, winHermes+"skills/")
	}
	return []agentCandidate{
		{
			format: "claude-code", name: "Claude Code", icon: "CC", color: "#534AB7",
			skillPath: "~/.claude/skills/", mcpPath: "~/.claude/mcp/",
			configDirs: []string{"~/.claude/"}, skillDirs: []string{"~/.claude/skills/"},
			exes: []string{"claude"},
		},
		{
			format: "codex", name: "Codex", icon: "CX", color: "#185FA5",
			skillPath: "~/.codex/skills/", mcpPath: "~/.codex/mcp/",
			configDirs: []string{"~/.codex/"}, skillDirs: []string{"~/.codex/skills/"},
			exes: []string{"codex"},
		},
		{
			format: "opencode", name: "OpenCode", icon: "OC", color: "#0F6E56",
			skillPath: "~/.config/opencode/skills/", mcpPath: "~/.config/opencode/mcp/",
			configDirs: []string{"~/.config/opencode/"}, skillDirs: []string{"~/.config/opencode/skills/"},
			exes: []string{"opencode"},
		},
		{
			format: "hermes", name: "Hermes", icon: "HE", color: "#E24B4A",
			skillPath: "~/.hermes/skills/", mcpPath: "~/.hermes/mcp/",
			configDirs: hermesConfigDirs, skillDirs: hermesSkillDirs,
			exes: []string{"hermes"},
		},
		{
			format: "trae", name: "Trae", icon: "TR", color: "#7C3AED",
			skillPath: traeSkill, mcpPath: traeMcp,
			configDirs: []string{"~/.trae-cn/", "~/.traecli/"},
			skillDirs:  []string{"~/.trae-cn/skills/", "~/.traecli/skills/"},
			exes:       []string{"traecli", "trae"},
		},
		{
			format: "zcode", name: "ZCode", icon: "ZC", color: "#2563EB",
			skillPath: "~/.zcode/skills/", mcpPath: "~/.zcode/mcp/",
			configDirs: []string{"~/.zcode/"},
			skillDirs: []string{
				"~/.zcode/skills/",
				"~/.zcode/cli/plugins/cache/zcode-plugins-official/",
			},
			exes: []string{"zcode"},
		},
		{
			format: "workbuddy", name: "WorkBuddy", icon: "WB", color: "#059669",
			skillPath: "~/.workbuddy/skills/", mcpPath: "~/.workbuddy/mcp/",
			configDirs: []string{"~/.workbuddy/"}, skillDirs: []string{"~/.workbuddy/skills/"},
			exes: []string{"workbuddy"},
		},
	}
}

// Scan 扫描文件系统,发现已安装的 agent。
// 所有 7 个预设 agent 始终在数据库中 (首次启动由 seed.go 插入),
// 扫描后按实际检测结果更新状态: 已安装 → active, 未安装 → unconfigured。
// 检测到实际安装目录后,更新数据库中的 skillPath/mcpPath 为实际路径。
// 同时扫描 agent 目录下的实际 skill 文件夹并注册到数据库。
func (r *Repository) Scan() ([]models.DiscoveredAgent, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	candidates := presetCandidates()

	// 确保所有预设 agent 都在数据库中 (防止用户删除后丢失)
	existingFormats, _ := r.existingFormats()
	for _, c := range candidates {
		if !contains(existingFormats, c.format) {
			r.createPresetAgent(c)
		}
	}

	// 检测每个 agent 是否已安装,并更新状态和路径
	var discovered []models.DiscoveredAgent
	for _, c := range candidates {
		found, foundConfigDir, foundSkillDir := r.detectAgent(c, home)

		// 更新 agent 状态: 已安装 → active, 未安装 → unconfigured
		status := "unconfigured"
		if found {
			status = "active"
			// 如果检测到实际 skill 目录与数据库默认值不同,更新数据库
			if foundSkillDir != "" {
				actualSkillPath := filepath.ToSlash(foundSkillDir)
				if !strings.HasSuffix(actualSkillPath, "/") {
					actualSkillPath += "/"
				}
				if actualSkillPath != c.skillPath {
					r.updateSkillPathByFormat(c.format, actualSkillPath)
				}
			}
		}
		r.updateStatusByFormat(c.format, status)

		displayPath := foundConfigDir
		if displayPath == "" {
			if len(c.configDirs) > 0 {
				displayPath = expandHome(c.configDirs[0], home)
			}
		}
		discovered = append(discovered, models.DiscoveredAgent{
			Type:     c.format,
			Path:     displayPath,
			Existing: found,
		})
	}

	// 扫描所有 agent 的 skill 目录,导入实际 skill 文件夹
	// 直接使用候选列表中的所有 skillDirs (而非仅数据库 skillPath),
	// 这样能覆盖 ZCode 插件缓存等非标准位置
	if err := r.scanAndImportSkillsWithCandidates(candidates, home); err != nil {
		_ = err // 扫描 skill 失败不影响 agent 扫描结果
	}

	return discovered, nil
}

// detectAgent 检测 agent 是否已安装
// 返回: (是否找到, 实际配置目录, 实际 skill 目录)
func (r *Repository) detectAgent(c agentCandidate, home string) (bool, string, string) {
	// 1. 检查候选配置目录是否存在
	for _, dir := range c.configDirs {
		configDir := expandHome(dir, home)
		if info, err := os.Stat(configDir); err == nil && info.IsDir() {
			// 找到配置目录,进一步找 skill 目录
			skillDir := ""
			for _, sd := range c.skillDirs {
				resolved := expandHome(sd, home)
				if info, err := os.Stat(resolved); err == nil && info.IsDir() {
					skillDir = resolved
					break
				}
			}
			return true, configDir, skillDir
		}
	}

	// 2. 检查可执行文件是否在 PATH 中
	for _, exe := range c.exes {
		if exePath, err := exec.LookPath(exe); err == nil && exePath != "" {
			return true, exePath, ""
		}
	}

	// 3. 额外检查: npm 全局 / cargo bin / LOCALAPPDATA
	for _, exe := range c.exes {
		if extra := checkExtraPaths(exe); extra != "" {
			return true, extra, ""
		}
	}

	return false, "", ""
}

// createPresetAgent 创建预设 agent 记录 (状态为 unconfigured)
func (r *Repository) createPresetAgent(c agentCandidate) {
	now := time.Now().UTC().Format(time.RFC3339)
	r.db.Exec(`INSERT INTO agents (id, name, icon, icon_color, skill_path, mcp_path, status, format, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?)`,
		storage.NewID(), c.name, c.icon, c.color, c.skillPath, c.mcpPath, "unconfigured", c.format, now, now)
}

// updateStatusByFormat 按 format 更新 agent 状态
func (r *Repository) updateStatusByFormat(format, status string) {
	now := time.Now().UTC().Format(time.RFC3339)
	r.db.Exec(`UPDATE agents SET status=?, updated_at=? WHERE format=?`, status, now, format)
}

// updateSkillPathByFormat 按 format 更新 agent 的 skill 路径
func (r *Repository) updateSkillPathByFormat(format, skillPath string) {
	now := time.Now().UTC().Format(time.RFC3339)
	r.db.Exec(`UPDATE agents SET skill_path=?, updated_at=? WHERE format=?`, skillPath, now, format)
}

// scanAndImportSkillsWithCandidates 使用候选列表扫描所有 agent 的 skill 目录。
// 采用递归深度扫描: 在每个候选 skill 根目录下递归查找所有含 SKILL.md 的目录。
// 这能正确处理各种嵌套结构:
//   - 扁平: <skill-name>/SKILL.md
//   - 2层 category (Hermes): <category>/<skill-name>/SKILL.md
//   - 3层嵌套 (obra/skills 仓库): skills/skills/<skill-name>/SKILL.md
//   - 插件结构 (ZCode): plugins/cache/<plugin>/<version>/skills/<skill-name>/SKILL.md
//
// 显示名取相对于扫描根目录的路径 (去掉末尾的 /SKILL.md)
func (r *Repository) scanAndImportSkillsWithCandidates(candidates []agentCandidate, home string) error {
	// 从数据库读取已存在的 agent (用于关联 skill)
	agents, err := r.List()
	if err != nil {
		return err
	}
	agentByFormat := map[string]models.Agent{}
	for _, a := range agents {
		agentByFormat[a.Format] = a
	}

	for _, c := range candidates {
		a, ok := agentByFormat[c.format]
		if !ok {
			continue
		}
		// 遍历所有候选 skill 目录 (ZCode 可能同时有 skills/ 和 plugins/cache/)
		for _, sd := range c.skillDirs {
			skillDir := expandHome(sd, home)
			if skillDir == "" {
				continue
			}
			info, err := os.Stat(skillDir)
			if err != nil || !info.IsDir() {
				continue
			}
			// 递归扫描 skill 目录,收集所有含 SKILL.md 的目录
			r.walkAndImportSkills(a, skillDir, skillDir, 0)
		}
	}

	return nil
}

// maxScanDepth 限制递归深度,避免无限递归和扫描过深
const maxScanDepth = 8

// walkAndImportSkills 递归扫描目录,找到含 SKILL.md 的子目录并导入。
// rootDir 是 skill 根目录 (用于计算相对路径作为显示名),currentDir 是当前扫描目录。
func (r *Repository) walkAndImportSkills(a models.Agent, rootDir, currentDir string, depth int) {
	if depth > maxScanDepth {
		return
	}

	entries, err := os.ReadDir(currentDir)
	if err != nil {
		return
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		name := entry.Name()
		// 跳过隐藏目录 (如 .git, .system, .hub 等)
		if strings.HasPrefix(name, ".") {
			continue
		}

		entryPath := filepath.Join(currentDir, name)

		if hasSkillFile(entryPath) {
			// 该目录含 SKILL.md,识别为一个 skill
			relPath, err := filepath.Rel(rootDir, entryPath)
			if err != nil {
				relPath = name
			}
			// 显示名: 用相对路径,斜杠分隔 (如 "creative/excalidraw" 或 "skills/skills/docx")
			displayName := filepath.ToSlash(relPath)
			r.importSkillIfNew(a, entryPath, displayName)
		} else {
			// 该目录不含 SKILL.md,继续递归扫描子目录
			r.walkAndImportSkills(a, rootDir, entryPath, depth+1)
		}
	}
}

// importSkillIfNew 导入 skill (如果尚未导入)
func (r *Repository) importSkillIfNew(a models.Agent, skillPath, name string) {
	skillPathSlash := filepath.ToSlash(skillPath)
	if !strings.HasSuffix(skillPathSlash, "/") {
		skillPathSlash += "/"
	}

	// 去重检查
	var count int
	r.db.QueryRow(`SELECT COUNT(*) FROM skills WHERE agent_id=? AND path=?`, a.ID, skillPathSlash).Scan(&count)
	if count > 0 {
		return
	}

	now := time.Now().UTC().Format(time.RFC3339)
	r.db.Exec(`INSERT INTO skills (id, agent_id, name, version, author, source, source_url, path, enabled, format, dependencies, installed_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`,
		storage.NewID(), a.ID, name, "", "", "local", "", skillPathSlash, 1, a.Format, "[]", now)
}

// expandHome 展开 ~ 为 home 目录
func expandHome(path, home string) string {
	if path == "" {
		return ""
	}
	if strings.HasPrefix(path, "~/") {
		return filepath.Join(home, path[2:])
	}
	if path == "~" {
		return home
	}
	return path
}

// hasSkillFile 检查目录中是否包含 SKILL.md (不区分大小写)
func hasSkillFile(dir string) bool {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return false
	}
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		name := strings.ToLower(e.Name())
		if name == "skill.md" {
			return true
		}
	}
	return false
}

// existingFormats 返回数据库中已存在的 agent format 列表
func (r *Repository) existingFormats() ([]string, error) {
	rows, err := r.db.Query(`SELECT DISTINCT format FROM agents`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var formats []string
	for rows.Next() {
		var f string
		if err := rows.Scan(&f); err != nil {
			return nil, err
		}
		formats = append(formats, f)
	}
	return formats, nil
}

// checkExtraPaths 检查 npm 全局 / cargo bin 等额外路径
func checkExtraPaths(exeName string) string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}

	var candidates []string
	if runtime.GOOS == "windows" {
		if appdata := os.Getenv("APPDATA"); appdata != "" {
			candidates = append(candidates, filepath.Join(appdata, "npm", exeName+".cmd"))
			candidates = append(candidates, filepath.Join(appdata, "npm", exeName))
		}
		candidates = append(candidates, filepath.Join(home, ".cargo", "bin", exeName+".exe"))
		if local := os.Getenv("LOCALAPPDATA"); local != "" {
			candidates = append(candidates, filepath.Join(local, exeName, exeName+".exe"))
		}
	} else {
		candidates = append(candidates, filepath.Join(home, ".cargo", "bin", exeName))
		candidates = append(candidates, filepath.Join(home, ".local", "bin", exeName))
		candidates = append(candidates, filepath.Join("/usr", "local", "bin", exeName))
	}

	for _, p := range candidates {
		if info, err := os.Stat(p); err == nil && !info.IsDir() {
			return p
		}
	}
	return ""
}

func contains(slice []string, s string) bool {
	for _, v := range slice {
		if v == s {
			return true
		}
	}
	return false
}
