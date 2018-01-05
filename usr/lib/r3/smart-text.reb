REBOL [
  Name: 'smart-text
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "Smart Text format"
]

dot: import 'doc-tree
append-existing: :dot/append-existing

element: function ["Make a non-empty element."
    name [word!]
    content [block! string!]
  ][
  node: dot/make-element name false
  append-existing node content
  node
]

br: func ["Make a BR node"] [dot/make-element 'br true]

b: specialize 'element [name: 'b]
i: specialize 'element [name: 'i]
sup: specialize 'element [name: 'sup]
sub: specialize 'element [name: 'sub]


smart-text: function [x] [
  x: copy x
  c: t: _
  node: dot/make-node
  replace/all x "--" "—"
  replace/all x "->" "^(2192)" ; right arrow
  replace/all x "=>" "^(21d2)" ; right double arrow
  bs: [p: (p: back p) :p]
  get-markdown: [
    bs spacer set c skip
    copy v: [any [
      [to xchar | to end]
      [ remove "\" skip
      | and c break
      | skip
      ]
    ]] skip
  ]
  spacer: charset " ^-^/"
  xchar: charset "*/^^_`\^/"
  parse x [any [
    copy v: [to xchar | to end]
    (if v > "" [append-existing node v])
    [; xchar
    remove "\^/"
    | remove "\" set c: skip
      (append-existing node c)
    | newline
      (append-existing node br)
    | and "/" get-markdown
      (append-existing node i v)
    | copy c: [skip spacer]
      (append-existing node c)
    | and "*" get-markdown
      (append-existing node b v)
    | and "^^" get-markdown
      (append-existing node sup v)
    | and "_" get-markdown
      (append-existing node sub v)
    | and "`" get-markdown
      (append-existing node unspaced ["`" v "`"])
    | set v xchar
      (append-existing node v)
    ]
  ]]
  node
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
