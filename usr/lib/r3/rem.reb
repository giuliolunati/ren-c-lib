REBOL [
  Name: 'rem
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "REbol Markup format"
  Exports: [load-rem mold-rem]
]

dot-append: proc [
  b [block!]
  v
  ][
  unless v [leave]
  unless block? v [v: reduce [%.txt v]]
  v: reduce v
  forskip v 2 [
    if lit-word? v/2 [v/2: to-word v/2]
    if any-word? v/2 [v/2: form v/2]
  ]
  b: tail b
  append b v
  new-line b true
]

rem: make object! [
  ;; available with /SECURE:
  space: :lib/space
  func: :lib/func

  doc: header: title: style: script: body:
  div: h1: h2: h3: h4: h5: h6: p:
  span: a: b: i:
  table: tr: td:
  'TAG

  meta: hr: br: img:
  'EMPTY-TAG

  rem-1: func [
      args [any-value! <...>]
      :look [any-value! <...>]
      id: class: style: node: t: w:
    ][
    w: first look
    if group? :w [take args return _]
    if any [path? :w all [word? :w
      'TAG != get :w 'EMPTY-TAG != get :w
    ] ] [return take args]
    unless word? :w [return take look]
    take look
    node: make block! 4
    class: id: style: _
    forever [
      t: first look
      if word? t [
        if #"." = first to-string t [ take look
          unless class [class: make block! 4]
          append class to-word next to-string t
          continue
        ]
        break
      ]
      if refinement? t [ take look
        t: to-word t
        dot-append node [t apply 'rem-1 [args: args look: look]]
        ; ^--- for non-HTML applications:
        ; value of an attribute may be a node!
        continue
      ]
      if set-word? t [ take look
        t: to-word t
        unless style [style: make block! 16]
        dot-append style [t take args]
        continue
      ]
      if issue? t [ take look
        id: next to-string t
        continue
      ]
      if any [url? t file? t] [ take look
        dot-append node [
          either/only w = 'a 'href 'src
          t
        ]
        continue
      ]
      break
    ]
    if id [dot-append node ['id id]]
    if style [dot-append node ['style style]]
    if class [dot-append node ['class form class]]
    either 'EMPTY-TAG = get :w [
      w: append to-tag w #"/"
    ][
      w: to-tag w
      case [
        block? t [
          t: make varargs! take look
          t: apply 'rem [args: t look: t]
        ]
        string? t [take look]
        any [word? t path? t] [
          t: apply 'rem-1 [args: args look: look]
        ]
      ]
      dot-append node t
    ]
    case [
      empty? node [node: _]
      all [2 = length node | %.txt = node/1] [
        node: node/2
      ]
    ]
    reduce [w node]
  ]

  rem: func [
      args [any-value! <...>]
      :look [any-value! <...>]
      x: b: dot:
    ][
    x: first look
    if block? x [
      x: make varargs! take look
      return apply 'rem [args: x look: x] 
    ]
    b: make block! 8
    forever [
      x: first look
      unless x [break]
      x: apply 'rem-1 [args: args look: look]
      dot-append b x
    ]
    b
  ]

  viewport: func [content] [
    if number? content [
      content: ajoin ["initial-scale=" content]
    ]
    rem meta /name "viewport" /content content
  ]
]

load-rem: func [
    x [block! string! file!]
    /secure t:
  ][
  if file? x [x: load x]
  if string? x [return x]
  either secure
  [ x: bind/new x rem ]
  [ x: bind x rem ]
  x: make varargs! x
  apply :rem/rem [args: x look: x]
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
