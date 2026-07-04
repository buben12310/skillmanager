package marketplace

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"skillmanager-core/pkg/errors"
	"skillmanager-core/pkg/models"
)

type Service struct {
	gh    *GitHubClient
	db    *sql.DB
	cache *Cache
}

func NewService(gh *GitHubClient, db *sql.DB) *Service {
	return &Service{gh: gh, db: db, cache: NewCache()}
}

// List 列出仓库 (缓存优先 → GitHub)
func (s *Service) List(ctx context.Context, category string) ([]models.MarketplaceRepo, error) {
	cacheKey := "list:" + category
	if v, ok := s.cache.Get(cacheKey); ok {
		return v.([]models.MarketplaceRepo), nil
	}
	// 1. 先查 DB 缓存
	if cached := s.queryFromDB(category); len(cached) > 0 {
		s.cache.Set(cacheKey, cached, 5*time.Minute)
		return cached, nil
	}
	// 2. 拉 GitHub
	res, err := s.gh.ListByTopic(ctx)
	if err != nil {
		// 降级: 看是否有任何 DB 数据
		if fallback := s.queryFromDB(""); len(fallback) > 0 {
			return fallback, nil
		}
		return nil, errors.Internal(err)
	}
	// 3. 写 DB 缓存
	s.upsertMany(res)
	out := s.queryFromDB(category)
	s.cache.Set(cacheKey, out, 5*time.Minute)
	return out, nil
}

// Get 单个仓库
func (s *Service) Get(ctx context.Context, owner, name string) (*models.MarketplaceRepo, error) {
	fn := owner + "/" + name
	cacheKey := "repo:" + fn
	if v, ok := s.cache.Get(cacheKey); ok {
		return v.(*models.MarketplaceRepo), nil
	}
	r, err := s.gh.Get(ctx, owner, name)
	if err != nil {
		return nil, errors.NotFound("repo not found: " + fn)
	}
	s.cache.Set(cacheKey, r, 10*time.Minute)
	return r, nil
}

// README 拉取并缓存
func (s *Service) README(ctx context.Context, owner, name string) (string, error) {
	cacheKey := "readme:" + owner + "/" + name
	if v, ok := s.cache.Get(cacheKey); ok {
		return v.(string), nil
	}
	md, err := s.gh.README(ctx, owner, name)
	if err != nil {
		return "", errors.NotFound("README not found")
	}
	s.cache.Set(cacheKey, md, 30*time.Minute)
	return md, nil
}

// Search 搜索
func (s *Service) Search(ctx context.Context, query string) ([]models.MarketplaceRepo, error) {
	res, err := s.gh.Search(ctx, query)
	if err != nil {
		return nil, errors.Internal(err)
	}
	return res, nil
}

