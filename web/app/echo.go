package app

import (
	"aqclf.xyz/tago"
    "log"
)

func Run() {
	app := tago.NewApp()
	err := routes(app).Run(":8080")
	if err != nil {
		log.Fatal(err)
	}
}