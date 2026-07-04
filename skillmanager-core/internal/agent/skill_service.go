package agent

import (
	"os"
	"path/filepath"
	"strings"

	"skillmanager-core/pkg/errors"
	"skillmanager-core/pkg/models"
)

type SkillService struct {
	repo      *SkillRepository
	agentRepo *Repository
}

func NewSkillService(repo *SkillRepository, agentRepo *Repository) *SkillService {
	return &SkillService{repo: repo, agentRepo: agentRepo}
}

func (s *SkillService) ListByAgent(agentID string) ([]models.Skill, error) {
	if agentID == "" {
		return nil, errors.BadRequest("agentId is required")
	}
	return s.repo.ListByAgent(agentID)
}

func (s *SkillService) Get(agentID, skillID string) (*models.Skill, error) {
	sk, err := s.repo.Get(agentID, skillID)
	if err != nil {
		return nil, errors.Internal(err)
	}
	if sk == nil {
		return nil, errors.NotFound("skill not found")
	}
	return sk, nil
}

func (s *SkillService) Create(sk *models.Skill) error {
	if sk.Name == "" {
		return errors.BadRequest("name is required")
	}
	if sk.Format == "" {
		sk.Format = "claude-code"
	}
	if sk.Source == "" {
		sk.Source = "local"
	}
	return s.repo.Create(sk)
}

func (s *SkillService) Toggle(agentID, skillID string) (bool, error) {
	enabled, err := s.repo.Toggle(agentID, skillID)
	if err != nil {
		return false, errors.Internal(err)
	}
	return enabled, nil
}

func (s *SkillService) Delete(agentID, skillID string) error {
	return s.repo.Delete(agentID, skillID)
}

// Compatibility 4x4 矩阵
func (s *SkillService) Compatible(skillFormat, agentFormat string) bool {
	if skillFormat == "" || agentFormat == "" {
		return true
	}
	if skillFormat == agentFormat {
		return true
	}
	if skillFormat == "generic" || agentFormat == "generic" {
		return true
	}
	return false
}

// ExportToAgent 将一个 skill 从源 Agent 导出到目标 Agent。
// 真正拷贝 skill 文件夹到目标 Agent 的 skillPath 下,并在目标 Agent 注册新记录。
// - 源 skill 路径必须存在且为目录
// - 目标 Agent 必须有 skillPath 配置
// - 若目标位置已有同名 skill,先清理再拷贝
// - 新 skill 的 source 标记为 "import",format 跟随目标 Agent
func (s *SkillService) ExportToAgent(sourceAgentID, skillID, targetAgentID string) (*models.Skill, error) {
	if targetAgentID == "" {
		return nil, errors.BadRequest("targetAgentId is required")
	}
	if sourceAgentID == targetAgentID {
		return nil, errors.BadRequest("源 Agent 与目标 Agent 相同")
	}

	// 1. 查源 skill
	srcSkill, err := s.repo.Get(sourceAgentID, skillID)
	if err != nil {
		return nil, errors.Internal(err)
	}
	if srcSkill == nil {
		return nil, errors.NotFound("source skill not found")
	}

	// 2. 查目标 agent,获取 skillPath 与 format
	targetAgent, err := s.agentRepo.Get(targetAgentID)
	if err != nil {
		return nil, errors.Internal(err)
	}
	if targetAgent == nil {
		return nil, errors.NotFound("target agent not found")
	}
	if targetAgent.SkillPath == "" {
		return nil, errors.BadRequest("目标 Agent 未配置 skillPath")
	}

	// 3. 展开路径 (~ → home)
	home, _ := os.UserHomeDir()
	srcPath := expandHome(srcSkill.Path, home)
	dstSkillPath := expandHome(targetAgent.SkillPath, home)

	// 源路径必须存在且为目录
	if info, err := os.Stat(srcPath); err != nil || !info.IsDir() {
		return nil, errors.BadRequest("源 skill 路径不存在或不是目录: " + srcPath)
	}

	// 4. 目标目录: <target_skillPath>/<skill_name>/
	dstDir := filepath.Join(dstSkillPath, srcSkill.Name)

	// 若目标已存在,先清理 (覆盖语义)
	if info, err := os.Stat(dstDir); err == nil && info.IsDir() {
		if err := os.RemoveAll(dstDir); err != nil {
			return nil, errors.Internal(err)
		}
	}

	// 5. 递归拷贝 (跳过 .git)
	if err := copySkillDir(srcPath, dstDir); err != nil {
		return nil, errors.Internal(err)
	}

	// 6. 在目标 agent 下注册新 skill 记录, path 指向拷贝后的新位置
	dstPathSlash := filepath.ToSlash(dstDir)
	if !strings.HasSuffix(dstPathSlash, "/") {
		dstPathSlash += "/"
	}
	newSkill := &models.Skill{
		AgentID:      targetAgentID,
		Name:         srcSkill.Name,
		Version:      srcSkill.Version,
		Author:       srcSkill.Author,
		Source:       "import",
		SourceURL:    srcSkill.SourceURL,
		Path:         dstPathSlash,
		Enabled:      true,
		Format:       targetAgent.Format,
		Dependencies: srcSkill.Dependencies,
	}
	if err := s.repo.Create(newSkill); err != nil {
		return nil, errors.Internal(err)
	}
	return newSkill, nil
}

// copySkillDir 递归拷贝 skill 目录,跳过 .git 内容
func copySkillDir(src, dst string) error {
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
