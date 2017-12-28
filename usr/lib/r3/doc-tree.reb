Rebol [
	Name: doc-tree
	Type: module
	Title: "Document tree"

	Author: ["Christopher Ross-Gill" "Giulio Lunati"]
	Date: 24-Dec-2017
	File: %doc-tree.reb
	Version: 0.1.0
	Rights: http://opensource.org/licenses/Apache-2.0
	History: [
		24-Dec-2017 0.2.0 "standalone module from rgchris' markup.reb"
	]
]

new: func ["Returns new empty document."] [
	new-line/all/skip copy [
		parent _ first _ last _ name _ public _ system _
		form _ head _ body _ type document length 0
	] true 2
]

make-node: func ["Returns new empty node."] [
	new-line/all/skip copy [
		parent _ back _ next _ first _ last _
		type _ name _ value _ length 0
	] true 2
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
		after list/first: list/last: make-node
		[ list/first/parent: list ]
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
		node [block! map!]
	][
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
	loop-until [n: ++ 1 not item: item/next]
  node/length: n
]

clear-from: func [
		"Removes ITEM and all subsequent siblings from ITEM/PARENT."
		item [block! map!]
		/local n p
	][
	p: item/parent
	n: p/length
	loop-until [n: -- 1 not item: remove item]
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

; vim: set sw=2 ts=2 sts=2:
