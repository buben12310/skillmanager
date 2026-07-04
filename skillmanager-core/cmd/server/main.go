package main

import (
	"context"
	"encoding/json"
	"flag"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"skillmanager-core/internal/agent"
	"skillmanager-core/internal/api"
	"skillmanager-core/internal/config"
	"skillmanager-core/internal/marketplace"
	"skillmanager-core/internal/storage"
)

const version = "1.0.0"

func main() {
	addr := flag.String("addr", "127.0.0.1:0", "listen address")
	flag.Parse()

	logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelInfo}))
	slog.SetDefault(logger)

	// SQLite
	db, err := storage.Open()
	if err != nil {
		slog.Error("open db failed", "err", err)
		os.Exit(1)
	}
	defer db.Close()
	if err := storage.SeedIfEmpty(db); err != nil {
		slog.Error("seed db failed", "err", err)
		os.Exit(1)
	}

	// DI
	agentRepo := agent.NewRepository(db)
	agentSvc := agent.NewService(agentRepo)
	skillRepo := agent.NewSkillRepository(db)
	skillSvc := agent.NewSkillService(skillRepo, agentRepo)
	mcpRepo := agent.NewMcpRepository(db)
	mcpSvc := agent.NewMcpService(mcpRepo)
	ghClient := marketplace.NewGitHubClient()
	marketSvc := marketplace.NewService(ghClient, db)
	handler := api.NewHandler(agentSvc, skillSvc, mcpSvc, marketSvc)
	router := handler.Router()

	// 监听
	ln, err := net.Listen("tcp", *addr)
	if err != nil {
		slog.Error("listen failed", "err", err)
		os.Exit(1)
	}
	port := ln.Addr().(*net.TCPAddr).Port

	srv := &http.Server{Handler: router}

	// 启动握手: 第一行 JSON 输出到 stdout,Flutter 解析用
	handshake := map[string]any{"port": port, "pid": os.Getpid(), "version": version}
	_ = json.NewEncoder(os.Stdout).Encode(handshake)
	slog.Info("skillmanager-core started", "port", port, "version", version, "dataDir", must(config.DataDir()))

	// 孤儿保护: 父进程退出则自杀
	go watchParent()

	// 优雅关闭
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go func() {
		if err := srv.Serve(ln); err != nil && err != http.ErrServerClosed {
			slog.Error("serve failed", "err", err)
			os.Exit(1)
		}
	}()
	<-ctx.Done()
	slog.Info("shutting down")
	shutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutCtx)
}

func watchParent() {
	ppid := os.Getppid()
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		if os.Getppid() != ppid {
			slog.Info("parent process exited, killing self")
			os.Exit(0)
		}
	}
}

func must(s string, err error) string {
	if err != nil {
		return "?"
	}
	return s
}
