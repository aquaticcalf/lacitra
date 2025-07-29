package pages

import (
	"aqclf.xyz/lacitra/web/components"
	"aqclf.xyz/lacitra/web/layouts"
	"aqclf.xyz/tago"
)

func Index() *tago.Element {
	return layouts.DaisyPage(
		"lacitra",
		tago.Div(
			tago.Class("flex flex-col min-h-[100dvh] items-center justify-center"),
			components.Button(tago.Fragment(tago.Text("lacitra"))),
		),
	)
}
