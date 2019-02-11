REBOL [
  Name: rem
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "REbol Markup format"
]

dot: import 'dot

;smt: import 'smart-text

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
    node: dot/make-element name
    attributes: class: id: style: _
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
          dot/add-attribute node ;\
            to-issue t
            take args
          ; ^--- for non-HTML applications:
          ; value of an attribute may be a node!
        ]
        set-word? t [
          take look
          v: take args
          if block? v [v: reduce v]
          style: default [dot/make-style]
          dot/add-property style to-word t v
        ]
        issue? t [
          take look
          id: next to-text t
        ]
        any [url? t file? t] [
          take look
          dot/add-attribute node ;\
            if find [a link] name ["href"]
            else ["src"]
            :t
        ]
        pair? t [
          take look
          if t/1 > 1
          [dot/add-attribute node "rowspan" to-integer t/1]
          if t/2 > 1
          [dot/add-attribute node "colspan" to-integer t/2]
        ]
        true [break]
      ]
    ]
    if id [dot/add-attribute node #id id]
    if style [dot/add-attribute node #style style]
    if class [dot/add-attribute node #class class]
    if empty [return node]
    switch type-of t [
      block! group! text! blank! [
        t: take look
      ]
      word! path! [
        t: take args
      ]
    ]
    if text? t [
      t: maybe-process-text t
    ] else [
      t: to-node-list :t
    ]
    dot/add-content node t
    node
  ]

  to-node-list: function [x] [
    x: default [copy []]
    block? x or [x: to-block x]
    list: dot/make-list
    while [x: try evaluate/set x 't] [
      if text? :t [
        t: maybe-process-text t
      ]
      if any [char? :t any-string? :t any-number? :t]
      [ t: dot/make-text t ]
      dot/add-list list t
    ]
    list
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
  smart-text: attempt[:smt/smart-text]
  process-text: false
  raw-text: function [x] [reduce [%.txt x]]
  maybe-process-text: func [x [text!]] [
    case [
      :process-text = true [smart-text/inline x]
      action? :process-text [process-text x]
      true [dot/make-text x]
    ]
  ]

  reset: func[] [process-text: false]

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
    ;; preprocess strings:
    ;; ^ -> ^^
    ;; \\ -> \
    ;; \(..) -> ^(..)
    ;; \" -> ^"
    ;; \{ -> ^{ 
    ;; \} -> ^} 
    x: copy x
    string-begin: charset {"^{} ;}
    dquo-spec: charset {^^"\}
    bra-spec: charset {^^{}\}
    escapable: charset {{"}(} ;)
    n: 0
    parse x [any [
      to string-begin
      [ {"} any [
          [to dquo-spec | to end]
          [ {^^} insert {^^}
          | and {"} break
          | and ["\" escapable]
            change skip "^^" skip
          | "\" remove "\"
          | skip
          ]
        ] skip 
      | "{" (n: 1) any [ ; }
          if (n > 0)
          [to bra-spec | to end]
          [ {^^} insert {^^}
          | "{" (n: me + 1)
          | "}" (n: me - 1)
          | and ["\" escapable]
            change skip "^^" skip
          | "\" remove "\"
          | skip
          ]
        ]
      ]
    ] to end ]
    x: load x
  ]
  x: bind/(if secure ['new] else [_]) x rem
  rem/to-node-list x
]

test-me: function [] [
  ?? load-rem [
    p /class "my" bg: "pink" ["normal" br i _ b "bold"]
  ]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
