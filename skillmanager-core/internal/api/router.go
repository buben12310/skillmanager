package api

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"skillmanager-core/internal/agent"
	"skillmanager-core/internal/marketplace"
)

type Handler struct {
	agent   agent.Service
	skill   agent.SkillService
	mcp     agent.McpService
	market  *marketplace.Service
}

func NewHandler(agentSvc *agent.Service, skillSvc *agent.SkillService, mcpSvc *agent.McpService, marketSvc *marketplace.Service) *Handler {
	return &Handler{agent: *agentSvc, skill: *skillSvc, mcp: *mcpSvc, market: marketSvc}
}

func (h *Handler) Router() http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RealIP)

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]string{"status": "ok"})
	})
	r.Get("/shutdown", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]string{"status": "shutting down"})
	})

	r.Route("/agents", func(r chi.Router) {
		r.Get("/", h.ListAgents)
		r.Post("/", h.CreateAgent)
		r.Get("/templates", h.AgentTemplates)
		r.Get("/scan", h.ScanAgents)
		r.Get("/{id}", h.GetAgent)
		r.Delete("/{id}", h.DeleteAgent)

		// Skills
		r.Get("/{id}/skills", h.ListSkills)
		r.Post("/{id}/skills", h.CreateSkill)
		r.Get("/{id}/skills/{skillId}", h.GetSkill)
		r.Patch("/{id}/skills/{skillId}/toggle", h.ToggleSkill)
		r.Delete("/{id}/skills/{skillId}", h.DeleteSkill)
		r.Post("/{id}/skills/{skillId}/export", h.ExportSkill)

		// MCPs
		r.Get("/{id}/mcps", h.ListMcps)
		r.Post("/{id}/mcps", h.CreateMcp)
		r.Get("/{id}/mcps/{mcpId}", h.GetMcp)
		r.Delete("/{id}/mcps/{mcpId}", h.DeleteMcp)
		r.Post("/{id}/mcps/{mcpId}/test", h.TestMcp)
	})

	// Marketplace
	r.Route("/marketplace", func(r chi.Router) {
		r.Get("/repos", h.ListMarketRepos)
		r.Get("/repos/{owner}/{name}", h.GetMarketRepo)
		r.Get("/repos/{owner}/{name}/readme", h.GetMarketReadme)
		r.Get("/search", h.SearchMarketRepos)
		r.Post("/install", h.InstallMarketRepo)
	})

	return r
}
