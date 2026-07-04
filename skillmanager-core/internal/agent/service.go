package agent

import (
	"database/sql"
	"encoding/json"

	"skillmanager-core/pkg/errors"
	"skillmanager-core/pkg/models"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service { return &Service{repo: repo} }

func (s *Service) List() ([]models.Agent, error) {
	return s.repo.List()
}

func (s *Service) Get(id string) (*models.Agent, error) {
	a, err := s.repo.Get(id)
	if err != nil {
		return nil, errors.Internal(err)
	}
	if a == nil {
		return nil, errors.NotFound("agent %s not found", id)
	}
	return a, nil
}

func (s *Service) Create(req models.CreateAgentRequest) (*models.Agent, error) {
	if req.Name == "" {
		return nil, errors.BadRequest("name is required")
	}
	if req.IconColor == "" {
		req.IconColor = "#534AB7"
	}
	return s.repo.Create(req)
}

func (s *Service) Delete(id string) error {
	if id == "" {
		return errors.BadRequest("id is required")
	}
	return s.repo.Delete(id)
}

func (s *Service) Scan() ([]models.DiscoveredAgent, error) {
	return s.repo.Scan()
}

func (s *Service) Templates() []models.CreateAgentRequest {
	return Templates()
}

// 兼容 json 导入,用于扩展
func (s *Service) Marshal(v any) ([]byte, error) { return json.Marshal(v) }

var _ = sql.ErrNoRows