// Install 智能安装: 检测仓库结构 (单 skill / skillpack), 安装到 agent skill 目录。
// - 单 skill (仓库根有 SKILL.md): 整个仓库安装为 <skill_dir>/<repo_name>/
// - skillpack (仓库含 skills/<sub>/SKILL.md): 每个子 skill 直接安装到 <skill_dir>/<sub>/
//   典型: obra/skills 仓库内含 skills/ 子目录,每个子目录是一个独立 skill。
// clone 到临时目录,拷贝完成后再删除临时目录,避免污染。
// 网络超时 / git 不可用都会返回友好错误。
func (s *Service) Install(ctx context.Context, req models.InstallRequest) (*models.Skill, error) {
	parts := strings.SplitN(req.Repo, "/", 2)
	if len(parts) != 2 {
		return nil, errors.BadRequest("invalid repo format")
	}
	owner, name := parts[0], parts[1]

	// 1. 获取 agent skillPath 与 format
	var skillPath, agentFormat string
	err := s.db.QueryRow("SELECT skill_path, format FROM agents WHERE id = ?", req.AgentID).
		Scan(&skillPath, &agentFormat)
	if err != nil {
		return nil, errors.NotFound("agent not found")
	}

	// 2. 展开 ~ 并确保 skill 根目录存在
	home, _ := os.UserHomeDir()
	skillPath = expandHome(skillPath, home)
	if err := os.MkdirAll(skillPath, 0o755); err != nil {
		return nil, errors.Internal(fmt.Errorf("create skill dir failed: %w", err))
	}

	// 2.5 预清理: 若目标目录中已有以 repo_name 命名的子目录,且其内含 skills/ 子目录
	// (说明是旧版错误安装的 skillpack 残留),直接删除避免污染。
	legacyBadDir := filepath.Join(skillPath, name)
	if info, err := os.Stat(legacyBadDir); err == nil && info.IsDir() {
		// 检测是否是旧版 skillpack 错误安装 (内含 skills/ 子目录)
		if _, err := os.Stat(filepath.Join(legacyBadDir, "skills")); err == nil {
			_ = os.RemoveAll(legacyBadDir)
		}
	}

	// 3. 检测 git 可用
	if _, err := exec.LookPath("git"); err != nil {
		return nil, errors.BadRequest("未检测到 git,请先安装 Git 并加入 PATH")
	}

	// 4. clone 到临时目录 (避免污染目标)
	tmpDir, err := os.MkdirTemp("", "skillmanager-clone-*")
	if err != nil {
		return nil, errors.Internal(fmt.Errorf("create temp dir failed: %w", err))
	}
	defer os.RemoveAll(tmpDir)

	cloneTarget := filepath.Join(tmpDir, name)
	cloneURL := "https://github.com/" + req.Repo + ".git"
	// 加 1 分钟超时 (skill 文件通常很小),避免网络问题卡死
	cloneCtx, cancel := context.WithTimeout(ctx, 1*time.Minute)
	defer cancel()
	cmd := exec.CommandContext(cloneCtx, "git", "clone", "--depth", "1", cloneURL, cloneTarget)
	if out, err := cmd.CombinedOutput(); err != nil {
		// 友好错误: 区分超时 / 网络错误
		if cloneCtx.Err() == context.DeadlineExceeded {
			return nil, errors.BadRequest("克隆超时 (1 分钟),可能是网络问题或仓库过大,请检查网络后重试")
		}
		msg := strings.TrimSpace(string(out))
		if msg == "" {
			msg = err.Error()
		}
		return nil, errors.BadRequest("git clone 失败: " + msg)
	}

	// 5. 检测仓库结构: 单 skill 还是 skillpack
	installed := s.installDetectedSkills(cloneTarget, skillPath, req, owner, name, agentFormat)
	if len(installed) == 0 {
		return nil, errors.BadRequest("仓库中未找到任何 SKILL.md 文件,无法识别为有效 skill")
	}

	// 6. 返回第一个 skill 作为代表 (其余通过 scanAndImportSkills 自动入库)
	first := installed[0]
	return first, nil
}

// installDetectedSkills 检测仓库结构并安装 skill。
// 返回所有成功安装的 skill 列表。
func (s *Service) installDetectedSkills(cloneDir, skillDir string, req models.InstallRequest, owner, repoName, agentFormat string) []*models.Skill {
	var installed []*models.Skill

	// 情况 A: 仓库根有 SKILL.md → 单 skill,整个目录安装为 <skill_dir>/<repo_name>/
	if hasSkillFile(cloneDir) {
		sk := s.installSingleSkill(cloneDir, filepath.Join(skillDir, repoName), req, owner, repoName, agentFormat)
		if sk != nil {
			installed = append(installed, sk)
		}
		return installed
	}

	// 情况 B: 仓库含 skills/ 子目录,每个子目录是独立 skill (skillpack 结构)
	skillsSubDir := filepath.Join(cloneDir, "skills")
	if info, err := os.Stat(skillsSubDir); err == nil && info.IsDir() {
		entries, err := os.ReadDir(skillsSubDir)
		if err == nil {
			for _, e := range entries {
				if !e.IsDir() || strings.HasPrefix(e.Name(), ".") {
					continue
				}
				srcSkill := filepath.Join(skillsSubDir, e.Name())
				if !hasSkillFile(srcSkill) {
					continue
				}
				dstSkill := filepath.Join(skillDir, e.Name())
				sk := s.installSingleSkill(srcSkill, dstSkill, req, owner, e.Name(), agentFormat)
				if sk != nil {
					installed = append(installed, sk)
				}
			}
		}
	}

	// 情况 C: 仓库根直接含多个子目录,每个子目录有 SKILL.md (无 skills/ 父目录)
	if len(installed) == 0 {
		entries, err := os.ReadDir(cloneDir)
		if err == nil {
			for _, e := range entries {
				if !e.IsDir() || strings.HasPrefix(e.Name(), ".") {
					continue
				}
				srcSkill := filepath.Join(cloneDir, e.Name())
				if !hasSkillFile(srcSkill) {
					continue
				}
				dstSkill := filepath.Join(skillDir, e.Name())
				sk := s.installSingleSkill(srcSkill, dstSkill, req, owner, e.Name(), agentFormat)
				if sk != nil {
					installed = append(installed, sk)
				}
			}
		}
	}

	return installed
}

