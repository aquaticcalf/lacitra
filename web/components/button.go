package components

import "aqclf.xyz/tago"

func Button(children *tago.Element) *tago.Element {
	return tago.Button(
		tago.Class("btn"),
		children,
	)
}
