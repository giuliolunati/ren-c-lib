REBOL [
  Name: 'smart-text
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "Smart Text format"
]

dot: import 'doc-tree
append-existing: :dot/append-existing
make-node: :dot/make-node

text: import 'text
smart-decode-text: :text/smart-decode-text

element: function ["Make a non-empty element."
    name [word!]
    content [block! text! blank!]
  ][
  node: dot/make-element name false
  if content [append-existing node content]
  node
]

br: func ["Make a BR node"] [dot/make-element 'br true]

b: specialize 'element [name: 'b]
i: specialize 'element [name: 'i]
p: specialize 'element [name: 'p]
sup: specialize 'element [name: 'sup]
sub: specialize 'element [name: 'sub]

smart-text: function ["Convert SmartText to doc-tree."
    x [text! binary! file! url!]
    /inline "Don't make paragraphs, only BR."
  ][
  if not inline [body: make-node]
  if any [file? x url? x] [x: read x]
  if binary? x [x: smart-decode-text x]
  x: copy x
  c: t: _
  node: if inline [make-node] else [p _]
  replace/all x "--" "—"
  replace/all x "->" "^(2192)" ; right arrow
  replace/all x "=>" "^(21d2)" ; right double arrow
  bs: [pos: (pos: back pos) :pos]
  get-markdown: [
    bs [spacer | newline] set c skip
    copy v: [any [
      [to xchar | to end]
      [ remove "\" skip
      | and c break
      | skip
      ]
    ]] skip
  ]
  spacer: charset " ^-"
  xchar: charset "*/^^_`\^/"
  parse x [any [
    copy v: [to xchar | to end]
    (if v > "" [append-existing node v])
    [; xchar
    remove "\^/"
    | remove "\" set c: skip
      (append-existing node c)
    | newline [
      some
        [ any spacer newline
          (if inline [append-existing node br])
        ] 
        ( if inline [append-existing node br]
          else [
            append-existing body node
            node: p _
          ]
        )
      | (append-existing node br)
      ]
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
  if inline [body: node]
  else [append-existing body node]
  while [(body/length = 1) and (not body/type)] [body: body/first]
  body
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
