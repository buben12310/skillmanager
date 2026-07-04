package agent

import (
	"database/sql"
	"encoding/json"
	"time"

	"skillmanager-core/internal/storage"
	"skillmanager-core/pkg/models"
)

// SkillRepository
type SkillRepository struct{ db *sql.DB }

func NewSkillRepository(db *sql.DB) *SkillRepository { return &SkillRepository{db: db} }

func (r *SkillRepository) ListByAgent(agentID string) ([]models.Skill, error) {
	rows, err := r.db.Query(`SELECT id, agent_id, name, version, author, source, source_url, path, enabled, format, dependencies, installed_at FROM skills WHERE agent_id=? ORDER BY installed_at DESC`, agentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []models.Skill{}
	for rows.Next() {
		var s models.Skill
		var version, author, sourceURL, deps, installedAt sql.NullString
		var enabledInt int
		if err := rows.Scan(&s.ID, &s.AgentID, &s.Name, &version, &author, &s.Source, &sourceURL, &s.Path, &enabledInt, &s.Format, &deps, &installedAt); err != nil {
			return nil, err
		}
		s.Version = version.String
		s.Author = author.String
		s.SourceURL = sourceURL.String
		s.Enabled = enabledInt == 1
		s.Dependencies = parseDeps(deps.String)
		s.InstalledAt, _ = time.Parse(time.RFC3339, installedAt.String)
		out = append(out, s)
	}
	return out, nil
}

func (r *SkillRepository) Get(agentID, skillID string) (*models.Skill, error) {
	var s models.Skill
	var version, author, sourceURL, deps, installedAt sql.NullString
	var enabledInt int
	err := r.db.QueryRow(`SELECT id, agent_id, name, version, author, source, source_url, path, enabled, format, dependencies, installed_at FROM skills WHERE agent_id=? AND id=?`, agentID, skillID).
		Scan(&s.ID, &s.AgentID, &s.Name, &version, &author, &s.Source, &sourceURL, &s.Path, &enabledInt, &s.Format, &deps, &installedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	s.Version = version.String
	s.Author = author.String
	s.SourceURL = sourceURL.String
	s.Enabled = enabledInt == 1
	s.Dependencies = parseDeps(deps.String)
	s.InstalledAt, _ = time.Parse(time.RFC3339, installedAt.String)
	return &s, nil
}

func (r *SkillRepository) Create(s *models.Skill) error {
	now := time.Now().UTC().Format(time.RFC3339)
	s.ID = storage.NewID()
	s.InstalledAt = time.Now().UTC()
	deps := mustJSON(s.Dependencies)
	_, err := r.db.Exec(`INSERT INTO skills (id, agent_id, name, version, author, source, source_url, path, enabled, format, dependencies, installed_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`,
		s.ID, s.AgentID, s.Name, s.Version, s.Author, s.Source, s.SourceURL, s.Path, boolToInt(s.Enabled), s.Format, deps, now)
	return err
}

func (r *SkillRepository) Update(s *models.Skill) error {
	deps := mustJSON(s.Dependencies)
	_, err := r.db.Exec(`UPDATE skills SET version=?, author=?, source=?, source_url=?, path=?, enabled=?, format=?, dependencies=? WHERE id=?`,
		s.Version, s.Author, s.Source, s.SourceURL, s.Path, boolToInt(s.Enabled), s.Format, deps, s.ID)
	return err
}

func (r *SkillRepository) Toggle(agentID, skillID string) (bool, error) {
	res, err := r.db.Exec(`UPDATE skills SET enabled = 1 - enabled WHERE agent_id=? AND id=?`, agentID, skillID)
	if err != nil {
		return false, err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return false, nil
	}
	var enabledInt int
	err = r.db.QueryRow(`SELECT enabled FROM skills WHERE agent_id=? AND id=?`, agentID, skillID).Scan(&enabledInt)
	return enabledInt == 1, err
}

func (r *SkillRepository) Delete(agentID, skillID string) error {
	_, err := r.db.Exec(`DELETE FROM skills WHERE agent_id=? AND id=?`, agentID, skillID)
	return err
}

func parseDeps(s string) []string {
	if s == "" || s == "null" {
		return []string{}
	}
	var deps []string
	if err := json.Unmarshal([]byte(s), &deps); err != nil {
		return []string{}
	}
	if deps == nil {
		return []string{}
	}
	return deps
}

func mustJSON(v []string) string {
	if v == nil {
		v = []string{}
	}
	b, _ := json.Marshal(v)
	return string(b)
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}
