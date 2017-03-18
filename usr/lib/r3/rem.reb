REBOL [
  Name: 'rem
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "REbol Markup format"
  Needs: [dot]
  Exports: [load-rem mold-rem]
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
    node: make-tag-node :w
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
        set-attribute node t apply 'rem-1 [args: args look: look]
        ; ^--- for non-HTML applications:
        ; value of an attribute may be a node!
        continue
      ]
      if set-word? t [ take look
        t: to-word t
        unless style [style: make block! 16]
        set-attribute style t take args
        continue
      ]
      if issue? t [ take look
        id: next to-string t
        continue
      ]
      if any [url? t file? t] [ take look
        set-attribute node
          either/only w = 'a 'href 'src
          t
        continue
      ]
      break
    ]
    if id [set-attribute node 'id id]
    if style [set-attribute node 'style style]
    if class [set-attribute node 'class form class]
    if 'TAG = get :w [
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
      set-content node t
    ]
    node
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
      if x [append/only b x]
    ]
    if 1 < length b [return b]
    b/1
  ]

  style: func [code b: t: k: v: s: selector!:] [
    selector!: [
      set t [word! | issue!]
    ]
    s: make block! 8
    parse code [any [
      (b: make block! 4)
      some [selector! (append b t)]
      (append/only s b)
      (t: make block! 16)
      some [
        set k set-word! set v skip
        ( k: to-word k
          append t k append t v
        )
      ]
      (append/only s t)
    ] ]
    make block! reduce [
      'tag "style"
      '. s
    ]
  ]

  viewport: func [content] [
    if number? content [
      content: ajoin ["initial-scale=" content]
    ]
    rem meta /name "viewport" /content content
  ]
]

load-rem: func [
    x [block! string!]
    /secure t:
  ][
  if string? x [return x]
  either secure
  [ x: bind/new x rem ]
  [ x: bind x rem ]
  x: make varargs! x
  apply :rem/rem [args: x look: x]
]

mold-rem: func [
    x
    ret: tag: k: n: v:
  ][
  case [
    tag: get-tag-name x [
      ret: make string! 512
      if find layout tag [
        break-line indent ret
        if layout/:tag > 0 [++ indent]
      ]
      append ret tag
      if v: x/id [
        append ret " #"
        append ret v
      ]
      if v: x/class [
        for-each v split v [some space] [
          append ret " ."
          append ret v
        ]
      ]
      for-each-attribute k v x [
        case [
          find [id class] k [continue]
          find [href src] k [
            if string? v [
              k: attempt [load v]
              either k [v: :k]
              [v: to-file v]
            ]
            append ret space
            append ret mold v
          ]
          k = 'style [
            for-each [k v] v [
              append ret space
              append ret to-set-word k
              append ret space
              append ret mold v
            ]
          ]
          true [
            append ret space 
            append ret to-refinement k
            append ret space
            append ret mold v
          ]
        ]
      ]
      v: get-content x
      if v [
        append ret space
        case [
          any [tag = '! tag = '?] [
            append ret v
          ]
          true [
            append ret mold-rem v
          ]
        ]
      ]
      if all [
        find layout tag
        layout/:tag > 0
      ] [-- indent]
      ret
    ]
    block? x [
      ret: make string! 512
      append ret #"[" n: line-number
      forall x [
        unless head? x [append ret space]
        append ret mold-rem x/1
      ]
      if line-number > n [
        break-line indent - 1 ret
      ]
      append ret #"]"
    ]
    tag? x [ret: form x]
    true [ret: mold x]
  ]
  ret
]
line-number: 1
indent: 0
indent-width: 2
break-line: func [
  indent [integer!]
  buffer [string!]
  ][
  append buffer newline
  append/dup buffer space indent * indent-width
  line-number: line-number + 1
]

layout: make map! [
  ; break line before with current indent
  ; 0: do not indent content
  ; 1: also indent content
  body 0
  br 0
  div 1
  h1 1 h2 1 h3 1 h4 1 h5 1 h6 1
  header 1
  hr 0
  meta 0
  p 1
  table 1
  title 1
  tr 1

]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
