Rebol [
	Name: html
	Type: module
	Title: "HTML Codec"

	Author: ["Christopher Ross-Gill" "Giulio Lunati"]
	Date: 23-Dec-2017
	File: %html.reb
	Version: 0.2.0
	Rights: http://opensource.org/licenses/Apache-2.0
	History: [
		23-Dec-2017 0.2.0 "rewrite based on rgchris' markup.reb"
	]
]

;;; IMPORT

text-mod: import 'text
smart-decode-text: :text-mod/smart-decode-text
unquote-string: :text-mod/unquote-string
quote-string: :text-mod/quote-string

trees: import 'doc-tree

markup: import 'markup
decode-markup: :markup/decode-markup

;;; UTILITIES

also: func [x [<opt> any-value!] y [<opt> any-value!]] [:x] 

put: func [map [map!] key value][
	if any-string? key [key: lock copy key]
	poke map key value
]

; https://github.com/metaeducation/ren-c/issues/322
maps-equal?: func [value1 [map! blank!] value2 [map! blank!]][
	if map? value1 [value1: sort/skip body-of value1 2]
	if map? value2 [value2: sort/skip body-of value2 2]
	equal? value1 value2
]

;;;

increment: func ['word [word!]][
	either number? get :word [
		also get word set word add get word 1
	][
		make error! "INCREMENT Expected number argument."
	]
]

references: make object! [ ; need to update references
	elements: make map! lock [
		"a" a "abbr" abbr "address" address "applet" applet "area" area "article" article
		"aside" aside "b" b "base" base "basefont" basefont "bgsound" bgsound
		"big" big "blockquote" blockquote "body" body "br" br "button" button
		"caption" caption "center" center "code" code "col" col "colgroup" colgroup
		"dd" dd "details" details "dialog" dialog "dir" dir "div" div
		"dl" dl "dt" dt "em" em "embed" embed "fieldset" fieldset
		"figcaption" figcaption "figure" figure "font" font "footer" footer "form" form
		"frame" frame "frameset" frameset "h1" h1 "h2" h2 "h3" h3
		"h4" h4 "h5" h5 "h6" h6 "head" head "header" header
		"hgroup" hgroup "hr" hr "html" html "i" i "iframe" iframe "image" image
		"img" img "input" input "isindex" isindex "keygen" keygen "label" label
		"li" li "link" link "listing" listing "main" main "marquee" marquee
		"math" math "meta" meta "nav" nav "nobr" nobr "noembed" noembed
		"noframes" noframes "noscript" noscript "object" object "ol" ol "optgroup" optgroup
		"option" option "p" p "param" param "plaintext" plaintext "pre" pre
		"rb" rb "rp" rp "rtc" rtc "ruby" ruby "s" s
		"script" script "section" section "select" select "small" small "source" source
		"span" span "strike" strike "strong" strong "style" style "sub" sub
		"summary" summary "sup" sup "svg" svg "table" table "tbody" tbody
		"td" td "template" template "textarea" textarea "tfoot" tfoot "th" th
		"thead" thead "time" time "title" title "tr" tr "track" track "tt" tt
		"u" u "ul" ul "var" var "wbr" wbr "xmp" xmp

		; SVG
		"altglyph" altGlyph "altglyphdef" altGlyphDef
		"altglyphitem" altGlyphItem "animatecolor" animateColor
		"animatemotion" animateMotion "animatetransform" animateTransform
		"clippath" clipPath "feblend" feBlend
		"fecolormatrix" feColorMatrix "fecomponenttransfer" feComponentTransfer
		"fecomposite" feComposite "feconvolvematrix" feConvolveMatrix
		"fediffuselighting" feDiffuseLighting "fedisplacementmap" feDisplacementMap
		"fedistantlight" feDistantLight "fedropshadow" feDropShadow
		"feflood" feFlood "fefunca" feFuncA
		"fefuncb" feFuncB "fefuncg" feFuncG
		"fefuncr" feFuncR "fegaussianblur" feGaussianBlur
		"feimage" feImage "femerge" feMerge
		"femergenode" feMergeNode "femorphology" feMorphology
		"feoffset" feOffset "fepointlight" fePointLight
		"fespecularlighting" feSpecularLighting "fespotlight" feSpotLight
		"fetile" feTile "feturbulence" feTurbulence
		"foreignobject" foreignObject "glyphref" glyphRef
		"lineargradient" linearGradient "radialgradient" radialGradient
		"textpath" textPath
	]

	tags: make map! 0
	end-tags: make map! 0
	element: _
	foreach element words-of elements [
		put tags elements/:element to tag! elements/:element
		put end-tags elements/:element rejoin [</> elements/:element]
	]
]

word-rule: [ ; reserved for future use
	w1: charset [
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
		#"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(02FF)"
		#"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)"
		#"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)"
		#"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
	]
	w+: charset [
		"-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
		#"^(B7)" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(037D)"
		#"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(203F)" - #"^(2040)"
		#"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)"
		#"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
	]
	word: [w1 any w+]
]

