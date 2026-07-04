package storage

import (
	"database/sql"
	_ "embed"

	_ "modernc.org/sqlite" // pure-Go SQLite driver

	"github.com/google/uuid"

	"skillmanager-core/internal/config"
)

//go:embed migrations/001_init.sql
var migrationSQL string

func Open() (*sql.DB, error) {
	path, err := config.DBPath()
	if err != nil {
		return nil, err
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	if _, err := db.Exec("PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON; PRAGMA synchronous = NORMAL;"); err != nil {
		return nil, err
	}
	if _, err := db.Exec(migrationSQL); err != nil {
		return nil, err
	}
	return db, nil
}

// NewID 生成 UUID
func NewID() string { return uuid.NewString() }

// TxHelper 简化事务
func TxHelper(db *sql.DB, fn func(*sql.Tx) error) (err error) {
	tx, e := db.Begin()
	if e != nil {
		return e
	}
	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback()
			panic(p)
		}
		if err != nil {
			_ = tx.Rollback()
		} else {
			err = tx.Commit()
		}
	}()
	return fn(tx)
}
