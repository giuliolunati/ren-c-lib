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
  count: toc-content: _
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
        set 'toc-content make block! 8
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
        ][
          t: maybe-process-text t
        ]
      ]
      if all[toc-content | find [h1 h2 h3 h4 h5 h6] tag] [
        dot-append toc-content reduce [
          (to-tag tag)
          reduce [
            <a> join-of reduce [
              #href join-of "#toc" count
            ] :t
          ]
        ]
        dot-append buf reduce [
          <a> reduce [#id join-of "toc" ++ count]
        ]
      ]
      if 'body = tag [dot-toc :t toc-content]
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
      t: do/next x 'x
      if string? :t [t: maybe-process-text t]
      dot-append buf :t
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
  ;; smart-text
  process-text: false
  raw-text: function [x] [reduce [%.txt x]]
  maybe-process-text: func [x [string!]] [
    case [
      :process-text = true [smart-text x]
      any-function? :process-text [process-text x]
      true [reduce [%.txt x]]
    ]
  ]
  smart-text: function [x] [
    c: _
    t: make block! 8
    x: copy x
    replace/all x "--" "—"
    replace/all x "->" "^(2192)" ; right arrow
    replace/all x "=>" "^(21d2)" ; right double arrow
    get-markdown: [
      copy v: [any [
        [to xchar | to end]
        [ remove "\" skip
        | and c break
        | skip
        ]
      ]] skip
    ]
    spaces: charset " ^-"
    xchar: charset "*/^^_`\^/"
    parse x [any [
      copy v: [to xchar | to end]
      (if v > "" [dot-append t [%.txt v]])
      [ "\" [newline | spaces]
        (dot-append t [<br/> _])
      | newline some [
          any spaces newline
          (dot-append t [<br/> _])
        ]
        (dot-append t [<br/> _])
      | remove "\" set c: skip
        (dot-append t [%.txt c])
      | copy c: [skip [spaces | newline]]
        (dot-append t [%.txt c])
      | set c: "*" get-markdown
        (dot-append t [<b> v])
      | set c: "/" get-markdown
        (dot-append t [<i> v])
      | set c: "^^" get-markdown
        (dot-append t [<sup> v])
      | set c: "_" get-markdown
        (dot-append t [<sub> v])
      | set c: "`" get-markdown
        (dot-append t [%.txt unspaced ["`" v "`"]])
      | set v xchar
        ( if empty? t [dot-append t [%.txt v]]
          else [append last t v]
        )
      ]
    ]]
    t
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
          | "{" (++ n)
          | "}" (-- n)
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
  rem/node x
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
