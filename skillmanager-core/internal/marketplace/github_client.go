package marketplace

import (
	"context"
	"net/http"
	"os"
	"time"

	"github.com/google/go-github/v62/github"

	"skillmanager-core/pkg/models"
)

// GitHubClient 封装 go-github 调用,无 token 时匿名 (限速 60/h)
type GitHubClient struct {
	client *github.Client
}

func NewGitHubClient() *GitHubClient {
	token := os.Getenv("GITHUB_TOKEN")
	var c *github.Client
	if token != "" {
		hc := &http.Client{
			Transport: &tokenTransport{token: token},
			Timeout:   15 * time.Second,
		}
		c = github.NewClient(hc)
	} else {
		c = github.NewClient(&http.Client{Timeout: 15 * time.Second})
	}
	return &GitHubClient{client: c}
}

type tokenTransport struct {
	token string
}

func (t *tokenTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req = req.Clone(req.Context())
	req.Header.Set("Authorization", "Bearer "+t.token)
	return http.DefaultTransport.RoundTrip(req)
}

// Search 搜索 topic=agent-skills / agent-skills 的仓库
func (g *GitHubClient) Search(ctx context.Context, query string) ([]models.MarketplaceRepo, error) {
	q := "topic:agent-skill"
	if query != "" {
		q = query + " topic:agent-skill"
	}
	opts := &github.SearchOptions{Sort: "stars", Order: "desc", ListOptions: github.ListOptions{PerPage: 30}}
	res, _, err := g.client.Search.Repositories(ctx, q, opts)
	if err != nil {
		return nil, err
	}
	out := make([]models.MarketplaceRepo, 0, len(res.Repositories))
	for _, r := range res.Repositories {
		out = append(out, toModel(r))
	}
	return out, nil
}

// Get 获取单个仓库元数据
func (g *GitHubClient) Get(ctx context.Context, owner, name string) (*models.MarketplaceRepo, error) {
	r, _, err := g.client.Repositories.Get(ctx, owner, name)
	if err != nil {
		return nil, err
	}
	m := toModel(r)
	return &m, nil
}

// README 拉取 README.md 内容
func (g *GitHubClient) README(ctx context.Context, owner, name string) (string, error) {
	rc, _, _, err := g.client.Repositories.GetContents(ctx, owner, name, "README.md", nil)
	if err != nil {
		// 退而求其次: 用 README (无后缀)
		rc, _, _, err = g.client.Repositories.GetContents(ctx, owner, name, "README", nil)
		if err != nil {
			return "", err
		}
	}
	if rc == nil || rc.Content == nil {
		return "", nil
	}
	return rc.GetContent()
}

// ListByTopic 多 topic 聚合搜索,合并去重
func (g *GitHubClient) ListByTopic(ctx context.Context) ([]models.MarketplaceRepo, error) {
	topics := []string{"agent-skill", "claude-skills", "agent-skills", "ai-agent-skill"}
	seen := map[string]bool{}
	out := []models.MarketplaceRepo{}
	for _, t := range topics {
		opts := &github.SearchOptions{Sort: "stars", Order: "desc", ListOptions: github.ListOptions{PerPage: 30}}
		res, _, err := g.client.Search.Repositories(ctx, "topic:"+t, opts)
		if err != nil {
			continue
		}
		for _, r := range res.Repositories {
			fn := r.GetFullName()
			if seen[fn] {
				continue
			}
			seen[fn] = true
			out = append(out, toModel(r))
		}
	}
	return out, nil
}

func toModel(r *github.Repository) models.MarketplaceRepo {
	m := models.MarketplaceRepo{
		FullName:      r.GetFullName(),
		Owner:         r.GetOwner().GetLogin(),
		Name:          r.GetName(),
		Description:   r.GetDescription(),
		Stars:         r.GetStargazersCount(),
		Forks:         r.GetForksCount(),
		Language:      r.GetLanguage(),
		DefaultBranch: r.GetDefaultBranch(),
		Topics:        r.Topics,
	}
	if r.License != nil {
		m.License = r.License.GetSPDXID()
	}
	return m
}

// 上下文超时帮助
func ctxTimeout(d time.Duration) (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), d)
}

var _ = ctxTimeout
