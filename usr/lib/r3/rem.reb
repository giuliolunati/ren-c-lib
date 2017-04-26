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
  unless (maybe [
    char! any-string! any-number! block!
  ] :v) [leave]
  unless block? v [v: reduce [%.txt v]]
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

rem: make object! [
  this: self
  ;; available with /SECURE:
  space: :lib/space
  func: :lib/func

  rem-tag: function [
      tag [word!]
      empty [logic!]
      args [any-value! <...>]
      :look [any-value! <...>]
    ][
    buf: make block! 4
    class: id: style: _
    while [t: first look] [
      case [
        all [word? t | #"." = first to-string t] [
          take look
          class: default [make block! 4]
          append class to-word next to-string t
        ]
        refinement? t [
          take look
          t: to-issue t
          dot-append buf [t take args]
          ; ^--- for non-HTML applications:
          ; value of an attribute may be a node!
        ]
        set-word? t [
          take look
          t: to-word t
          unless style [style: make block! 16]
          dot-append style [t take args]
        ]
        issue? t [
          take look
          id: next to-string t
        ]
        maybe [url! file!] t [
          take look
          dot-append buf [
            either/only tag = 'a #href #src
            :t
          ]
        ]
        true [break]
      ]
    ]
    case/all [
      id [dot-append buf [#id id]]
      style [dot-append buf [#style style]]
      class [dot-append buf [#class form class]]
    ]
    either empty [
      tag: append to-tag tag "/"
    ][
      tag: to-tag tag
      case [
        block? t [t: node take look]
        string? t [take look]
        maybe [word! path!] t [
          t: take args
          if all [block? t | not dot? t] [
            ;; REM block -> DOT block!
            t: node t
          ]
        ]
      ]
      dot-append buf :t
    ]
    case [
      empty? buf [buf: _]
      all [2 = length buf | %.txt = buf/1] [
        buf: buf/2
      ]
    ]
    reduce [tag buf]
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
    meta hr br img
  ]
  def-tags/bind [
    doc header title style script body
    div h1 h2 h3 h4 h5 h6 p
    span a b i
    table tr td
  ]
]

load-rem: function [
    x [block! string! file! url!]
    /secure
  ][
  if string? x [x: reduce [x]]
  unless block? x [x: load x]
  x: bind/(either secure ['new] [_]) x rem
  rem/node x
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
