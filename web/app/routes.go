package app

import (
	"aqclf.xyz/tago"
	"aqclf.xyz/lacitra/web/pages"
)

func routes(app *tago.App) *tago.App {
	app.GET("/", pages.Index())
	return app
}