html-tokenizer: make object! [
	; 8.2.4 Tokenization https://www.w3.org/TR/html5/syntax.html#tokenization
	series: mark: buffer: attribute: token: last-token: character: closer: additional-character: _
	is-paused: is-done: false

	b: [#"b" | #"B"]
	c: [#"c" | #"C"]
	d: [#"d" | #"D"]
	e: [#"e" | #"E"]
	i: [#"i" | #"I"]
	l: [#"l" | #"L"]
	m: [#"m" | #"M"]
	o: [#"o" | #"O"]
	p: [#"p" | #"P"]
	s: [#"s" | #"S"]
	t: [#"t" | #"T"]
	u: [#"u" | #"U"]
	y: [#"y" | #"Y"]

	space: charset "^-^/^M "
	upper-alpha: charset "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	lower-alpha: charset "abcdefghijklmnopqrstuvwxyz"
	alpha: union upper-alpha lower-alpha
	digit: charset "0123456789"
	alphanum: union alpha digit
	hex-digit: charset "0123456789abcdefABCDEF"
	non-markup: complement charset "^@^-^/^M&< "
	non-rcdata: complement charset "^@&<"
	non-script: complement charset "^@<"
	not-null: complement charset "^@"
	; word: :word-rule/word

	error: [(report 'parse-error)]
	null-error: [#"^@" (report 'unexpected-null-character)]
	unknown: to string! #{EFBFBD}
	timely-end: [end (is-done: true emit [end]) fail]
	untimely-end: [end (report 'untimely-end use data)]
	emit-one: [mark: skip (emit mark/1)]

	states: [
		data: [
				space (emit series/1)
			| copy mark [some non-markup any [some space some non-markup]] (emit mark)
			| #"&" (use character-reference-in-data)
			| #"<" (use tag-open)
			| null-error ; (emit unknown)
			| timely-end
		]

		character-reference-in-data: [
			(use data)
			end
			|
			and [space | #"&" | #"<"]
			|
			mark: (
				character: decode-markup mark
				mark: character/2
				either character/1 [
					emit character/1
				][
					emit "&"
				]
			) :mark
		]

		rcdata: [
				copy mark [some non-rcdata] (emit mark)
			| #"&" (use character-reference-in-rcdata)
			| #"<" (use rcdata-less-than-sign)
			| null-error (emit unknown)
			| timely-end
		]

		character-reference-in-rcdata: [
			(use rcdata)
			end
			|
			and [space | #"<" | #"&"]
			|
			(
				character: decode-markup series
				mark: character/2
				either character/1 [
					emit character/1
				][
					emit "&"
				]
			) :mark
		]

		rawtext: [
				copy mark some non-script (emit mark)
			| #"<" (use rawtext-less-than-sign)
			| null-error (emit unknown)
			| emit-one
			| timely-end
		]

		script-data: [
				copy mark some non-script (emit mark)
			| #"<" (use script-data-less-than-sign)
			| null-error (emit unknown)
			| timely-end
		]

		plaintext: [
				copy mark some not-null (emit mark)
			| null-error (emit unknown)
			| timely-end
		]

		tag-open: [
			#"!" (
				use markup-declaration-open
			)
			|
			#"/" (
				use end-tag-open
			)
			|
			copy mark [alpha any alphanum] (
				use tag-name
				token: reduce ['tag lowercase mark _ _]
			)
			|
			and "?" (
				use bogus-comment
				report 'unexpected-question-mark-instead-of-tag-name
			)
			|
			end (
				use data
				report 'eof-before-tag-name position
			)
			|
			(
				use data
				report 'invalid-first-character-of-tag-name
				emit "<" 
			)
		]

		end-tag-open: [
			copy mark some alpha (
				use tag-name
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			#">" (
				use data
				report 'missing-end-tag-name
			)
			|
			end (
				use data
				report 'eof-before-tag-name
				emit "</"
			)
			|
			(
				use bogus-comment
				report 'invalid-first-character-of-tag-name
			)
		]

		tag-name: [
			some space (
				adjust token
				use before-attribute-name
			)
			|
			#"/" (
				adjust token
				use self-closing-start-tag
			)
			|
			#">" (
				adjust token
				use data
				emit also token token: _
			)
			|
			copy mark some alpha (
				append token/2 lowercase mark
			)
			|
			null-error (
				append token/2 unknown
			)
			|
			end (
				use data
				report 'eof-in-tag
			)
			|
			skip (
				append token/2 series/1
			)
		]

		rcdata-less-than-sign: [
			#"/" (
				use rcdata-end-tag-open
				buffer: make string! 0
			)
			|
			(
				use rcdata
				emit "<"
			)
		]

		rcdata-end-tag-open: [
			copy mark some alpha (
				use rcdata-end-tag-name
				append buffer mark
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			(
				use rcdata
				emit "</"
				buffer: _
			)
		]

		rcdata-end-tag-name: [
			mark:
			[space | #"/" | #">"] (
				either all [
					token/1 = 'end-tag
					token/2 = closer
				][
					closer: _
					switch series/1 [
						#"^-" #"^/" #"^M" #" " [
							use before-attribute-name
							mark: next series
						]
						#"/" [
							use self-closing-start-tag
							mark: next series
						]
						#">" [
							use data
							mark: next series
							token/2: to word! token/2
							emit also token token: buffer: _
						]
					]
				][
					use rcdata
					emit "</"
					emit also buffer token: buffer: _
				]
			) :mark
			|
			copy mark some alpha (
				append buffer mark
				append token/2 lowercase mark
			)
			|
			(
				use rcdata
				emit "</"
				emit also buffer token: buffer: _
			)
		]

		rawtext-less-than-sign: [
			#"/" (
				use rawtext-end-tag-open
				buffer: make string! 0
			)
			|
			(
				use rawtext
				emit "<"
			)
		]

		rawtext-end-tag-open: [
			copy mark some alpha (
				use rawtext-end-tag-name
				append buffer mark
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			(
				use rawtext
				emit "</"
				emit also buffer buffer: _
			)
		]

		rawtext-end-tag-name: [
			mark:
			[space | #"/" | #">"] (
				either all [
					token/1 = 'end-tag
					token/2 = closer
				][
					closer: _
					adjust token
					switch series/1 [
						#"^-" #"^/" #"^M" #" " [
							use before-attribute-name
							mark: next series
						]
						#"/" [
							use self-closing-start-tag
							mark: next series
						]
						#">" [
							use data
							mark: next series
							emit also token token: buffer: _
						]
					]
				][
					use rawtext
					emit "</"
					emit also buffer token: buffer: _
				]
			) :mark
			|
			copy mark some alpha (
				append buffer mark
				append token/2 lowercase mark
			)
			|
			(
				use rawtext
				emit "</"
				emit also buffer token: buffer: _
			)
		]

		script-data-less-than-sign: [
			#"/" (
				use script-data-end-tag-open
				buffer: make string! 0
			)
			|
			#"!" (
				use script-data-escape-start
				emit "<!"
			)
			|
			(
				use script-data
				emit "<"
			)
		]

		script-data-end-tag-open: [
			copy mark some alpha (
				use script-data-end-tag-name
				append buffer mark
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			(
				use script-data
				emit "</"
				emit also buffer buffer: _
			)
		]

		script-data-end-tag-name: [
			mark:
			[space | #"/" | #">"] (
				either all [
					token/1 = 'end-tag
					token/2 = closer
				][
					closer: _
					adjust token
					switch series/1 [
						#"^-" #"^/" #"^M" #" " [
							use before-attribute-name
							mark: next series
						]
						#"/" [
							use self-closing-start-tag
							mark: next series
						]
						#">" [
							use data
							mark: next series
							emit also token token: buffer: _
						]
					]
				][
					use script-data
					emit "</"
					emit also buffer token: buffer: _
				]
			) :mark
			|
			copy mark some alpha (
				append buffer mark
				append token/2 lowercase mark
			)
			|
			(
				use script-data
				emit "</"
				emit also buffer token: buffer: _
			)
		]

		script-data-escape-start: [
			#"-" (
				use script-data-escape-start-dash
				emit "-"
			)
			|
			(
				use script-data
			)
		]

		script-data-escape-start-dash: [
			#"-" (
				use script-data-escaped-dash-dash
				emit "-"
			)
			|
			(
				use script-data
			)
		]

		script-data-escaped: [
			#"-" (
				use script-data-escaped-dash
				emit "-"
			)
			|
			#"<" (
				use script-data-escaped-less-than-sign
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one
		]

		script-data-escaped-dash: [
			#"-" (
				use script-data-escaped-dash-dash
				emit "-"
			)
			|
			#"<" (
				use script-data-escaped-less-than-sign
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one (
				use script-data-escaped
			)
		]

		script-data-escaped-dash-dash: [
			#"-" (
				emit "-"
			)
			|
			#"<" (
				use script-data-escaped-less-than-sign
			)
			|
			#">" (
				use script-data
				emit ">"
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one (
				use script-data-escaped
			)
		]

		script-data-escaped-less-than-sign: [
			#"/" (
				use script-data-escaped-end-tag-open
				buffer: make string! 0
			)
			|
			copy mark some alpha (
				use script-data-double-escape-start
				emit "<"
				emit mark
				buffer: lowercase mark
			)
			|
			(
				use script-data-escaped
				emit "<"
			)
		]

		script-data-escaped-end-tag-open: [
			copy mark some alpha (
				use script-data-escaped-end-tag-name
				append buffer mark
				token: reduce ['end-tag lowercase mark _ _]
			)
			|
			(
				use script-data-escaped
				emit "</"
				emit also buffer buffer: _
			)
		]

		script-data-escaped-end-tag-name: [
			mark:
			[space | #"/" | #">"] (
				either all [
					token/1 = 'end-tag
					token/2 = closer
				][
					closer: _
					adjust token
					switch series/1 [
						#"^-" #"^/" #"^M" #" " [
							use before-attribute-name
							mark: next series
						]
						#"/" [
							use self-closing-start-tag
							mark: next series
						]
						#">" [
							use data
							mark: next series
							emit also token token: buffer: _
						]
					]
				][
					use script-data-escaped
					emit "</"
					emit also buffer token: buffer: _
				]
			) :mark
			|
			copy mark some alpha (
				append buffer mark
				append token/2 lowercase mark
			)
			|
			(
				use script-data-escaped
				emit "</"
				emit also buffer token: buffer: _
			)
		]

		script-data-double-escape-start: [
			[space | #"/" | #">"] (
				either buffer == "script" [
					use script-data-double-escaped
				][
					use script-data-escaped
				]
				emit series/1
			)
			|
			copy mark some alpha (
				emit mark
				append buffer lowercase mark
			)
			|
			(
				use script-data
			)
		]

		script-data-double-escaped: [
			#"-" (
				use script-data-double-escaped-dash
				emit "-"
			)
			|
			#"<" (
				use script-data-double-escaped-less-than-sign
				emit "<"
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one
		]

		script-data-double-escaped-dash: [
			#"-" (
				use script-data-double-escaped-dash-dash
				emit "-"
			)
			|
			#"<" (
				use script-data-double-escaped-less-than-sign
				emit "<"
			)
			|
			null-error (
				emit unknown
			)
			|
			untimely-end
			|
			emit-one (
				use script-data-double-escaped
			)
		]

		script-data-double-escaped-dash-dash: [
			#"-" (
				emit "-"
			)
			|
			#"<" (
				use script-data-double-escaped-less-than-sign
				emit "<"
			)
			|
			#">" (
				use script-data
				emit ">"
			)
			|
			null-error (
				use script-data-double-escaped
				emit unknown
			)
			|
			untimely-end
			|
			emit-one (
				use script-data-double-escaped
			)
		]

		script-data-double-escaped-less-than-sign: [
			#"/" (
				use script-data-double-escape-end
				emit "/"
				buffer: make string! 0
			)
			|
			[end | emit-one] (
				use script-data-double-escaped
			)
		]

		script-data-double-escape-end: [
			mark:
			[space | #"/" | #">"] (
				either buffer == "script" [
					use script-data-escaped
				][
					use script-data-double-escaped
				]
				emit mark/1
			)
			|
			copy mark some alpha (
				emit mark
				append buffer lowercase mark
			)
			|
			(
				use script-data-double-escaped
			)
		]

		before-attribute-name: [
			some space
			|
			#"/" (
				use self-closing-start-tag
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end
			|
			[
					null-error (mark: unknown)
				| copy mark some alpha (lowercase mark)
				| copy mark [#"^(22)" | #"'" | #"<" | #"="] error
				| copy mark skip
			] (
				use attribute-name
				token/3: any [token/3 make map! 0]
				attribute: reduce [mark make string! 0]
			)
		]

		attribute-name: [
			[
					some space (use after-attribute-name)
				| #"/" (use self-closing-start-tag)
				| #"=" (use before-attribute-value)
				| untimely-end
			] (
				either find token/3 attribute/1 [
					report 'duplicate-attribute
				][
					put token/3 attribute/1 attribute/2
				]
			)
			|
			#">" (
				use data
				either find token/3 attribute/1 [
					report 'duplicate-attribute
				][
					put token/3 attribute/1 attribute/2
				]
				emit also token token: attribute: _
			)
			|
			[
				null-error (mark: unknown)
				|
				copy mark some alpha (lowercase mark)
				|
				copy mark [#"^(22)" | #"'" | #"<"] (
					report 'unexpected-character-in-attribute-name
				)
				|
				copy mark skip
			] (
				append attribute/1 mark
			)
		]

		after-attribute-name: [
			some space
			|
			#"/" (
				use self-closing-start-tag
			)
			|
			#"=" (
				use before-attribute-value
			)
			|
			#">" (
				use data
				emit token
			)
			|
			untimely-end
			|
			[
					null-error (mark: unknown)
				| copy mark some alpha (lowercase mark)
				| [#"^(22)" | #"'" | #"<"] error
				| copy mark skip
			] (
				use attribute-name
				attribute: reduce [mark make string! 0]
			)
		]

		before-attribute-value: [
			some space
			|
			#"^(22)" (
				use attribute-value-double-quoted
				additional-character: #"^(22)"
			)
			|
			#"'" (
				use attribute-value-single-quoted
				additional-character: #"'"
			)
			|
			#">" (
				use data
				report 'missing-attribute-value
				emit also token token: attribute: _
			)
			|
			(
				use attribute-value-unquoted
				additional-character: #">"
			)
		]

		attribute-value-double-quoted: [ ; 38
			#"^(22)" (
				use after-attribute-value-quoted
			)
			|
			#"&" (
				use character-reference-in-attribute-value
			)
			|
			untimely-end
			|
			[null-error (mark: unknown) | copy mark skip] (
				append attribute/2 mark
			)
		]

		attribute-value-single-quoted: [
			#"'" (
				use after-attribute-value-quoted
			)
			|
			#"&" (
				use character-reference-in-attribute-value
			)
			|
			untimely-end
			|
			[null-error (mark: unknown) | copy mark skip] (
				append attribute/2 mark
			)
		]

		attribute-value-unquoted: [
			some space (
				use before-attribute-name
			)
			|
			#"&" (
				use character-reference-in-attribute-value
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			end (
				use data
				report 'eof-in-tag
			)
			|
			[
				null-error (mark: unknown)
				|
				copy mark [#"^(22)" | #"'" | #"<" | #"=" | #"`"] (
					report 'unexpected-character-in-unquoted-attribute-value
				)
				|
				copy mark skip
			] (
				append attribute/2 mark
			)
		]

		character-reference-in-attribute-value: [
			(use :last-state-name)
			end
			|
			and [space | #"&" | #"<" | additional-character]
			|
			mark: (
				character: decode-markup mark
				mark: character/2
				either character/1 [
					append attribute/2 character/1
				][
					append attribute/2 #"&"
				]
			) :mark
		]

		after-attribute-value-quoted: [
			some space (
				use before-attribute-name
			)
			|
			#"/" (
				use self-closing-start-tag
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end
			|
			(
				use attribute-name
			)
		]

		self-closing-start-tag: [
			#">" (
				use data
				token/4: 'self-closing
				emit token
			)
			|
			untimely-end
			|
			(
				use before-attribute-name
				report "Expected '>'"
			)
		]

		bogus-comment: [
			(use data)
			[
					copy mark to #">" skip
				| copy mark to end
			] (
				emit reduce ['comment mark]
			)
		]

		markup-declaration-open: [
			"--" (
				use comment-start
				token: reduce ['comment make string! 0]
			)
			|
			d o c t y p e (
				use doctype
			)
			|
			and "[CDATA[" (
				use bogus-comment
				report "CDATA not supported"
			)
			|
			(
				use bogus-comment
				report "Malformed comment"
			)
		]

		comment-start: [
			#"-" (
				use comment-start-dash
			)
			|
			#">" (
				use data
				report "Malformed Comment"
				emit also token token: _
			)
			|
			untimely-end
			|
			[
					null-error (mark: unknown)
				| copy mark skip
			] (
				use comment
				append token/2 mark
			)
		]

		comment-start-dash: [
			#"-" (
				use comment-end
			)
			|
			#">" (
				use data
				report "Malformed comment"
				emit also token token: _
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			(
				use comment
				emit "-"
			)
		]

		comment: [
			#"-" (
				use comment-end-dash
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			[
					null-error (mark: unknown)
				| copy mark some alpha
				| copy mark skip
			] (
				append token/2 mark
			)
		]

		comment-end-dash: [
			#"-" (
				use comment-end
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			[
					null-error (mark: unknown)
				| copy mark skip
			] (
				use comment
				append token/2 #"-"
				append token/2 mark
			)
		]

		comment-end: [
			#">" (
				use data
				emit also token token: _
			)
			|
			"!" (
				use comment-end-bang
				report "Malformed comment"
			)
			|
			#"-" (
				report "Too many consecutive dashes in comment"
				append token/2 #"-"
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			[
					null-error (mark: unknown)
				| copy mark skip (report "Expected end of comment")
			] (
				append token/2 "--"
				append token/2 mark
			)
		]

		comment-end-bang: [
			#"-" (
				use comment-end-dash
				append token/2 "--!"
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end (
				emit also token token: _
			)
			|
			[
					null-error (mark: unknown)
				| copy mark skip
			] (
				use comment
				append token/2 "--!"
				append token/2 mark
			)
		]

		doctype: [
			some space (
				use before-doctype-name
			)
			|
			untimely-end (
				emit reduce ['doctype _ _ _ 'force-quirks]
			)
			|
			(
				use before-doctype-name
				report "Extraneous characters in doctype"
			)
		]

		before-doctype-name: [
			some space
			|
			[
					null-error (mark: unknown)
				| copy mark some alpha (lowercase mark)
				| copy mark skip
			] (
				use doctype-name
				token: reduce ['doctype mark _ _ _]
			)
			|
			#">" (
				use data
				emit reduce ['doctype _ _ _ 'force-quirks]
			)
			|
			untimely-end (
				emit reduce ['doctype _ _ _ 'force-quirks]
			)
		]

		doctype-name: [
			space (
				use after-doctype-name
			)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[
					null-error (mark: unknown)
				| copy mark any alpha (lowercase mark)
				| copy mark skip
			] (
				append token/2 mark
			)
		]

		after-doctype-name: [
			some space
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			p u b l i c (
				use after-doctype-public-keyword
			)
			|
			s y s t e m (
				use after-doctype-system-keyword
			)
			|
			skip (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		after-doctype-public-keyword: [
			some space (
				use before-doctype-public-identifier
			)
			|
			#"^(22)" error (
				use doctype-public-identifier-double-quoted
				token/3: make string! 0
			)
			|
			#"'" error (
				use doctype-public-identifier-single-quoted
				token/3: make string! 0
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		before-doctype-public-identifier: [
			some space
			|
			#"^(22)" (
				use doctype-public-identifier-double-quoted
				token/3: make string! 0
			)
			|
			#"'" (
				use doctype-public-identifier-single-quoted
				token/3: make string! 0
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		doctype-public-identifier-double-quoted: [
			#"^(22)" (
				use after-doctype-public-identifier
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[null-error (mark: unknown) | copy mark [some alpha | skip]] (
				append token/3 mark
			)
		]

		doctype-public-identifier-single-quoted: [
			#"'" (
				use after-doctype-public-identifier
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[
					null-error (mark: unknown)
				| copy mark [some alpha | skip]
			] (append token/3 mark)
		]

		after-doctype-public-identifier: [
			space (use between-doctype-public-and-system-identifiers)
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			#"^(22)" error (
				use doctype-system-identifier-double-quoted
				token/4: make string! 0
			)
			|
			#"'" error (
				use doctype-system-identifier-single-quoted
				token/4: make string! 0
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		between-doctype-public-and-system-identifiers: [
			some space
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			#"^(22)" (
				use doctype-system-identifier-double-quoted
				token/4: make string! 0
			)
			|
			#"'" (
				use doctype-system-identifier-single-quoted
				token/4: make string! 0
			)
			|
			untimely-end (
				token/5: 'force-quirks
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		after-doctype-system-keyword: [
			some space (
				use before-doctype-system-identifier
			)
			|
			#"^(22)" (
				use doctype-system-identifier-double-quoted
				token/4: make string! 0
			)
			|
			#"'" (
				use doctype-system-identifier-single-quoted
				token/4: make string! 0
			)
			|
			#">" (
				use data
				report "Premature end of DOCTYPE System ID"
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip (
				use bogus-doctype
				report "Unexpected value in DOCTYPE declaration"
				token/5: 'force-quirks
			)
		]

		before-doctype-system-identifier: [
			some space
			|
			#"^(22)" (
				use doctype-system-identifier-double-quoted
				token/4: make string! 0
			)
			|
			#"'" (
				use doctype-system-identifier-single-quoted
				token/4: make string! 0
			)
			|
			#">" error (
				use data
				report 'system-identifier-missing
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip error (
				use bogus-doctype
				token/5: 'force-quirks
			)
		]

		doctype-system-identifier-double-quoted: [
			#"^(22)" (
				use after-doctype-system-identifier
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[
					null-error (mark: unknown)
				| copy mark some [space | alpha] (lowercase mark)
				| copy mark skip
			] (
				append token/4 mark
			)
		]

		doctype-system-identifier-single-quoted: [
			#"'" (
				use after-doctype-system-identifier
			)
			|
			#">" error (
				use data
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			[
					null-error (mark: unknown)
				| copy mark some [space | alpha] (lowercase mark)
				| copy mark skip
			] (
				append token/4 mark
			)
		]

		after-doctype-system-identifier: [
			some space
			|
			#">" (
				use data
				emit also token token: _
			)
			|
			untimely-end (
				token/5: 'force-quirks
				emit also token token: _
			)
			|
			skip (
				use bogus-doctype
			)
		]

		bogus-doctype: [
			#">" (
				use data
				emit token
			)
			|
			end (
				use data
				emit token
			)
			|
			skip
		]

		cdata-section: [
			(use data)
			[copy mark to "]]>" 3 skip | copy mark to end]
			(emit mark)
		]
	]

	emit: report: _

	adjust: func [token][
		also token token/2: any [
			select references/elements token/2
			token/2
		]
	]

	current-state-name: current-state: state: last-state-name: _

	use: func ['target [word!] /until end-tag [string!]][
		last-state-name: :current-state-name
		current-state-name: target
		if until [closer: :end-tag]
		; probe to tag! target
		; probe copy/part series 10
		state: current-state: any [
			select states :target
			do make error! rejoin ["No Such State: " uppercase form target]
		]
	]

	rule: [
		while [series: state]
		series: (
			; Work around Red issue: https://github.com/red/red/issues/2907
			loop-until [
				any [
					is-paused
					is-done
					; (probe state false)
					parse/case series [series: state]
				]
			]
		)
	]

	init: func [
		"Initialize the tokenization process"
		source [string!] "A markup string to tokenize"
		token-handler [function!] "A function to handle tokens"
		error-handler [function!] "A function to handle errors"
	][
		mark: buffer: attribute: token: last-token: character: additional-character: _
		current-state-name: current-state: state: last-state-name: _
		is-paused: is-done: false
		series: :source
		emit: :token-handler
		report: :error-handler
		self
	]

	start: func [
		"Start the tokenization process"
	][
		unless string? series [
			do make error! "Tokenization process has not been initialized"
		]
		use data
		parse/case series rule
	]

	pause: func [
		"Pause the tokenization process"
	][
		is-paused: true
		state: [fail]
	]

	resume: func [
		"Resume the tokenization process"
	][
		unless string? series [
			do make error! "Tokenization process has not been initialized"
		]
		is-paused: false
		state: :current-state
		parse/case series rule
	]
]

