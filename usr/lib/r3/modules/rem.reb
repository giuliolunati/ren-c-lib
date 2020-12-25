REBOL [
  Name: rem
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "REbol Markup format"
]
dot: import 'dot
text: import 'text

;;; GLOBALS ;;;
t: w: x: pos: _

;;; RULES ;;;

empty-lines: [newline some [
  any hspace newline
]]

ch-mark: charset "*_"

marker: [set t ch-mark opt t]

hspace: charset " ^-"
wspace: union hspace charset "^J^L^M"

xchar: union ch-mark union wspace charset "{\"

tchar: complement xchar

text-after: p: _
text-before: false

map-mark: make map! [
  #"*" b #"_" i
]

stack: make block! 2

push: function [x [word!]] [
  either find stack x [false]
  [append stack x true]
]

pop: function [x [word!]] [
  either x = last stack
  [take/last stack true]
  [false]
]

open-mark: [p:] close-mark: [:p]

wchar: charset [#"A" - #"Z" #"a" - #"z" "-_"]

take-last-word: function [x [text!]] [
  if empty? x [return false]
  x: tail x
  while [not head? x] [
    x: back x
    if find wchar x/1 [x continue]
    x: next x
    break
  ]
  if tail? x [x: head x return false]
  to-word take/part x tail x
  elide [x: head x]
]

output: make block! 2
append/only output make block! 2

emit: func [x] [
  if (text? x) and [text? last last output]
  [ append last last output x ]
  else [append last output x]
]

rules: [(text-before: false) any 
  [ p: empty-lines (emit lit --)
    (text-before: false)
  | newline (emit 'br)
    (text-before: false)
  | copy t [some hspace] 
    (emit t) (text-before: false)
  | p: some ch-mark
    [ tchar (text-after: true)
    | (text-after: false)
    ] :p
    [ :(text-after and [not text-before])
      some [copy t marker
        :(push t: map-mark/(t/1))
        (emit to-set-word t)
      ]
    | :(text-before and [not text-after])
      some [ copy t marker
        :(pop t: map-mark/(t/1))
        (emit to-get-word t)
      ]
    | :(text-before = text-after)
      some [ copy t marker
        :(if 1 < length-of t [
          t: map-mark/(t/1)
          did case [
            push t [t: to-set-word t]
            pop t [t: to-get-word t]
          ]
        ])
        (emit t)
      ]
    ]
  | "\" set t skip
    (emit to-text t) 
    (text-before: not did find wspace t)
  | copy t [to xchar | to end]
    [ "{"
      [:(did w: take-last-word t)
        (emit t)
        copy t to "}" skip
        (emit tokenize system/contexts/user/:w t)
      | (emit join t "{")
      ]
    | (if not empty? t [emit t])
      (text-before: true)
    ]
  ]
]

tokenize: function [
    x [text! block! quoted!]
][
  if quoted? x [return eval x]
  append/only output make block! 2
  if text? x [
    p: parse x [rules]
    (tail? p) or [
    print [p] quit
      insert p: mutable p " ~~ "
      p: copy/part skip p -20 44
      print unspaced ["** Parse error at: ..." p "..."]
      quit
    ]
  ]
  if block? x [
    while [x: try evaluate/set x 't] [
      if block? :t [t: tokenize t]
      if text? :t [
        t: tokenize t
      ]
      if any [char? :t any-string? :t any-number? :t]
      [ t: to-text t ]
      if any [text? t quoted? t]
      [ append last output t ]
    ]
  ]
  uneval take/last output
]

rem: make object! [
  this: self
  ; declare some words, thus can use they later...
  b: br: i: sup: sub: meta: request: _
  ;; available with /SECURE:
  space: :lib/space
  func: :lib/func

  unit: function [x u] [unspaced [x u] ]
  pt: enfix specialize :unit [u: 'pt]
  px: enfix specialize :unit [u: 'px]
  em: enfix specialize :unit [u: 'em]
  ex: enfix specialize :unit [u: 'ex]
  mm: enfix specialize :unit [u: 'mm]
  cm: enfix specialize :unit [u: 'cm]

  rem-element: function [
      ;; WARNING: if change here, check specializations!
      name [word!]
      empty [logic!]
      args [any-value! <...>]
      :look [any-value! <...>]
  ][
    node: reduce [either empty [name] [to-set-word name]]
    class: id: _
    while [t: not tail? look] [
      t: first look
      if group? t [t: do t]
      case [
        all [word? t | #"." = first to-text t] [
          take look
          class: default [make block! 2]
          append class to-word next to-text t
        ]
        refinement? t [
          take look
          append node t append node take args
          ; ^--- for non-HTML applications:
          ; value of an attribute may be a node!
        ]
        set-word? t [
          take look
          v: take look
          append node to-path reduce
          [ _ t ]
          append/only node v
        ]
        issue? t [
          take look
          id: next to-text t
        ]
        any [url? t file? t] [
          take look
          append node either find [a link] name
          [/href] [/src]
          append node :t
        ]
        pair? t [
          take look
          if t/1 > 1 [
            append node /rowspan
            append node to-integer t/1
          ]
          if t/2 > 1 [
            append node /colspan
            append node to-integer t/2
          ]
        ]
        
      ] else [break]
    ]
    if id [append node /id append node :id]
    if class [append node /class append node :class]

    if not empty [
      switch type-of t [
        block! group! text! blank! [
          t: take look
        ]
        word! path! [
          t: take args
        ]
      ]
      t: tokenize t
      append node t
      append node to-get-word name
    ]
    uneval node
  ]

  def-empty-elements: func [
      return: [action!]
      elements [block!]
      /bind
    ][
    for-each element elements [
      if bind [element: lib/bind/new to-word :element this]
      set :element specialize 'rem-element [
        name: :element empty: true
      ]
    ]
  ]

  def-elements: func [
      return: [action!]
      elements [block!]
      /bind
    ][
    for-each element elements [
      if bind [element: lib/bind/new to-word :element this]
      set :element specialize 'rem-element [
        name: :element | empty: false
      ]
    ]
  ]

  def-empty-elements/bind [
    meta hr br img link input
  ]

  def-elements/bind [
    doc header title style script body
    div h1 h2 h3 h4 h5 h6 p
    span a b i sup sub
    table tr td
    button textarea
  ]
  viewport: func [content] [
    if any-number? content [
      content: unspaced ["initial-scale=" content]
    ]
    meta /name "viewport" /content content
  ]

  ;; smart-text
  raw-text: function [x] [reduce [%.txt x]]

  map-repeat: function [
      'w [word!]
      n [integer!]
      body [block!]
    ][
    o: make object! compose [(to-set-word :w) _]
    out: make block! 0
    bind body o
    repeat i n [
      o/:w: i append/only out do body
    ]
    out
  ]
]

load-rem: function [
    x [block! text! file! url! binary!]
    /secure
  ][
  if any [file? x url? x] [
    x: read/string x
  ]
  if binary? x [x: to-text x]
  if text? x [
    ; ""-strings:
    ;   "" -> "
    ;   newline -> ^newline
    ; all strings:
    ;   ^ -> ^^
    x: copy x
    string-begin: charset {"^{} ;}
    dquo-spec: charset {^^"^/}
    bra-spec: charset {^^{}}
    n: 0
    parse x [any [
      to string-begin
      [ {"} any [
          [to dquo-spec | to end]
          [ change {^/} {^^/}
          | and {""} change skip {^^} skip
          | and {"} break
          | {^^} insert {^^}
          ]
        ] skip 
      | "{" (n: 1) any [ ; }
          :(n > 0)
          [to bra-spec | to end]
          [ {^^} insert {^^}
          | "{" (n: n + 1)
          | "}" (n: n - 1)
          ]
        ]
      ]
    ] to end ]
    x: load x
  ]
  x: bind/(if secure ['new] else [_]) x rem
  x: eval tokenize x
  dot/post-process x
]

; vim: set et sw=2 :
