package config

import (
	"os"
	"path/filepath"
)

// DataDir 跨平台数据目录
func DataDir() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", err
	}
	p := filepath.Join(dir, "skillmanager")
	return p, os.MkdirAll(p, 0o755)
}

func DBPath() (string, error) {
	dir, err := DataDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "skillmanager.db"), nil
}

func LogDir() (string, error) {
	dir, err := DataDir()
	if err != nil {
		return "", err
	}
	p := filepath.Join(dir, "logs")
	return p, os.MkdirAll(p, 0o755)
}
