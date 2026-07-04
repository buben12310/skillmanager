CREATE TABLE IF NOT EXISTS agents (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    icon        TEXT NOT NULL,
    icon_color  TEXT NOT NULL,
    skill_path  TEXT NOT NULL,
    mcp_path    TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'active',
    format      TEXT NOT NULL,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS skills (
    id            TEXT PRIMARY KEY,
    agent_id      TEXT NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    name          TEXT NOT NULL,
    version       TEXT,
    author        TEXT,
    source        TEXT NOT NULL,
    source_url    TEXT,
    path          TEXT NOT NULL,
    enabled       INTEGER NOT NULL DEFAULT 1,
    format        TEXT NOT NULL,
    dependencies  TEXT,
    installed_at  TEXT NOT NULL,
    UNIQUE(agent_id, name)
);

CREATE TABLE IF NOT EXISTS mcps (
    id              TEXT PRIMARY KEY,
    agent_id        TEXT NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    command         TEXT NOT NULL,
    args            TEXT NOT NULL,
    path            TEXT NOT NULL,
    connected       INTEGER NOT NULL DEFAULT 0,
    tools           TEXT,
    last_tested_at  TEXT,
    UNIQUE(agent_id, name)
);

CREATE TABLE IF NOT EXISTS settings (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_skills_agent   ON skills(agent_id);
CREATE INDEX IF NOT EXISTS idx_mcps_agent     ON mcps(agent_id);
CREATE INDEX IF NOT EXISTS idx_skills_enabled ON skills(enabled);

-- Phase 3: GitHub 市场缓存
CREATE TABLE IF NOT EXISTS marketplace_repos (
    full_name       TEXT PRIMARY KEY,   -- "owner/repo"
    owner           TEXT NOT NULL,
    name            TEXT NOT NULL,
    description     TEXT DEFAULT '',
    stars           INTEGER DEFAULT 0,
    forks           INTEGER DEFAULT 0,
    language        TEXT DEFAULT '',
    license         TEXT DEFAULT '',
    default_branch  TEXT DEFAULT 'main',
    topics          TEXT DEFAULT '[]',
    cached_at       TEXT NOT NULL,
    category        TEXT DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_market_stars ON marketplace_repos(stars DESC);
CREATE INDEX IF NOT EXISTS idx_market_cat   ON marketplace_repos(category);

