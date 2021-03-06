vim: set syn=rebol:
REBOL [
	Title: "XML for REBOL 3"
	File: %load-html.reb
	Name: 'load-html
	Author: "Christopher Ross-Gill"
	Purpose: "XML handler for Rebol v3"
	Comment: http://www.ross-gill.com/page/XML_and_REBOL
	Date: 22-Oct-2009
	Version: 0.3.0
	Type: 'module
	History: [0.3.0 16-Feb-2013]
	Exports: [load-html decode-html]
]
word: use [w1 w+] [
	w1: charset [ "ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" -#"^(02FF)" #"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)" #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)" ]
	w+: charset [ "-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" #"^(B7)" #"^(C0)" -#"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(203F)" - #"^(2040)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)" #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)" ]
	[w1 any w+]
]
decode-html: use [nm hx ns entity char] [
	nm: charset "0123456789" hx: charset "0123456789abcdefABCDEF" ns: make map! ["lt" 60 "gt" 62 "amp" 38 "quot" 34 "apos" 39]
	entity: [
		"&" [ ; should be #"&" 
			#"#" [ #"x" copy char 2 4 hx ";" (char: to-integer to-issue char)
				| copy char 2 5 nm ";" (char: to-integer char)
			] | copy char word ";" (char: any [ns/:char 63])
		] (char: to-char char)
	]
	func [text [string! none!]] [
		either text [ if parse/all text [any [remove entity insert char | skip]][text] ][copy ""]
	]
]
load-html: use [
		html! doc make-node name-to-tag is-tag is-attr space
		entity text name attribute element header content
	][
	html!: context [
		name: space: value: tree: branch: position: none
		flatten: use [
				html path emit encode form-name element attribute tag attr text
			][
			path: copy []
			emit: func [data] [repend html data]
			encode: func [text][
				parse/all text: copy text [
					some
						[ change #"<" "&lt;"
						| change #"^"" "&quot;"
						| change #"&" "&amp;"
						| skip
						]
				]
				head text
			]
			form-name: func [name [path!]][
				rejoin [
					either head? name
						[""]
						[append form first back name ":"]
					switch type?/word name/1 [
						tag! [to-string name/1]
						issue! [next to-string name/1]
					]
				]
			]
			attribute: [
				set attr is-attr
				set text [any-string! | number! | logic!]
				(	attr: form-name attr
					emit [" " attr {="} encode form text {"}]
				)
			]
			element:
				[	set tag is-tag
					( insert path tag: form-name tag
						emit ["<" either head? tag [tag][]]
					)
					[	none! (emit " />" remove path)
						| set text string!
							(	emit [">" encode form text "</" tag ">"]
								remove path
							)
						| and block! into [
							any attribute
							[ end (emit " />" remove path)
							| (emit ">")
								some element end
								(emit ["</" take path ">"])
							]
							]
					]
					| %.txt set text string! (emit encode form text)
					| attribute
				]
			does [
				html: copy ""
				if parse tree element [html]
			]
		]
		find-element: func [
				element [tag! issue! datatype! word!]
				/local hit
			][
			parse value [
				any [
					and path! hit: into [element] break
					| (hit: none) skip
				]
			] hit
		]
		get-by-tag: func [
				tag [tag! issue!] /local rule hits hit
			][
			hits: copy [] tree
			parse tree rule: [
				some [
					opt [
						hit: and path! into [tag] skip
						(append hits make-node hit)
						:hit
					]
					skip [and block! into rule | skip]
				]
			] hits
		]
		get-by-id: func [id /local rule at hit][
			parse tree rule: [
				some [
					hit: tag! and block! into [thru #id id to end]
					return (hit: make-node hit)
					| skip [and block! into rule | skip]
				]
			] hit
		]
		text: has [rule text part][
			case/all [
				string? value [text: copy value]
				block? value [ parse value rule: [
						any [
								[%.txt | is-tag]
								set part string!
								(append any [text text: copy ""] part)
							| skip and block! into rule
							| 2 skip
						]
				] ]
				string? text [trim/auto text]
			]
		]
		get: func [name [issue! tag!] /local hit pos][
			if parse tree [
				is-tag
				and block! into [
					any [
							pos: and path! into [name]
							[	block! (hit: make-node pos)
							| set hit skip
							]
							to end
						|
							[is-tag | is-attr | file!] skip
					]
				]
			] [hit]
		]
		sibling: func [/before /after][
			case [ all [after parse after: skip position 2 [[file! | is-tag] to end]][ make-node after ] all [before parse before: skip position -2 [[file | is-tag] to end]][ make-node before ] ]
		]
		parent: has [branch] ["Need Branch" none]
		children: has [hits hit][
			hits: copy [] parse case [ block? value [value] string? value [reduce [%.txt value]] none? value [[]] ][ any [is-attr skip] any [hit: [is-tag | file!] skip (append hits make-node hit)] ] hits
		]
		attributes: has [hits hit][
			hits: copy [] parse either block? value [value][[]] [ any [hit: is-attr skip (append hits make-node hit)] to end ] hits
		]
		clone: does [make-node tree]
		append-child: func [name data /attr /local pos][
			case [
				none? position/2
					[value: tree/2: position/2: copy []]
				string? position/2
					[ new-line value: tree/2: position/2: compose [%.txt (position/2)] true ]
			]
			either attr
				[ parse position/2 [
					any [into [issue!] skip] pos:
				] ]
				[ pos: tail position/2 ]
			insert pos reduce [name data]
			new-line pos true
		]
		append-text: func [text][
			case [
				none? position/2
					[value: tree/2: position/2: text]
				string? position/2
					[append position/2 text]
				%.txt = pick tail position/2 -2
					[append last position/2 text]
				block? position/2
					[append-child %.txt text]
			]
		]
		append-attr: func [name value][append-child/attr name value ]
	]
	doc: make html! [
		branch: make block! 10
		document: true
		new: does [clear branch tree: position: reduce ['document none]]
		open-tag: func [tag][
			insert/only branch position
			tag: name-to-tag tag
			tag/1: to-tag tag/1
			tree: position: append-child tag none
		]
		close-tag: func [tag][
			tag: name-to-tag tag
			tag/1: to-tag tag/1
			while [tag <> position/1][
				probe reform ["No End Tag:" position/1]
				if empty? branch [make error! "End tag error!"]
				take branch
			]
			tree: position: take branch
		]
	]
	is-tag: [and path! into [tag!]]
	is-attr: [and path! into [issue!]]
	name-to-tag: func [name [string!]][
		back tail to-path replace name ":" " "
	]
	make-node: func [here /base][
		make either base [doc] [html!][ position: here name: here/1 space: all [path? name not head? name pick head name 1] value: here/2 tree: reduce [name value] ]
	]
	space: use [space] [space: charset "^-^/^M " [some space] ]
	name: [word opt [":" word]]
	entity: use [nm hx][ nm: charset "0123456789" hx: charset "0123456789abcdefABCDEF" [#"&" [word | #"#" [1 5 nm | #"x" 1 4 hx]] ";" | #"&"] ]
	text: use [mk char value][ intersect charset ["^-^/^M" #" " - #"^(FF)"] complement charset [#"^(00)" - #"^(20)" "& <"] char: charset ["^-^/^M" #"^(20)" - #"^(25)" #"^(27)" -#"^(3B)" #"^(3D)" - #"^(FFFF)"]  [ copy value [ opt space [char | entity] any [char | entity | space] ] (doc/append-text decode-html value) ] ]
	attribute: use [attr value][ [ opt space copy attr name opt space "=" opt space [ {"} copy value to {"} | {'} copy value to {'} ] skip ( attr: name-to-tag attr attr/1: to-issue attr/1 doc/append-attr attr decode-html value ) ] ]
	element: use [tag value][
		[ #"<" [ copy tag name (doc/open-tag tag) any attribute opt space [ "/>" (doc/close-tag tag) | #">" content "</" copy tag name (doc/close-tag tag) opt space #">" ] | #"!" [ "--" copy value to "-->" 3 skip  (doc/append-child %.cmt value) | "[CDATA[" copy value to "]]>" 3 skip (doc/append-text value)  (doc/append-child %.bin value) ] ]
		]
	]
	header: [ any [ space | "<" ["?html" thru "? >" | "!" ["--" thru "-->" | thru ">"] | "?" thru "?>"] ] ]
	content: [any [text | element | space]]
	load-html: func [ "Transform an XML document to a REBOL block"
			document [any-string!] "An XML string/location to transform"
			/dom "Returns an object with DOM-like methods to traverse the XML tree"
			/local root
		][
		case/all [
			any [file? document url? document]
				[document: read/string document]
			binary? document
				[document: to-string document]
		]
		root: doc/new parse/all/case document [header element to end]
		doc/tree: any [root/document []]
		doc/value: doc/tree/2
		either dom
			[make-node/base doc/tree]
			[doc/tree]
	]
]
