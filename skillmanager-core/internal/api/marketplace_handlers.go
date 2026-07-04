package api

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"

	"skillmanager-core/pkg/errors"
	"skillmanager-core/pkg/models"
)

func (h *Handler) ListMarketRepos(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")
	if category == "" {
		category = "全部"
	}
	res, err := h.market.List(r.Context(), category)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, res)
}

func (h *Handler) GetMarketRepo(w http.ResponseWriter, r *http.Request) {
	owner := chi.URLParam(r, "owner")
	name := chi.URLParam(r, "name")
	res, err := h.market.Get(r.Context(), owner, name)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, res)
}

func (h *Handler) GetMarketReadme(w http.ResponseWriter, r *http.Request) {
	owner := chi.URLParam(r, "owner")
	name := chi.URLParam(r, "name")
	md, err := h.market.README(r.Context(), owner, name)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, map[string]string{"readme": md})
}

func (h *Handler) SearchMarketRepos(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	if q == "" {
		writeError(w, errors.BadRequest("missing q parameter"))
		return
	}
	res, err := h.market.Search(r.Context(), q)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, 200, res)
}

func (h *Handler) InstallMarketRepo(w http.ResponseWriter, r *http.Request) {
	var req models.InstallRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, errors.BadRequest("invalid body"))
		return
	}
	sk, err := h.market.Install(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	// 落库为 skill
	_ = h.skill.Create(sk)
	writeJSON(w, 201, sk)
}

var _ = strconv.Atoi
