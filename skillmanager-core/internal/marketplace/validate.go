package marketplace

import (
	"errors"
	"regexp"
	"strings"

	"gopkg.in/yaml.v3"
)

// FrontMatter SKILL.md 头部元数据
type FrontMatter struct {
	Name        string   `yaml:"name"`
	Description string   `yaml:"description"`
	Version     string   `yaml:"version"`
	Author      string   `yaml:"author"`
	Triggers    []string `yaml:"triggers,omitempty"`
	Category    string   `yaml:"category,omitempty"`
	Tags        []string `yaml:"tags,omitempty"`
	License     string   `yaml:"license,omitempty"`
}

type ValidResult struct {
	Valid  bool
	Meta   *FrontMatter
	Errors []string
	Score  int
}

var (
	semverRe = regexp.MustCompile(`^\d+\.\d+\.\d+$`)
	slugRe   = regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)
)

var blacklist = []string{
	"<script", "eval(", "exec(", "system(", "rm -rf",
	"backdoor", "trojan", "keylogger", "crypto miner",
}

// ValidateSkillMD 校验 SKILL.md 内容 (安全+元数据)
func ValidateSkillMD(content string) *ValidResult {
	r := &ValidResult{Valid: true, Score: 100}

	lower := strings.ToLower(content)
	for _, kw := range blacklist {
		if strings.Contains(lower, kw) {
			r.Valid = false
			r.Errors = append(r.Errors, "检测到危险代码: "+kw)
			return r
		}
	}

	if len(content) > 100*1024 {
		r.Valid = false
		r.Errors = append(r.Errors, "SKILL.md 超过 100KB")
		return r
	}

	fm, err := extractFrontMatter(content)
	if err != nil {
		r.Valid = false
		r.Errors = append(r.Errors, "frontmatter 解析失败: "+err.Error())
		return r
	}
	r.Meta = fm

	if fm.Name == "" {
		r.Errors = append(r.Errors, "name 不能为空")
		r.Valid = false
	} else if !slugRe.MatchString(fm.Name) {
		r.Errors = append(r.Errors, "name 格式非法")
		r.Valid = false
	}
	if len(fm.Description) < 20 {
		r.Errors = append(r.Errors, "description 至少 20 字符")
		r.Valid = false
	}
	if !semverRe.MatchString(fm.Version) {
		r.Errors = append(r.Errors, "version 需符合 semver")
		r.Valid = false
	}
	if fm.Author == "" {
		r.Errors = append(r.Errors, "author 不能为空")
		r.Valid = false
	}

	// 质量评分
	if len(fm.Description) < 50 {
		r.Score -= 5
	}
	if len(fm.Triggers) == 0 {
		r.Score -= 10
	}
	if fm.Category == "" {
		r.Score -= 5
	}
	if len(fm.Tags) < 2 {
		r.Score -= 5
	}
	if fm.License == "" {
		r.Score -= 5
	}
	return r
}

func extractFrontMatter(content string) (*FrontMatter, error) {
	if !strings.HasPrefix(content, "---\n") {
		return nil, errors.New("missing frontmatter")
	}
	rest := content[4:]
	end := strings.Index(rest, "\n---")
	if end == -1 {
		return nil, errors.New("unclosed frontmatter")
	}
	fm := &FrontMatter{}
	if err := yaml.Unmarshal([]byte(rest[:end]), fm); err != nil {
		return nil, err
	}
	return fm, nil
}