// installSingleSkill 把源 skill 目录拷贝到目标目录,并构造 Skill 记录。
// 若目标已存在: force=true 则覆盖,否则跳过 (返回 nil)。
func (s *Service) installSingleSkill(src, dst string, req models.InstallRequest, owner, skillName, agentFormat string) *models.Skill {
	// 目标已存在处理
	if _, err := os.Stat(dst); err == nil {
		if !req.Force {
			// 已存在且不覆盖,跳过 (不报错,允许 skillpack 部分安装)
			return nil
		}
		_ = os.RemoveAll(dst)
	}

	// 拷贝目录
	if err := copyDir(src, dst); err != nil {
		return nil
	}

	// 构造 skill 记录
	dstSlash := filepath.ToSlash(dst)
	if !strings.HasSuffix(dstSlash, "/") {
		dstSlash += "/"
	}
	return &models.Skill{
		ID:           fmt.Sprintf("mk-%s-%d", skillName, time.Now().UnixNano()),
		AgentID:      req.AgentID,
		Name:         skillName,
		Version:      "1.0.0",
		Author:       owner,
		Source:       "marketplace",
		SourceURL:    "github.com/" + req.Repo,
		Path:         dstSlash,
		Enabled:      true,
		Format:       agentFormat,
		Dependencies: []string{},
		InstalledAt:  time.Now(),
	}
}

// copyDir 递归拷贝目录
func copyDir(src, dst string) error {
	return filepath.Walk(src, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}
		target := filepath.Join(dst, rel)
		if info.IsDir() {
			return os.MkdirAll(target, 0o755)
		}
		// 跳过 .git 目录内容
		if strings.Contains(rel, ".git") {
			return nil
		}
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		return os.WriteFile(target, data, info.Mode())
	})
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
		if strings.ToLower(e.Name()) == "skill.md" {
			return true
		}
	}
	return false
}

// expandHome 展开 ~ 为 home 目录 (跨平台)
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

// === DB 缓存 ===

func (s *Service) queryFromDB(category string) []models.MarketplaceRepo {
	q := "SELECT full_name, owner, name, description, stars, forks, language, license, default_branch, topics, category FROM marketplace_repos"
	args := []any{}
	if category != "" && category != "全部" {
		q += " WHERE category = ?"
		args = append(args, category)
	}
	q += " ORDER BY stars DESC LIMIT 50"
	rows, err := s.db.Query(q, args...)
	if err != nil {
		return nil
	}
	defer rows.Close()
	out := []models.MarketplaceRepo{}
	for rows.Next() {
		var m models.MarketplaceRepo
		var topicsJSON string
		if err := rows.Scan(&m.FullName, &m.Owner, &m.Name, &m.Description, &m.Stars,
			&m.Forks, &m.Language, &m.License, &m.DefaultBranch, &topicsJSON, &m.Category); err != nil {
			continue
		}
		_ = json.Unmarshal([]byte(topicsJSON), &m.Topics)
		out = append(out, m)
	}
	return out
}

func (s *Service) upsertMany(repos []models.MarketplaceRepo) {
	tx, err := s.db.Begin()
	if err != nil {
		return
	}
	defer tx.Commit()
	now := time.Now().UTC().Format(time.RFC3339)
	for _, r := range repos {
		topicsJSON, _ := json.Marshal(r.Topics)
		_, _ = tx.Exec(`INSERT OR REPLACE INTO marketplace_repos
			(full_name, owner, name, description, stars, forks, language, license, default_branch, topics, cached_at, category)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			r.FullName, r.Owner, r.Name, r.Description, r.Stars, r.Forks,
			r.Language, r.License, r.DefaultBranch, string(topicsJSON), now, r.Category)
	}
}
