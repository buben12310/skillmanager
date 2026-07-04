package api

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	apperr "skillmanager-core/pkg/errors"
	"skillmanager-core/pkg/models"
)

// Agent handlers
func (h *Handler) ListAgents(w http.ResponseWriter, r *http.Request) {
	agents, err := h.agent.List()
	if err != nil {
		writeError(w, apperr.Internal(err))
		return
	}
	writeJSON(w, 200, agents)
}

func (h *Handler) GetAgent(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	a, err := h.agent.Get(id)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, a)
}

func (h *Handler) CreateAgent(w http.ResponseWriter, r *http.Request) {
	var req models.CreateAgentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, apperr.BadRequest("invalid request body"))
		return
	}
	a, err := h.agent.Create(req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 201, a)
}

func (h *Handler) DeleteAgent(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.agent.Delete(id); err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, map[string]string{"status": "ok"})
}

func (h *Handler) ScanAgents(w http.ResponseWriter, r *http.Request) {
	result, err := h.agent.Scan()
	if err != nil {
		writeError(w, apperr.Wrap(err, apperr.CodeScanFailed, "扫描失败"))
		return
	}
	writeJSON(w, 200, map[string]any{"discovered": result})
}

func (h *Handler) AgentTemplates(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.agent.Templates())
}

// 写入工具
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, err error) {
	ae, ok := err.(*apperr.AppError)
	if !ok {
		ae = apperr.Internal(err)
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(apperr.HTTPStatus(ae.Code))
	_ = json.NewEncoder(w).Encode(ae.JSON())
}