markup-loader: make object! [
	last-token: _

	load-markup: func [source [string!]][
		last-token: _
		collect [
			html-tokenizer/init source
			func [token [block! char! string!]][
				case [
					not block? token [
						either all [
							last-token
							last-token/1 = 'text
						][
							append last-token/2 token
							token: last-token
						][
							token: reduce ['text to string! token]
							keep token/2
						]
					]

					token/1 = 'tag [
						keep to tag! token/2
						if map? token/3 [keep token/3]
						if token/4 [keep </>]

						switch token/2 [
							script [
								html-tokenizer/use/until script-data form token/2
							]
							title [
								html-tokenizer/use/until rcdata form token/2
							]
							style textarea [
								html-tokenizer/use/until rawtext form token/2
							]
						]
					]

					token/1 = 'end-tag [
						keep to tag! rejoin ["/" token/2]
					]

					token/1 = 'comment [
						keep to tag! rejoin ["!--" token/2 "--"]
					]
				]

				also _ last-token: :token
			]
			func [value][value]

			html-tokenizer/start
		]
	]
]

markup-as-block: function [node [map! block!]][
	tags: references/tags

	new-line/all/skip collect [
		switch/default node/type [
			element [
				keep any [
					select tags node/name
					node/name
				]
				either any [node/value node/first][
					keep/only new-line/all/skip collect [
						if node/value [
							keep %.attrs
							keep node/value
						]
						kid: node/first
						while [kid][
							keep markup-as-block kid
							kid: kid/next
						]
					] true 2
				][
					keep _
				]
			]
			document [
				kid: node/first
				while [kid][
					keep markup-as-block kid
					kid: kid/next
				]
			]
			text [
				keep %.txt
				keep node/value
			]
			comment [
				keep %.comment
				keep to tag! rejoin ["!--" node/value "--"]
			]
		][
			keep _
			keep to tag! node/type
		]
	] true 2
]

