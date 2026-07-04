package api

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"skillmanager-core/pkg/errors"
	"skillmanager-core/pkg/models"
)

func (h *Handler) ListSkills(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	skills, err := h.skill.ListByAgent(agentID)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, skills)
}

func (h *Handler) GetSkill(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	skillID := chi.URLParam(r, "skillId")
	sk, err := h.skill.Get(agentID, skillID)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, sk)
}

func (h *Handler) CreateSkill(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	var sk models.Skill
	if err := json.NewDecoder(r.Body).Decode(&sk); err != nil {
		writeError(w, errors.BadRequest("invalid request body"))
		return
	}
	sk.AgentID = agentID
	if err := h.skill.Create(&sk); err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 201, sk)
}

func (h *Handler) ToggleSkill(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	skillID := chi.URLParam(r, "skillId")
	enabled, err := h.skill.Toggle(agentID, skillID)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, map[string]bool{"enabled": enabled})
}

func (h *Handler) DeleteSkill(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	skillID := chi.URLParam(r, "skillId")
	if err := h.skill.Delete(agentID, skillID); err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, map[string]string{"status": "ok"})
}

// ExportSkill 将 skill 从当前 Agent 导出到目标 Agent (含文件拷贝)
func (h *Handler) ExportSkill(w http.ResponseWriter, r *http.Request) {
	sourceAgentID := chi.URLParam(r, "id")
	skillID := chi.URLParam(r, "skillId")
	var body struct {
		TargetAgentID string `json:"targetAgentId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, errors.BadRequest("invalid request body"))
		return
	}
	sk, err := h.skill.ExportToAgent(sourceAgentID, skillID, body.TargetAgentID)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 201, sk)
}

func (h *Handler) ListMcps(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	mcps, err := h.mcp.ListByAgent(agentID)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, mcps)
}

func (h *Handler) GetMcp(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	mcpID := chi.URLParam(r, "mcpId")
	m, err := h.mcp.Get(agentID, mcpID)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, m)
}

func (h *Handler) CreateMcp(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	var m models.MCP
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		writeError(w, errors.BadRequest("invalid request body"))
		return
	}
	m.AgentID = agentID
	if err := h.mcp.Create(&m); err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 201, m)
}

func (h *Handler) DeleteMcp(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	mcpID := chi.URLParam(r, "mcpId")
	if err := h.mcp.Delete(agentID, mcpID); err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, map[string]string{"status": "ok"})
}

func (h *Handler) TestMcp(w http.ResponseWriter, r *http.Request) {
	agentID := chi.URLParam(r, "id")
	mcpID := chi.URLParam(r, "mcpId")
	result, err := h.mcp.Test(agentID, mcpID)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, result)
}
