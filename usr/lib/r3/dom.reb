Rebol [
	Name: dom
	Type: module
	Title: "Document tree"

	Author: ["Christopher Ross-Gill" "Giulio Lunati"]
	Date: 24-Dec-2017
	File: %dom.reb
	Version: 0.1.0
	Rights: http://opensource.org/licenses/Apache-2.0
	History: [
		24-Dec-2017 0.2.0 "standalone module from rgchris' markup.reb"
	]
]

this: self

new: func ["Returns new empty document."] [
	new-line/all/skip copy [
		parent _ first _ last _ name _ public _ system _
		form _ head _ body _ type document length 0

	] true 2
]

make-node: func ["Returns new empty node."] [
	new-line/all/skip copy [
		parent _ back _ next _ first _ last _
		type _ name _ value _
		length 0 empty _
	] true 2
]

maybe-node?: func [
		"Check if X may be a node."
		x
	][
	if not block? x [return false]
	if all [
		x/1 = 'parent
		x/3 = 'back
		x/5 = 'next
		x/7 = 'first
		x/9 = 'last
		x/11 = 'type
		x/13 = 'name
		x/15 = 'value
	] [return true]
	false
]

insert-before: func [
		"Insert a new empty node before ITEM and return it."
		item [block! map!]
		/local node
	][
	node: make-node

	node/parent: item/parent
	node/back: item/back
	node/next: item

	either blank? item/back [
		item/parent/first: node
	][
		item/back/next: node
	]
  item/parent/length: 1 + item/parent/length

	item/back: node
]

insert-after: func [
		"Insert a new empty node after ITEM and return it."
		item [block! map!]
		/local node
	][
	node: make-node

	node/parent: item/parent
	node/back: item
	node/next: item/next

	either blank? item/next [
		item/parent/last: node
	][
		item/next/back: node
	]
  item/parent/length: 1 + item/parent/length

	item/next: node
]

insert: func [
		"Insert a new empty node as LIST/FIRST and return it."
		list [block! map!]
	][
	list/length: 1 + list/length
	either list/first [
		insert-before list/first
	][
		list/first: list/last: make-node
		elide list/first/parent: list
	]
]

append: func [
		"Append a new empty node as LIST/LAST and return it."
		list [block! map!]
	][
	list/length: 1 + list/length
	either list/last [
		insert-after list/last
	][
		insert list
	]
]

append-existing: func [
		"Append NODE as LIST/LAST and return it."
		list [block! map!]
		node [block! map! text! char!]
	][
	if any [text? node char? node] [node: make-text node]
	node/parent: list
	node/next: _
	list/length: 1 + list/length

	either blank? list/last [
		node/back: _
		list/first: list/last: node
	][
		node/back: list/last
		node/back/next: node
		list/last: node
	]
]

remove: func [
		"Removes ITEM from ITEM/PARENT or error."
		item [block! map!]
		/back "Returns ITEM/BACK instead of ITEM."
		/next "Returns ITEM/NEXT instead of ITEM."
	][
	unless item/parent [
		do make error! "Node does not exist in tree."
	]

	either item/back [
		item/back/next: item/next
	][
		item/parent/first: item/next
	]

	either item/next [
		item/next/back: item/back
	][
		item/parent/last: item/back
	]

  item/parent/length: item/parent/length - 1
	item/parent: item/back: item/next: _ ; node becomes freestanding

	case [
		back [item/back]
		next [item/next]
		/else [item]
	]
]

clear: func [
		"Removes all children from LIST."
		list [block! map!]
	][
	list/length: 0
	while [list/first] [remove list/first]
]

fix-length: func [
    "Fixes NODE/LENGTH and returns it."
		node [block! map!]
		/local n item
	][
	n: 0
	item: node/first
	loop-until [n: n + 1 not item: item/next]
  node/length: n
]

clear-from: func [
		"Removes ITEM and all subsequent siblings from ITEM/PARENT."
		item [block! map!]
		/local n p
	][
	p: item/parent
	n: p/length
	loop-until [n: me - 1 not item: remove item]
	p/length: n
]

walk: func [
		"Execute CALLBACK code for every descendant of NODE."
		node [block! map!]
		callback [block!]
		/into "TRUE when called recursively."
		/only "Do not recursion (children only)."
	][
	case bind compose/deep [
		only [
			node: node/first
			while [:node][
				(to group! callback)
				node: node/next
			]
		]
		/else [
			(to group! callback)
			node: node/first
			while [:node][
				walk/into node callback
				node: node/next
			]
		]
	] 'node
]

make-text: func [
		"Makes a text node with value VALUE."
		value [char! any-string! any-number!]
		/target node [block! map!] "Use existing node"
	][
	if not text? value [value: form value]
	node: default [make-node]
	node/type: 'text
	node/value: value
	node
]

make-element: func [
		"Makes an element node an sets NAME and EMPTY."
		name [word!]
		empty [logic!]
		/target node [block! map!] "Use existing node"
	][
	node: default [make-node]
	node/type: 'element
	node/name: name
	node/empty: empty
	node
]

mold-node: function [node [map! block!]][
	new-line/all/skip collect [
		switch node/type [
			'element _ [
				keep node/name
				either any [node/value node/first][
					keep/only new-line/all/skip collect [
						if node/value [
							keep %.attrs
							keep node/value
						]
						kid: node/first
						while [kid][
							keep mold-node kid
							kid: kid/next
						]
					] true 2
				][
					keep _
				]
			]
			'document [
				kid: node/first
				while [kid][
					keep mold-node kid
					kid: kid/next
				]
			]
			'text [
				keep %.txt
				keep node/value
			]
			'comment [
				keep %.comment
				keep to tag! rejoin ["!--" node/value "--"]
			]
		] else [
			keep _
			keep to tag! node/type
		]
	] true 2
]

append-pair-to-map: function [
    "If TARGET is blank, set it to MAP!, then set TARGET/KEY: VALUE."
    'target [word! set-word!]
    key
    value
  ][
  x: get target
  x: default [make map! 2]
  x/:key: value
  set target x
]

; vim: set sw=2 ts=2 sts=2:
