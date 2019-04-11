REBOL [
  Name: dot
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "DOcument Tree"
  Exports: [
  ]
]

add-attribute: func [
  target key value
] [
  target: default [make block! 2]
  if 2 = length-of target [
    new-line head target true
    new-line tail target true
  ]
  append/only target key
  append/only target value
  if 2 < length-of target [
    new-line tail target true
  ]
  target
]

add-content: adapt ;\
  specialize :add-attribute [key: 'content]
  [value: blockify value]

add-list: func [list node] [
  if 1 = length-of list [
    new-line head list true
    new-line tail list true
  ]
  append/only list node
  if 1 < length-of list [new-line tail list true]
  list
]

add-property: :add-attribute

make-element: function [
		"Makes an element node"
		name [word!]
	][
	to-group reduce ['element name]
]

make-list: func [] [
  make block! 2
]

make-style: :make-list

make-text: func [
		"Makes a text node with value VALUE."
		value [char! any-string! any-number!]
	][
  to-group reduce ['text to-text value]
]

post-process: function [
  "Expand '--"
  tok [quoted! block!]
][
  a: e: _
  stack: make block! 2

  parse tok [any
    [ set e set-word! copy a [any [path! skip]]
      (append/only stack flatten/deep reduce [to-get-word e e a])
    | get-word! (take/last stack)
    | remove '-- (t: last stack) insert t
    | skip
    ]
  ]
  tok
]
    
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
