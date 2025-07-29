package main

import (
	"aqclf.xyz/lacitra/internal/db"
	"aqclf.xyz/lacitra/web/app"
	"log"
)

func main() {
	_, err := db.InitDB("./storage/lacitra.db")
	if err != nil {
		log.Fatal(err)
	}

	app.Run()
}
