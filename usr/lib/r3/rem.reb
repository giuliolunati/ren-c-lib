REBOL [
  Name: 'rem
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "REbol Markup format"
  Exports: [
    def-empty-tags
    def-tags
    load-rem
    mold-rem
  ]
]

dot-append: proc [
    b [block!]
    v [any-value! <opt>]
  ][
  if not (maybe [
    char! any-string! any-number! block!
  ] :v) [leave]
  if not block? v [v: reduce [%.txt v]]
  v: reduce v
  for-skip v 2 [
    if lit-word? v/2 [v/2: to-word v/2]
    if maybe [any-word! any-string!] v/2 [v/2: form v/2]
  ]
  b: tail b
  append b v
  new-line b true
]

dot?: func [x] [
  all [block? x | maybe [tag! file!] x/1]
]

dot-toc: function [body toc] [
  for-each [k v] body [
    if all [tag? k | block? v] [
      if "toc" = select v #id [
        append v toc
        return true
      ]
      if t: dot-toc v toc [return t]
    ]
  ]
  return false
]

rem: make object! [
  this: self
  ;; available with /SECURE:
  space: :lib/space
  func: :lib/func

  macro: make block! 8
  count: toc: _

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

  rem-tag: function [
      tag [word!]
      empty [logic!]
      args [any-value! <...>]
      :look [any-value! <...>]
    ][
    buf: make block! 4
    class: id: style: _
    while [not tail? look] [
      t: apply 'look-first [look: args]
      case [
        all [word? t | #"." = first to-string t] [
          apply 'take-first [look: args]
          class: default [make block! 4]
          append class to-word next to-string t
        ]
        refinement? t [
          apply 'take-first [look: args]
          t: to-issue t
          dot-append buf [t apply 'take-eval [args: args]]
          ; ^--- for non-HTML applications:
          ; value of an attribute may be a node!
        ]
        set-word? t [
          apply 'take-first [look: args]
          t: to-word t
          if not style [style: make block! 16]
          dot-append style [t apply 'take-eval [args: args]]
        ]
        issue? t [
          apply 'take-first [look: args]
          id: next to-string t
        ]
        maybe [url! file!] t [
          apply 'take-first [look: args]
          dot-append buf [
            if find [a link] tag [#href]
            else [#src]
            :t
          ]
        ]
        get-word? t [
          apply 'take-first [look: args]
          attempt [append macro get to-word t]
        ]
        true [break]
      ]
    ]
    case/all [
      id [dot-append buf [#id id]]
      style [dot-append buf [#style style]]
      class [dot-append buf [#class form class]]
    ]
    if empty [
      tag: append to-tag tag "/"
    ] else [
      if 'body = tag [
        set 'toc make block! 8
        set 'count 1
      ]
      case [
        block? t [
          t: node
          apply 'take-first [look: args]
        ]
        string? t [
          apply 'take-first [look: args]
        ]
        maybe [word! path!] t [
          t: apply 'take-eval [args: args]
          if all [block? t | not dot? t] [
            ;; REM block -> DOT block!
            t: node t
          ]
        ]
      ]
      if string? t [
        switch/default tag [
          'script [t: reduce [%.js t]]
          'style [t: reduce [%.css t]]
        ][t: reduce [%.txt t]]
      ]
      if find [h1 h2 h3 h4 h5 h6] tag [
        if toc [
          dot-append toc
          reduce [
            (to-tag tag)
            reduce [
              <a> join-of reduce [
                #href join-of "#toc" count
              ] :t
            ]
          ]
        ]
        dot-append buf reduce [
          <a> [#id join-of "toc" ++ count]
        ]
      ]
      if 'body = tag [dot-toc :t toc]
      dot-append buf :t
    ]
    case [
      empty? buf [buf: _]
      all [2 = length buf | %.txt = buf/1] [
        buf: buf/2
      ]
    ]
    reduce [to-tag tag buf]
  ]
  node: function [x [block!]] [
    if not block? x [return x]
    buf: make block! 8
    while [not tail? x] [
      dot-append buf do/next x 'x
    ]
    buf
  ]
  def-empty-tags: func [
      return: [function!]
      tags [block!]
      /bind
    ][
    for-each tag tags [
      if bind [tag: lib/bind/new to-word :tag this]
      set :tag specialize 'rem-tag [
        tag: :tag | empty: true
      ]
    ]
  ]
  def-tags: func [
      return: [function!]
      tags [block!]
      /bind
    ][
    for-each tag tags [
      if bind [tag: lib/bind/new to-word :tag this]
      set :tag specialize 'rem-tag [
        tag: :tag | empty: false
      ]
    ]
  ]
  ; declare 'meta, thus can use it in viewport
  meta: _ 

  viewport: func [content] [
    if number? content [
      content: unspaced ["initial-scale=" content]
    ]
    meta /name "viewport" /content content
  ]
  def-empty-tags/bind [
    meta hr br img link
  ]
  def-tags/bind [
    doc header title style script body
    div h1 h2 h3 h4 h5 h6 p
    span a b i sup sub
    table tr td
  ]
]

load-rem: function [
    x [block! string! file! url!]
    /secure
  ][
  if string? x [x: reduce [x]]
  if not block? x [x: load x]
  x: bind/(if secure ['new] else [_]) x rem
  rem/node x
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
