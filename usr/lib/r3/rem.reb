REBOL [
  Name: 'rem
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "REbol Markup format"
]

dot: import 'doc-tree
+pair: enfix :dot/append-pair-to-map
append-existing: :dot/append-existing
make-node: :dot/make-node
make-element: :dot/make-element
make-text: :dot/make-text
maybe-node?: :dot/maybe-node?

smt: import 'smart-text
smart-text: :smt/smart-text

rem: make object! [
  this: self
  ; declare some words, thus can use they later...
  b: br: i: sup: sub: meta: _
  ;; available with /SECURE:
  space: :lib/space
  func: :lib/func
  ;; shortcuts
  macro: make block! 8
  look-first: function [
      :look [any-value! <...>]
    ][
    if empty? macro [first look]
    else [first macro]
  ]
  take-first: function [
      :look [any-value! <...>]
    ][
    if empty? macro [take look]
    else [take macro]
  ]
  take-eval: function [
      args [any-value! <...>]
    ][
    either empty? macro [take args]
    [do/next macro 'macro]
  ]
  macro-tail?: function [
      :look [any-value! <...>]
    ][
    if empty? macro [tail? look]
    else [false]
  ]
  ;; 
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
      t: apply 'look-first [look: args]
      case [
        all [word? t | #"." = first to-string t] [
          apply 'take-first [look: args]
          class: default [make block! 2]
          append class to-word next to-string t
        ]
        refinement? t [
          apply 'take-first [look: args]
          attributes: +pair ;\
            lock next to-string t
            apply 'take-eval [args: args]
          ; ^--- for non-HTML applications:
          ; value of an attribute may be a node!
        ]
        set-word? t [
          apply 'take-first [look: args]
          t: to-word t
          style: +pair t apply 'take-eval [args: args]
        ]
        issue? t [
          apply 'take-first [look: args]
          id: next to-string t
        ]
        maybe [url! file!] t [
          apply 'take-first [look: args]
          attributes: +pair ;\
            if find [a link] name ["href"]
            else ["src"]
            :t
        ]
        get-word? t [
          apply 'take-first [look: args]
          attempt [append macro get to-word t]
        ]
        true [break]
      ]
    ]
    if id [attributes: +pair "id" id]
    if style [attributes: +pair "style" style]
    if class [attributes: +pair "class" class]
    case [
      block? t [
        t: apply 'take-first [look: args]
      ]
      string? t [
        apply 'take-first [look: args]
      ]
      maybe [word! path!] t [
        t: apply 'take-eval [args: args]
      ]
    ]
    if string? t [
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
  node: to-node: function [x [block!]] [
    if maybe-node? x [return x]
    node: make-node
    while [not tail? x] [
      t: do/next x 'x
      if string? :t [
        t: maybe-process-text t
      ]
      if maybe [char! any-string! any-number!] :t
      [ t: make-text t ]
      if block? :t [
        append-existing node to-node t
      ]
    ]
    node
  ]
  def-empty-elements: func [
      return: [function!]
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
      return: [function!]
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
  viewport: func [content] [
    if number? content [
      content: unspaced ["initial-scale=" content]
    ]
    meta /name "viewport" /content content
  ]
  def-empty-elements/bind [
    meta hr br img link
  ]
  def-elements/bind [
    doc header title style script body
    div h1 h2 h3 h4 h5 h6 p
    span a b i sup sub
    table tr td
  ]
  ;; smart-text
  process-text: false
  raw-text: function [x] [reduce [%.txt x]]
  maybe-process-text: func [x [string!]] [
    case [
      :process-text = true [smart-text/inline x]
      any-function? :process-text [process-text x]
      true [make-text x]
    ]
  ]
  reset: func[] [process-text: false]
]

load-rem: function [
    x [block! string! file! url! binary!]
    /secure
  ][
  if maybe [file! url!] x [
    x: read/string x
  ]
  if binary? x [x: to-string x]
  if string? x [
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
