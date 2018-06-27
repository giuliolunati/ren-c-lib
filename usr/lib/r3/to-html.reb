Rebol [
	Name: to-html
	Type: module
	Title: "HTML Codec"

	Author: ["Giulio Lunati"]
]

text-mod: import 'text
quote-string: :text-mod/quote-string
unquote-string: :text-mod/unquote-string

is-empty?: function [t [any-string!]] [
	any [ find [
		"area" "base" "br" "col" "embed" "hr" "img" "input"
		"keygen" "link" "meta" "param" "source" "track" "wbr"
	] t | find "!?" t/1 ]
]

mold-style: function [
		x [map! block! text!]
	][
	if map? x [x: to-block x]
	if block? x [
		x: delimit map-each [k v] x [
			unspaced [k ":" space v]
		] "; "
	]
	x
]

to-html: function [
		x [block!]
		/into ret
	][
	if not x [return x]
	ret: default [make text! 256]
	case [
		'comment = x/type [
			append ret "<!--"
			append ret x/value
			append ret "-->"
		]
		'document = x/type [
			append ret "<html>"
			to-html/into x/head ret
			to-html/into x/body ret
			append ret "</html>"
		]
		find [element _ ] x/type [
			if x/type [
				append ret "<"
				append ret name: to-text x/name
				empty: x/empty
				if attrib: x/value [
					assert [map? attrib]
					for-each k attrib [
						value: attrib/:k
						if text? value [value: copy value]
						if k = "style" [value: mold-style value]
						if not text? value [value: form value] 
						append ret unspaced [
							" " k "=" quote-string value
						]
					]
				]
				if empty [append ret "/"]
				append ret ">"
			]
			y: select x 'first
			while [y] [
				to-html/into y ret
				y: select y 'next
			]
			if all [x/type not empty] [
				append ret to-tag unspaced ["/" name]
			]
		]
		'text = x/type [append ret x/value]
	] else [
		print ["!! unhandled type:" x/type]
	]
	ret
]

; vim: set sw=2 ts=2 sts=2:
