package db

import (
    _ "embed"
    "database/sql"
    "path/filepath"
    "os"

    _ "github.com/mattn/go-sqlite3"
)

//go:embed migration/init.sql
var schema string

func InitDB(path string) (*sql.DB, error) {

    // create directory if it doesn't exist
    dir := filepath.Dir(path)
    if err := os.MkdirAll(dir, 0755); err != nil {
        return nil, err
    }

    // check if database file exists
    _, err := os.Stat(path)
    isNewDB := os.IsNotExist(err)

    // open file
    db, err := sql.Open("sqlite3", path)
    if err != nil {
        return nil, err
    }

    // test the connection
    if err := db.Ping(); err != nil {
        err = db.Close()
        return nil, err
    }

    // run schema migration only if the database is new
    if isNewDB {
        if _, err = db.Exec(schema); err != nil {
            err = db.Close()
            return nil, err
        }
    }

    return db, err
}
