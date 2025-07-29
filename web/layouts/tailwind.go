package layouts

import (
	. "aqclf.xyz/tago"
)

func TailwindPage(title string, children *Element) *Element {
	return Html(
		Head(
			Tailwind(),
			Title(title),
			Link(
				Attr("rel", "shortcut icon"),
				Attr("href", "https://aqclf.xyz/favicon.png"),
				Attr("type", "image/png"),
			),
			Meta(
				Attr("name", "viewport"),
				Attr("content", "width=device-width, initial-scale=1.0"),
			),
		),
		Body(
			children,
		),
	)
}
