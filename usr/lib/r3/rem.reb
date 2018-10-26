REBOL [
  Name: rem
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "REbol Markup format"
]

dot: import 'dom
+pair: enfix :dot/append-pair-to-block
append-existing: :dot/append-existing
make-node: :dot/make-node
make-element: :dot/make-element
make-text: :dot/make-text
maybe-node?: :dot/maybe-node?

smt: import 'smart-text

rem: make object! [
  this: self
  ; declare some words, thus can use they later...
  b: br: i: sup: sub: meta: request: _
  ;; available with /SECURE:
  space: :lib/space
  func: :lib/func

  unit: function [#x u] [unspaced [x u] ]
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
    node: make-node
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
          attributes: +pair ;\
            lock next to-text t
            take args
          ; ^--- for non-HTML applications:
          ; value of an attribute may be a node!
        ]
        set-word? t [
          take look
          t: to-word t
          v: take args
          if block? v [v: reduce v]
          style: +pair t v
        ]
        issue? t [
          take look
          id: next to-text t
        ]
        any [url? t file? t] [
          take look
          attributes: +pair ;\
            if find [a link] name ["href"]
            else ["src"]
            :t
        ]
        pair? t [
          take look
          if t/1 > 1
          [attributes: +pair "rowspan" to-integer t/1]
          if t/2 > 1
          [attributes: +pair "colspan" to-integer t/2]
        ]
        true [break]
      ]
    ]
    if id [attributes: +pair "id" id]
    if style [attributes: +pair "style" style]
    if class [attributes: +pair "class" class]
    case [
      block? t [
        t: take look
      ]
      group? t [
        t: take look
      ]
      text? t [
        take look
      ]
      any [word? t path? t] [
        t: take args
      ]
    ]
    if text? t [
      t: maybe-process-text t
    ]
    if t [append-existing node to-node :t]
    case [
      empty? node [node: _]
      all [2 = length of node | %.txt = node/1] [
        node: node/2
      ]
    ]
    node/value: attributes
    make-element/target name empty node
  ]
  node: to-node: function [x] [
    block? x or [x: to-block x]
    if maybe-node? x [return x]
    node: make-node
    while [x: try evaluate/set x 't] [
      if text? :t [
        t: maybe-process-text t
      ]
      if any [char? :t any-string? :t any-number? :t]
      [ t: make-text t ]
      if block? :t [
        append-existing node to-node t
      ]
    ]
    node
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
  smart-text: :smt/smart-text
  process-text: false
  raw-text: function [x] [reduce [%.txt x]]
  maybe-process-text: func [x [text!]] [
    case [
      :process-text = true [smart-text/inline x]
      action? :process-text [process-text x]
      true [make-text x]
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
  rem/to-node x
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
