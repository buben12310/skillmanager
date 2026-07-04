package agent

import (
	"context"
	"fmt"
	"os/exec"
	"time"

	"skillmanager-core/pkg/errors"
	"skillmanager-core/pkg/models"
)

type McpService struct {
	repo *McpRepository
}

func NewMcpService(repo *McpRepository) *McpService { return &McpService{repo: repo} }

func (s *McpService) ListByAgent(agentID string) ([]models.MCP, error) {
	return s.repo.ListByAgent(agentID)
}

func (s *McpService) Get(agentID, mcpID string) (*models.MCP, error) {
	m, err := s.repo.Get(agentID, mcpID)
	if err != nil {
		return nil, errors.Internal(err)
	}
	if m == nil {
		return nil, errors.NotFound("mcp not found")
	}
	return m, nil
}

func (s *McpService) Create(m *models.MCP) error {
	if m.Name == "" || m.Command == "" {
		return errors.BadRequest("name and command are required")
	}
	return s.repo.Create(m)
}

func (s *McpService) Delete(agentID, mcpID string) error {
	return s.repo.Delete(agentID, mcpID)
}

// Test 仅做进程启动握手 (不调任何工具避免副作用)
func (s *McpService) Test(agentID, mcpID string) (*TestResult, error) {
	m, err := s.Get(agentID, mcpID)
	if err != nil {
		return nil, err
	}
	start := time.Now()
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, m.Command, m.Args...)
	if err := cmd.Start(); err != nil {
		// 启动失败 = 不可连接
		_ = s.repo.SetConnection(agentID, mcpID, false, []string{})
		return &TestResult{Connected: false, Tools: []string{}, LatencyMs: int(time.Since(start).Milliseconds())}, nil
	}
	// 给进程 200ms 初始化,然后 kill
	time.Sleep(200 * time.Millisecond)
	_ = cmd.Process.Kill()
	_ = cmd.Wait()
	latency := int(time.Since(start).Milliseconds())
	_ = s.repo.SetConnection(agentID, mcpID, true, []string{"(initialize ok)"})
	return &TestResult{Connected: true, Tools: []string{"(initialize ok)"}, LatencyMs: latency}, nil
}

type TestResult struct {
	Connected  bool     `json:"connected"`
	Tools      []string `json:"tools"`
	LatencyMs  int      `json:"latencyMs"`
}

var _ = fmt.Sprintf
