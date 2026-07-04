package agent

import (
	"database/sql"
	"time"

	"skillmanager-core/internal/storage"
	"skillmanager-core/pkg/models"
)

type McpRepository struct{ db *sql.DB }

func NewMcpRepository(db *sql.DB) *McpRepository { return &McpRepository{db: db} }

func (r *McpRepository) ListByAgent(agentID string) ([]models.MCP, error) {
	rows, err := r.db.Query(`SELECT id, agent_id, name, command, args, path, connected, tools, last_tested_at FROM mcps WHERE agent_id=? ORDER BY name`, agentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []models.MCP{}
	for rows.Next() {
		var m models.MCP
		var args, tools, lastTested sql.NullString
		var connectedInt int
		if err := rows.Scan(&m.ID, &m.AgentID, &m.Name, &m.Command, &args, &m.Path, &connectedInt, &tools, &lastTested); err != nil {
			return nil, err
		}
		m.Args = parseDeps(args.String)
		m.Tools = parseDeps(tools.String)
		m.Connected = connectedInt == 1
		if lastTested.String != "" {
			t, _ := time.Parse(time.RFC3339, lastTested.String)
			m.LastTestedAt = &t
		}
		out = append(out, m)
	}
	return out, nil
}

func (r *McpRepository) Get(agentID, mcpID string) (*models.MCP, error) {
	var m models.MCP
	var args, tools, lastTested sql.NullString
	var connectedInt int
	err := r.db.QueryRow(`SELECT id, agent_id, name, command, args, path, connected, tools, last_tested_at FROM mcps WHERE agent_id=? AND id=?`, agentID, mcpID).
		Scan(&m.ID, &m.AgentID, &m.Name, &m.Command, &args, &m.Path, &connectedInt, &tools, &lastTested)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	m.Args = parseDeps(args.String)
	m.Tools = parseDeps(tools.String)
	m.Connected = connectedInt == 1
	if lastTested.String != "" {
		t, _ := time.Parse(time.RFC3339, lastTested.String)
		m.LastTestedAt = &t
	}
	return &m, nil
}

func (r *McpRepository) Create(m *models.MCP) error {
	m.ID = storage.NewID()
	args := mustJSON(m.Args)
	tools := mustJSON(m.Tools)
	if m.Args == nil {
		m.Args = []string{}
	}
	if m.Tools == nil {
		m.Tools = []string{}
	}
	_, err := r.db.Exec(`INSERT INTO mcps (id, agent_id, name, command, args, path, connected, tools, last_tested_at) VALUES (?,?,?,?,?,?,?,?,NULL)`,
		m.ID, m.AgentID, m.Name, m.Command, args, m.Path, boolToInt(m.Connected), tools)
	return err
}

func (r *McpRepository) Delete(agentID, mcpID string) error {
	_, err := r.db.Exec(`DELETE FROM mcps WHERE agent_id=? AND id=?`, agentID, mcpID)
	return err
}

func (r *McpRepository) SetConnection(agentID, mcpID string, connected bool, tools []string) error {
	now := time.Now().UTC().Format(time.RFC3339)
	toolsJSON := mustJSON(tools)
	_, err := r.db.Exec(`UPDATE mcps SET connected=?, tools=?, last_tested_at=? WHERE agent_id=? AND id=?`,
		boolToInt(connected), toolsJSON, now, agentID, mcpID)
	return err
}