html-loader: make object! [
	document: space: head-node: body-node: form-node: parent: kid: last-token: _
	open-elements: active-formatting-elements: pending-table-characters:
	current-node: nodes: node: mark: _
	insertion-point: insertion-type: _
	fostering?: false

	specials: [
		address applet area article aside base basefont bgsound blockquote body br button
		caption center col colgroup dd details dir div dl dt embed fieldset figcaption
		figure footer form frame frameset h1 h2 h3 h4 h5 h6 head header hgroup hr html
		iframe img input isindex li link listing main marquee meta nav noembed noframes
		noscript object ol p param plaintext pre script section select source style
		summary table tbody td template textarea tfoot th thead title tr track ul wbr xmp
		mi mo mn ms mtext annotation-xml
		foreignobject desc title
	]

	formatting: [
		a b big code em font i nobr s small strike strong tt u
	]

	scopes: [
		default: [
			applet caption html table td th marquee object
			mi mo mn ms mtext annotation-xml
			foreignobject desc title
		]
		list-item: [
			applet caption html table td th marquee object
			mi mo mn ms mtext annotation-xml
			foreignobject desc title
			ul ol
		]
		button: [
			applet caption html table td th marquee object
			mi mo mn ms mtext annotation-xml
			foreignobject desc title
			button
		]
		table: [html table]
		select: [optgroup option]
	]

	implied-end-tags: [
		dd dt li option optgroup p rb rp rt rtc
	]

	header-elements: [
		h1 h2 h3 h4 h5 h6
	]

	ruby-elements: [
		rb rp rt rtc
	]

	push: func [node [block! map!]][
		also current-node: node insert/only open-elements node
	]

	pop-element: does [
		also take open-elements current-node: pick open-elements 1
	]

	push-formatting: func [node [block! map! issue!] /local mark count][
		also node case [
			; issue? node [
			; ]
			/else [
				count: 1
				mark: :active-formatting-elements
				while [
					not any [
						tail? mark
						issue? first mark
					]
				][
					either all [
						equal? node/name mark/1/name
						maps-equal? node/value mark/1/value
						(increment count) > 3
					][
						remove mark
					][
						mark: next mark
					]
				]
				insert/only active-formatting-elements node
			]
		]
	]

	pop-formatting: func [node [block! map! issue!]][
		also node case [
			issue? node [
				while [not tail? active-formatting-elements][
					if issue? take active-formatting-elements [
						break
					]
				]
			]

			/else [
				remove-each element active-formatting-elements [
					same? element node
				]
			]
		]
	]

	find-element: func [from [block!] element [block! map!]][
		catch [
			also _ forall from [
				case [
					issue? from/1 [break]

					same? element from/1 [
						throw from
					]
				]
			]
		]
	]

	select-element: func [from [block!] name [word! string!]][
		catch [
			also _ foreach node from [
				case [
					issue? node [break]
					node/name = name [throw node]
				]
			]
		]
	]

	tagify: func [name [word! string!] /close /local source][
		source: either close ['end-tags]['tags]
		any [
			select references/:source name
			name
		]
	]

	set-insertion-point: func [override-target [blank! block! map!] /local target last-table][
		target: any [
			:override-target
			current-node
		]

		insertion-type: 'append
		insertion-point: either all [
			fostering?
			find [table tbody tfoot thead tr] target/name
		][
			case [
				blank? last-table: select-element open-elements 'table [
					last open-elements
				]

				last-table/parent [
					insertion-type: 'before
					last-table
				]

				/else [
					first next find-element open-elements last-table
				]
			]
		][
			target
		]
	]

	reset-insertion-mode: func [/local mark node][
		mark: :open-elements
		forall mark [
			if any-value? switch tagify mark/1/name [
				<select> [
					use in-select
					foreach node next mark [
						switch tagify node/name [
							<template> [break]
							<table> [
								use in-select-in-table
								break
							]
						]
					]
					state
				]
				<td> <th> [either tail? next mark [_][use in-cell]]
				<tr> [use in-row]
				<tbody> <tfoot> <thead> [use in-table-body]
				<caption> [use in-caption]
				<colgroup> [use in-column-group]
				<table> [use in-table]
				; <template> [use in-body] ; template not supported at this time
				<head> [either tail? next mark [_][use in-head]]
				<body> [use in-body]
				<frameset> [use in-frameset]
				<html> [
					either document/head [
						use after-head
					][
						use before-head
					]
				]
			][
				break
			]
		]
	]

	append-element: func [token [block!] /to parent [map! block!] /namespace 'space [word!] /local node][
		; probe token
		set-insertion-point any [:parent _]

		unless map? :parent [parent: :current-node]
		unless word? :space [space: 'html]

		node: switch insertion-type [
			append [trees/append insertion-point]
			before [trees/insert-before insertion-point]
		]

		node/type: 'element
		node/name: token/2
		node/value: pick token 3
		node
	]

	append-comment: func [token [block!] /to parent [map! block!] /local node][
		set-insertion-point any [:parent _]

		node: switch insertion-type [
			append [trees/append insertion-point]
			before [trees/insert-before insertion-point]
		]

		node/type: 'comment
		node/value: token/2
		node
	]

	append-text: func [token [char! string!] /to parent [map! block!] /local target][
		set-insertion-point any [:parent _]

		target: switch insertion-type [
			append [insertion-point/last]
			before [insertion-point/back]
		]

		unless all [
			target
			target/type = 'text
		][
			target: switch insertion-type [
				append [trees/append insertion-point]
				before [trees/insert-before insertion-point]
			]
			target/type: 'text
			target/value: make string! 0
		]

		append target/value token
	]

	close-element: func [token [block!]][
		foreach node open-elements [
			case [
				token/2 = node/name [
					generate-implied-end-tags/thru :token/2
					pop-formatting node ; temporary until adoption agency algorithm works
					break
				]
				find specials node/name [
					; error
					break
				]
			]
		]
	]

	find-in-scope: func ['target [word! block!] /scope 'scope-name [word!] /local mark][
		if word? :target [target: reduce [target]]

		unless word? :scope-name [
			scope-name: 'default
		]

		scope: any [
			select scopes scope-name
			do make error! rejoin ["Scope not available: " to tag! scope-name]
		]

		; Red alters series position with FORALL
		mark: :open-elements

		catch [
			also false forall mark [
				case [
					find target mark/1/name [throw mark/1]
					find scope mark/1/name [break]
				]
			]
		]
	]

	find-element-in-scope: func [
		element [block! map!]
		/scope 'scope-name [word!]
		/local mark
	][
		unless word? :scope-name [
			scope-name: 'default
		]

		scope: any [
			select scopes scope-name
			do make error! rejoin ["Scope not available: " to tag! scope-name]
		]

		; Red alters series position with FORALL
		mark: :open-elements

		catch [
			also false forall mark [
				case [
					same? element mark/1 [throw mark]
					find scope mark/1/name [break]
				]
			]
		]
	]

	close-thru: func ['name [word! string! block!] /quiet][
		name: compose [(name)]
		loop-until [
			; is assumed that NAME exists in the OPEN-ELEMENTS stack
			to logic! find name select pop-element 'name
		]
		current-node
	]

	generate-implied-end-tags: func [
		/thru 'target [word! string! block!]
		/except exceptions [block!]
	][
		target: compose [(any [:target []])]

		exceptions: compose [
			(target) (any [:exceptions []])
		]

		while compose/only [
			find (exclude implied-end-tags exceptions) current-node/name
		][
			pop-element
		]

		if thru [
			unless find target current-node/name [
				; error
			]
			close-thru :target
		]

		current-node
	]

	close-para-if-in-scope: func [/local node][
		if find-in-scope/scope p button [
			generate-implied-end-tags/thru p
		]
	]

	probe-stacks: does [
		print unspaced [
			"Open Elements: " mold map-each item open-elements [item/name] newline
			"Active Formatting: " mold map-each item active-formatting-elements [
				either issue? item [item][item/name]
			] newline
		]
	]

	reconstruct-formatting-elements: does [
		unless empty? active-formatting-elements [
			while [
				not tail? active-formatting-elements
			][
				either any [
					issue? first active-formatting-elements
					find-element open-elements first active-formatting-elements
				][
					break
				][
					active-formatting-elements: next active-formatting-elements
				]
			]

			while [
				not head? active-formatting-elements
			][
				active-formatting-elements: back active-formatting-elements
				change/only active-formatting-elements push append-element reduce [
					'tag active-formatting-elements/1/name active-formatting-elements/1/value
				]
			]
		]
	]

	adopt: func [
		token [block!]
		/local formatting-element element clone subject count
		common-ancestor bookmark node last-node position mark furthest-block
	][
		subject: token/2

		either all [
			equal? current-node/name subject
			not find-element active-formatting-elements current-node
		][
			pop-element
		][
			loop 8 [
				formatting-element: select-element active-formatting-elements :subject

				case [
					not formatting-element [
						close-element token
						break
					]

					not find-element open-elements formatting-element [
						report 'adoption-agency-1.2
						pop-formatting formatting-element
						break
					]

					not find-element-in-scope formatting-element [
						report 'adoption-agency-4.4
						break
					]

					not same? current-node formatting-element [
						report 'adoption-agency-1.3
					]
				]

				mark: find-element copy open-elements formatting-element
				common-ancestor: first next mark

				unless furthest-block: catch [
					also _ while [not head? mark][
						mark: back mark
						if find specials mark/1/name [
							throw mark/1
						]
					]
				][
					loop-until [
						same? formatting-element pop-element
					]
					pop-formatting formatting-element
					break
				]

				bookmark: find-element active-formatting-elements formatting-element
				node: last-node: furthest-block
				count: 0

				forever [
					increment count

					node: first mark: next mark

					case/all [
						same? formatting-element node [
							break
						]

						all [
							count > 3
							find-element active-formatting-elements node
						][
							pop-formatting node
						]

						not find-element active-formatting-elements node [
							remove find-element open-elements node
							continue
						]
					]

					clone: trees/make-node
					clone/type: 'element
					clone/name: node/name
					clone/value: node/value

					change/only find-element open-elements node clone
					change/only find-element active-formatting-elements node clone

					node: :clone

					if same? furthest-block last-node [
						bookmark: find-element active-formatting-elements clone
					]

					trees/append-existing node trees/remove last-node

					last-node: :node
				]

				if last-node/parent [
					trees/remove last-node
				]

				set-insertion-point common-ancestor
				trees/append-existing insertion-point last-node

				clone: trees/make-node
				clone/type: 'element
				clone/name: formatting-element/name
				clone/value: formatting-element/value

				while [furthest-block/first][
					trees/append-existing clone trees/remove furthest-block/first
				]

				trees/append-existing furthest-block clone

				insert/only bookmark clone
				pop-formatting formatting-element

				remove find-element open-elements formatting-element
				insert/only find-element open-elements furthest-block clone

				current-node: first open-elements
			]
		]
	]

	clear-stack-to-table: func [/body /row /local target][
		target: case [
			body [[tbody tfoot thead template html]]
			row [[tr template html]]
			/else [scopes/table]
		]
		while compose/only [
			not find (target) current-node/name
		][
			pop-element
		]
	]

	finish-up: does [
		while [
			not empty? open-elements
		][
			pop-element
		]
	]

	states: [
		initial: [
			"Initial"
			space []
			doctype [
				document/name: token/2
				document/public: token/3
				document/system: token/4
				use before-html
			]
			tag end-tag text end [
				; error
				use before-html
				do-token token
			]
			comment [append-comment/to token document]
		]

		before-html: [
			"Before HTML"
			space []
			doctype [
				report 'unexpected-doctype
			]
			<html> [
				push append-element/to token document
				use before-head
			]
			text tag </head> </body> </html> </br> end else [
				push append-element/to [tag html] document
				use before-head
				do-token token
			]
			comment [append-comment/to token document]
		]

		before-head: [
			"Before Head"
			space []
			doctype [
				report 'unexpected-doctype
			]
			<html> [
				do-token/in token in-body
			]
			<head> [
				document/head: push append-element token
				use in-head
			]
			text tag </head> </body> </html> </br> end else [
				document/head: push append-element [tag head]
				use in-head
				do-token token
			]
			end-tag [
				; error
			]
			comment [append-comment token]
		]

		in-head: [
			"In Head"
			space [
				append-text token
			]
			doctype [
				report 'unexpected-doctype
			]
			<html> [
				do-token/in token in-body
			]
			<base> <basefont> <bgsound> <link> <meta> [
				append-element token
			]
			<title> [
				push append-element token
				html-tokenizer/use/until rcdata form token/2
				use/return text
			]
			<noframes> <style> [
				push append-element token
				html-tokenizer/use/until rawtext form token/2
				use/return text
			]
			<noscript> [ ; scripting flag is false
				push append-element token
				use in-head-noscript
			]
			<script> [
				push append-element token
				html-tokenizer/use/until script-data form token/2
				use/return text
			]
			<head> [
				; error
			]
			</head> [
				pop-element
				use after-head
			]
			text tag </body> </html> </br> end else [
				pop-element
				use after-head
				do-token token
			]
			end-tag [
				; error
			]
			comment [append-comment token]
		]

		in-head-noscript: [
			"In Head (NoScript)"
			space [
				do-token/in token in-head
			]
			doctype [
				; error
			]
			<html> [
				do-token/in token in-body
			]
			<basefont> <bgsound> <link> <meta> <noframes> <style> [
				do-token/in token in-head
			]
			<head> <noscript> [
				; error
			]
			</noscript> [
				pop-element
				use in-head
			]
			text tag </br> end else [
				; error
				node: node/parent
				use in-head
				do-token token
			]
			end-tag [
				; error
			]
			comment [do-token/in token in-head]
		]

		after-head: [
			"After Head"
			space [append-text token]
			doctype [
				; error
			]
			<html> [
				do-token/in token in-body
			]
			<body> [
				document/body: push append-element token
				use in-body
			]
			<frameset> [
				push append-element token
				use in-frameset
			]
			<base <basefont> <bgsound> <link> <meta> <noframes>
			<script> <style> <template> <title> [
				; error
				push document/head
				do-token/in token in-head
				
			]
			<head> [
				; error
			]
			text tag </body> </html> </br> end else [
				document/body: push append-element [tag body]
				use in-body
				do-token token
			]
			end-tag [
				; error
			]
			comment [append-comment token]
		]

		in-body: [
			"In Body"
			space text [
				reconstruct-formatting-elements
				append-text token
			]
			doctype [
				report 'unexpected-doctype
			]
			<html> [
				; error
				; check attributes
			]
			<base> <basefont> <bgsound> <link> <meta> <noframes>
			<script> <style> <template> <title> [
				; error
				do-token/in token in-head
			]
			<body> [
				; error
				; check attributes
			]
			<frameset> [
				; error
				; handle frameset
			]
			<address> <article> <aside> <blockquote> <center> <details> <dialog>
			<dir> <div> <dl> <fieldset> <figcaption> <figure> <footer> <header>
			<hgroup> <main> <nav> <ol> <p> <section> <summary> <ul> [
				close-para-if-in-scope
				push append-element token
			]
			<h1> <h2> <h3> <h4> <h5> <h6> [
				close-para-if-in-scope
				if find header-elements current-node/name [
					; error
					pop-element
				]
				push append-element token
			]
			<pre> <listing> [
				close-para-if-in-scope
				push append-element token
			]
			<form> [
				either document/form [
					; error
				][
					close-para-if-in-scope
					document/form: push append-element token
				]
			]
			<li> [
				nodes: :open-elements
				forall nodes [
					node: pick nodes 1
					case [
						node/name = 'li [
							generate-implied-end-tags/thru li
							break
						]

						find exclude specials [address div p] node/name [
							break
						]
					]
				]
				close-para-if-in-scope
				push append-element token
			]
			<dd> <dt> [
				foreach node open-elements [
					case [
						node/name = 'dd [
							generate-implied-end-tags/thru dd
							break
						]

						node/name = 'dt [
							generate-implied-end-tags/thru dt
							break
						]

						find exclude specials [address div p] node/name [
							break
						]
					]
				]
				close-para-if-in-scope
				push append-element token
			]
			<plaintext> [
				close-para-if-in-scope
				html-tokenizer/use plaintext
				push append-element token
			]
			<button> [
				if find-in-scope button [
					; error
					close-thru button
				]
				reconstruct-formatting-elements
				push append-element token
			]
			<a> [
				if select-element open-elements 'a [
					; error
					do-token [end-tag a]
				]
				reconstruct-formatting-elements
				push-formatting push append-element token
			]
			<nobr> [
				reconstruct-formatting-elements
				if find-in-scope nobr [
					; error
					do-token [end-tag nobr]
					reconstruct-formatting-elements
				]
				push-formatting push append-element token
			]
			<b> <big> <code> <em> <font> <i> <s> <small> <strike> <strong> <tt> <u> [
				reconstruct-formatting-elements
				push-formatting push append-element token
			]
			<applet> <marquee> <object> [
				reconstruct-formatting-elements
				push append-element token
				push-formatting to issue! token/2
			]
			<table> [
				; unless document/quirks-mode [
					close-para-if-in-scope
				; ]
				push append-element token
				use in-table
			]
			<area> <br> <embed> <img> <keygen> <wbr> [
				reconstruct-formatting-elements
				append-element token
				; acknowledge self-closing flag
			]
			<input> [
				reconstruct-formatting-elements
				append-element token
				; acknowledge self-closing flag
			]
			<param> <source> <track> [
				append-element token
			]
			<hr> [
				close-para-if-in-scope
				append-element token
				; acknowledge self-closing flag
			]
			<image> [
				; error
				token/2: 'img
				do-token token
			]
			<textarea> [
				push append-element token
				html-tokenizer/use/until rcdata form token/2
				use/return text
			]
			<xmp> [
				close-para-if-in-scope
				reconstruct-formatting-elements
				push append-element token
				html-tokenizer/use/until rawtext form token/2
				use/return text
			]
			<iframe> [
				push append-element token
				html-tokenizer/use/until rawtext form token/2
				use/return text
			]
			<noembed> [
				push append-element token
				html-tokenizer/use/until rawtext form token/2
				use/return text
			]
			<select> [
				reconstruct-formatting-elements
				push append-element token
				either find [in-table in-caption in-table-body in-row in-cell] current-state-name [
					use in-select-in-table
				][
					use in-select
				]
			]
			<optgroup> <option> [
				if current-node/name = 'option [
					pop-element
				]
				reconstruct-formatting-elements
				push append-element token
			]
			<rb> <rtc> [
				if find-in-scope ruby [
					generate-implied-end-tags
					unless current-node/name = 'ruby [
						; error
					]
				]
				push append-element token
			]
			<rp> <rt> [
				if find-in-scope ruby [
					generate-implied-end-tags/except [rtc]
					unless find [ruby rtc] current-node/name [
						; error
					]
				]
				push append-element token
			]
			<math> [
				reconstruct-formatting-elements
				; adjust-math-ml-attributes
				; adjust-foreign-attributes
				push append-element/namespace token mathml
				if token 'self-closing [
					pop-element
				]
			]
			<svg> [
				reconstruct-formatting-elements
				; adjust-math-ml-attributes
				; adjust-foreign-attributes
				push append-element/namespace token svg
				if find token 'self-closing [
					pop-element
				]
			]
			<caption> <col> <colgroup> <frame> <head> <tbody> <td> <tfoot> <th>
			<thead> <tr> [
				; error
			]
			</body> [
				; error if a tag is open other than
				; --list of tags--
				use after-body
			]
			</html> [
				; error if a tag is open other than
				; --list of tags--
				use after-body
				do-token token
			]
			</address> </article> </aside> </blockquote> </button> </center> </details>
			</dialog> </dir> </div> </dl> </fieldset> </figcaption> </figure> </footer>
			</header> </hgroup> </listing> </main> </nav> </ol> </pre> </section> </summary>
			</ul> [
				either find-in-scope :token/2 [
					close-thru :token/2
				][
					; error
				]
			]
			</form> [
				node: document/form
				document/form: _
				case [
					blank? node [
						; error
					]

					not same? node find-in-scope form [
						; error
					]

					(
						generate-implied-end-tags
						same? node current-node
					) [
						pop-element
					]

					/else [
						; error
						if node: find-element open-elements node [
							remove node
						]
					]
				]
			]
			</p> [
				unless find-in-scope/scope p button [
					push append-element [tag p]
				]
				close-para-if-in-scope
			]
			</li> [
				either find-in-scope/scope li list-item [
					close-thru li
				][
					; error
				]
			]
			</dd> </dt> [
				either find-in-scope :token/2 [
					close-thru :token/2
				][
					; error
				]
			]
			</h1> </h2> </h3> </h4> </h5> </h6> [
				either find-in-scope :header-elements [
					generate-implied-end-tags
					unless token/2 = current-node/name [
						; error
					]
					close-thru :header-elements
				][
					; error
				]
			]
			</a> </b> </big> </code> </em> </font> </i> </nobr> </s> </small> </strike> </strong>
			</tt> </u> [
				adopt token
			]
			</applet> </marquee> </object> [
				either find-in-scope :token/2 [
					close-thru :token/2
					if mark: find/tail active-formatting-elements issue! [
						remove/part active-formatting-elements mark
					]
				][
					report 'end-tag-too-early token/2
				]
			]
			tag [
				reconstruct-formatting-elements
				push append-element token
				if find token 'self-closing [
					pop-element
				]
			]
			end-tag [
				close-element token
			]
			end [
				foreach node open-elements [
					unless find [dd dt li p tbody td tfoot th thead tr body html] node/name [
						report 'expected-closing-tag-but-got-eof
						break
					]
				]
				finish-up
			]
			comment [append-comment token]
		]

		text: [
			"In Text"
			space text [append-text token]
			end-tag [
				; possible alt <script> handler here
				pop-element
				use :return-state
				return-state: _
			]
			end [
				use :return-state
				return-state: _
			]
			comment [append-comment token]
		]

		in-table: [
			"In Table"
			space text [
				either find [table tbody tfoot thead tr] current-node/name [
					insert pending-table-characters: make block! 4 ""
					use/return in-table-text
					do-token token
				][
					do-else token
				]
			]
			doctype [
				report 'unexpected-doctype
			]
			<caption> [
				clear-stack-to-table
				push-formatting #caption
				push append-element token
				use in-caption
			]
			<colgroup> [
				clear-stack-to-table
				push append-element token
				use in-column-group
			]
			<col> [
				clear-stack-to-table
				push append-element [tag colgroup]
				use in-column-group
				do-token token
			]
			<tbody> <tfoot> <thead> [
				clear-stack-to-table
				push append-element token
				use in-table-body
			]
			<td> <th> <tr> [
				clear-stack-to-table
				push append-element [tag tbody]
				use in-table-body
				do-token token
			]
			<table> [
				report 'table-in-table
				if find-in-scope/scope table table [
					close-thru table
					reset-insertion-mode
					do-token token
				]
			]
			<style> <script> <template> [
				do-token/in token in-head
			]
			<input> [
				either select any [token/3 []] "type" "hidden" [
					; error
					append-element token
					; acknowledge-self-closing-flag token
				][
					do-else token
				]
			]
			<form> [
				; error
				unless any [
					select-element open-elements template
					document/form
				][
					document/form: append-element token
				]
			]
			</table> [
				either find-in-scope/scope table table [
					close-thru table
					reset-insertion-mode
				][
					report 'no-table-in-scope
				]
			]
			</body> </caption> </col> </colgroup> </html> </tbody> </td> </tfoot> </th> </thead> </tr> [
				; error
			]
			</template> [
				do-token/in token in-head
			]
			end [
				do-token/in token in-body
			]
			tag end-tag else [
				; error
				fostering?: on
				do-token/in token in-body
				fostering?: off
			]
			comment [append-comment token]
		]

		in-table-text: [
			"In Table Text"
			space text [
				append pending-table-characters token
			]
			doctype tag end-tag comment end [
				either find next pending-table-characters string! [
					report 'needs-fostering
					do-else/in rejoin pending-table-characters in-table
					pending-table-characters: _
					use :return-state
					do-token token
				][
					append-text rejoin pending-table-characters
					use :return-state
					do-token token
				]
			]
		]

		in-caption: [
			"In Caption"
			<caption> <col> <colgroup> <tbody> <td> <tfoot> <th> <thead> <tr>
			</table> [
				either find-in-scope/scope caption table [
					generate-implied-end-tags/thru caption
					pop-formatting #caption
					use in-table
					do-token token
				][
					; error
				]
			]
			</caption> [
				either find-in-scope/scope caption table [
					generate-implied-end-tags/thru caption
					pop-formatting #caption
					use in-table
				][
					; error
				]
			]
			</body> </col> </colgroup> </html> </tbody> </td> </tfoot> </th> </thead> </tr> [
				; error
			]
			space text doctype tag end-tag comment end [
				do-token/in token in-body
			]
		]

		in-column-group: [
			"In Column Group"
			space [
				append-text token
			]
			doctype [
				report 'unexpected-doctype
			]
			<html> end [
				do-token/in token in-body
			]
			<col> [
				append-element token
				; acknowledge-self-closing-tag
			]
			</colgroup> [
				either current-node/name = 'colgroup [
					pop-element
					use in-table
				][
					; error
				]
			]
			</col> [
				; error
			]
			<template> </template> [
				do-token/in token in-head
			]
			text tag end-tag []
			comment [append-comment token]
		]

		in-table-body: [
			"In Table Body"
			<tr> [
				clear-stack-to-table/body
				push append-element token
				use in-row
			]
			<th> <td> [
				; error
				clear-stack-to-table/body
				push append-element [tag tr]
				use in-row
				do-token token
			]
			</tbody> </tfoot> </thead> [
				either find-in-scope/scope :token/2 table [
					clear-stack-to-table/body
					pop-element
					use in-table
				][
					; error
				]
			]
			<caption> <col> <colgroup> <tbody> <tfoot> <thead>
			</table> [
				either find-in-scope/scope [tbody tfoot thead] table [
					clear-stack-to-table/body
					pop-element
					use in-table
					do-token token
				][
					; error
				]
			]
			</body> </caption> </col> </colgroup> </html> </td> </th> </tr> [
				; error
			]
			space text doctype tag end-tag comment end [
				do-token/in token in-table
			]
		]

		in-row: [
			"In Table Row"
			<th> <td> [
				clear-stack-to-table/row
				push append-element token
				use in-cell
				push-formatting #cell
			]
			<tr> [
				either find-in-scope/scope tr table [
					clear-stack-to-table/row
					pop-element
					use in-table-body
				][
					; error
				]
			]
			<caption> <col> <colgroup> <tbody> <tfoot> <thead> <tr>
			</table> [
				either find-in-scope/scope tr table [
					clear-stack-to-table/row
					pop-element
					use in-table-body
					do-token token
				][
					; error
				]
			]
			</tbody> </tfoot> </thead> [
				case [
					not find-in-scope/scope [tbody tfoot thead] table [
						; error
					]
					not find-in-scope/scope tr table []
					/else [
						clear-stack-to-table/row
						pop-element
						use in-table-body
						do-token token
					]
				]
			]
			</body> </caption> </col> </colgroup> </html> </td> </th> [
				; error
			]
			space text doctype tag end-tag comment end [
				do-token/in token in-table
			]
		]

		in-cell: [
			"In Table Cell"
			</td> </th> [
				either find-in-scope/scope :token/2 table [
					generate-implied-end-tags/thru [td th]
					pop-formatting #cell
					use in-row
				][
					; error
				]
			]
			<caption> <col> <colgroup> <tbody> <td> <tfoot> <th> <thead> <tr> [
				either find-in-scope/scope [td th] table [
					generate-implied-end-tags/thru [td th]
					pop-formatting #cell
					use in-row
					do-token token
				][
					; error
				]
			]
			</body> </caption> </col> </colgroup> </html> [
				; error
			]
			</table> </tbody> </tfoot> </thead> </tr> [
				either find-in-scope/scope :token/2 table [
					generate-implied-end-tags/thru [td th]
					pop-formatting #cell
					use in-row
					do-token token
				][
					; error
				]
			]
			space text doctype tag end-tag comment end [
				do-token/in token in-body
			]
		]

		in-select: [
			"In Select"
			space text [
				append-text token
			]
			doctype [
				report 'unexpected-doctype
			]
			<html> [
				do-token/in token in-body
			]
			<option> [
				if current-node/name = 'option [
					pop-element
				]
				push append-element token
			]
			<optgroup> [
				if find [option optgroup] current-node/name [
					pop-element
				]
				push append-element token
			]
			</optgroup> [
				if all [
					current-node/name = 'option
					open-elements/2/name = 'optgroup
				][
					pop-element
				]
				either current-node/name = 'optgroup [
					pop-element
				][
					; error
				]
			]
			</option> [
				either current-node/name = 'option [
					pop-element
				][
					; error
				]
			]
			</select> [
				either find-in-scope/scope select select [
					close-thru select
					reset-insertion-mode
				][
					; error
				]
			]
			<select> [
				; error
				if find-in-scope/scope select select [
					close-thru select
					reset-insertion-mode
				]
			]
			<input> <keygen> <textarea> [
				; error
				if find-in-scope/scope select select [
					close-thru select
					reset-insertion-mode
					do-token token
				]
			]
			<script> <template> </template> [
				do-token/in token in-head
			]
			end [
				do-token/in token in-body
			]
			tag end-tag [
				; error
			]
			comment [append-comment token]
		]

		in-select-in-table: [
			"In Select (In Table)"
			<caption> <table> <tbody> <tfoot> <thead> <tr> <td> <th> [
				; error
				close-thru select
				reset-insertion-mode
				do-token token
			]
			</caption> </table> </tbody> </tfoot> </thead> </tr> </td> </th> [
				; error
				if find-in-scope/scope :token/2 table [
					clear-thru select
					reset-insertion-mode
					do-token token
				]
			]
			space text doctype tag end-tag comment end [
				do-token/in token in-select
			]
		]

		after-body: [
			"After Body"
			space <html> [
				do-token/in token in-body
			]
			doctype [
				report 'unexpected-doctype
			]
			</html> [
				use after-after-body
			]
			end [
				finish-up
			]
			text tag end-tag [
				; error
				use body
				do-token token
			]
			comment [
				append-comment/to token last open-elements
			]
		]

		in-frameset: [
			"In Frameset"
			space [
				append-text token
			]
			doctype [
				report 'unexpected-doctype
			]
			<html> [
				do-token/in token body
			]
			<frameset> [
				push append-element token
			]
			</frameset> [
				either current-node/name = 'html [
					; error
				][
					pop-element
					unless current-node/name = 'frameset [
						use after-frameset
					]
				]
			]
			<frame> [
				append-element token
				; acknowledge-self-closing-flag
			]
			<noframes> [
				do-token/in token in-head
			]
			end [
				unless same? current-node last open-elements [
					; error
				]
				finish-up
			]
			text tag end-tag [
				; error
			]
			comment [append-comment token]
		]

		after-frameset: [
			"After Frameset"
			space [
				append-text token
			]
			doctype [
				report 'unexpected-doctype
			]
			<html> [
				do-token/in token in-body
			]
			</html> [
				use after-after-frameset
			]
			<noframes> [
				do-token/in token in-head
			]
			end [
				finish-up
			]
			text tag end-tag [
				; error
				use body
				do-token token
			]
			comment [
				append-comment token
			]
		]

		after-after-body: [
			"After After Body"
			space doctype <html> [
				do-token/in token in-body
			]
			end [
				finish-up
			]
			text tag end-tag [
				; error
				use in-body
				do-token token
			]
			comment [
				append-comment/to token document
			]
		]

		after-after-frameset: [
			"After After Frameset"
			space doctype <html> [
				do-token/in token in-body
			]
			end [
				finish-up
			]
			<noframes> [
				do-token/in token in-head
			]
			text [
				report 'expected-eof-but-got-char
			]
			tag [
				report 'expected-eof-but-got-start-tag
			]
			end-tag [
				report 'expected-eof-but-got-end-tag
			]
			comment [
				append-comment/to token document
			]
		]
	]

	count-of: func [string [string!] /local lines chars mark last-mark][
		lines: 0
		mark: head string

		loop-until [
			last-mark: :mark
			increment lines
			any [
				not mark: find next mark newline
				negative? offset-of mark string
			]
		]

		chars: offset-of last-mark string

		rejoin ["(" lines "," chars ")"]
	]
  verbose: true
	report: func [
		type [word! string!]
		; info
	][
		also type if verbose [print unspaced ["** " count-of html-tokenizer/series ": " type]
	]]

	current-state-name: current-state: return-state: state: last-state-name: token: _

	use: func ['target [word!] /return][
		last-state-name: :current-state-name
		if return [return-state: :current-state-name]
		current-state-name: target
		; probe rejoin [<state: > target]
		; probe token
		state: current-state: any [
			select states :target
			do make error! rejoin ["No Such State: " uppercase form target]
		]
		state
	]

	do-token: func [this [block! char! string!] /in 'other [word!] /local target operative-state][
		operative-state: _

		if word? :other [
			either find states other [
				operative-state: select states other
			][
				do make error! rejoin ["No such state: " to tag! uppercase form other]
			]
		]

		current-node: pick open-elements 1
		state: any [:operative-state state]

		target: case [
			char? token ['space]
			any [string? this char? this]['text]
			not block? this [do make error! "Not A Token"]
			all [
				this/1 = 'tag
				find state target: tagify this/2
			][target]
			all [
				this/1 = 'end-tag
				find state target: tagify/close this/2
			][target]
			this [this/1]
		]

		token: also token (
			token: :this
			switch :target state
		)

		state: current-state

		_
	]

	do-else: func [this [block! char! string!] /in 'other [word!] /local operative-state][
		operative-state: _

		if word? :other [
			either find states other [
				operative-state: select states other
			][
				do make error! rejoin ["No such state: " to tag! uppercase form other]
			]
		]

		state: any [:operative-state state]
		current-node: pick open-elements 1

		token: also token (
			token: :this
			switch 'else state
		)

		state: :current-state

		_
	]

	load-html: func [
			source [string! binary! file!]
      /quiet
		][
		if file? source [source: read source]
		if binary? source [source: smart-decode-text source]
    if quiet [set 'verbose false]
		open-elements: make block! 12
		active-formatting-elements: make block! 6
		last-token: _
		insertion-point: document: trees/new
		document/head: document/body: document/form: _
		insertion-type: 'append

		current-state-name: current-state: return-state: state: last-state-name: _

		use initial

		html-tokenizer/init source ; /
		func [current [block! char! string!]][
			do-token token: :current
		] ; /
		func [type [word! string!]][
			report :type html-tokenizer/series
		]

		html-tokenizer/start

		document
	]
]

load-html: :html-loader/load-html

list-elements: function [node [map! block!]][
	tags: references/tags
	print "LIST ELEMENTS:"
	trees/walk node [
		this: :node
		print to path! reverse collect [
			while [this/type <> 'document][
				keep either this/type = 'element [
					this/name
				][
					any [
						tags/(this/type)
						this/type
					]
				]
				this: this/parent
			]
		]
	]
]

is-empty?: function [t [any-string!]] [
	any [ find [
		"area" "base" "br" "col" "embed" "hr" "img" "input"
		"keygen" "link" "meta" "param" "source" "track" "wbr"
	] t | find "!?" t/1 ]
]

mold-style: function [
		x [block! string!]
	][
	if string? x [x] else [
		delimit map-each [k v] x [
			unspaced [k ":" space v]
		] "; "
	]
]

mold-html: function [
		x [block!]
		/into ret
	][
	if not x [return x]
	ret: default [make string! 256]
	switch x/type [
		comment [
			append ret "<!--"
			append ret x/value
			append ret "-->"
		]
		document [
			append ret "<html>"
			mold-html/into x/head ret
			mold-html/into x/body ret
			append ret "</html>"
		]
		element [
			append ret "<"
			append ret name: to-string x/name
			empty: is-empty? name
			attrib: x/value
			for-each k attrib [
				append ret unspaced [
					" " k "=" quote-string copy attrib/:k
				]
			]
			if empty [append ret " /"]
			append ret ">"
			x: select x 'first
			while [x] [
				mold-html/into x ret
				x: select x 'next
			]
			if not empty [
				append ret to-tag unspaced ["/" name]
			]
		]
		text [append ret x/value]
	] else [
		print ["!! unhandled type:" x/type]
	]
	ret
]

; vim: set sw=2 ts=2 sts=2:
