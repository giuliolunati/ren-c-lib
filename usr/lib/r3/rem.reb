REBOL [
  Name: 'rem
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "REbol Markup format"
]

dot: import 'doc-tree
+pair: enfix :dot/append-pair-to-map

dot-append: proc [
    b [block!]
    v [any-value! <opt>]
  ][
  fail "dot-append"
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
  count: toc-content: _
  rem-element: function [
      ;; WARNING: if change here, check specializations!
      name [word!]
      empty [logic!]
      args [any-value! <...>]
      :look [any-value! <...>]
    ][
    node: dot/make-node
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
    if 'body = name [
      set 'toc-content make block! 8
      set 'count 1
    ]
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
      switch/default name [
        'script [t: reduce [%.js t]]
        'style [t: reduce [%.css t]]
      ][
        t: maybe-process-text t
      ]
    ]
    if all[toc-content | find [h1 h2 h3 h4 h5 h6] name] [
      dot-append toc-content reduce [
        name
        reduce [
          <a> join-of reduce [
            #href join-of "#toc" count
          ] :t
        ]
      ]
      dot-append node reduce [
        <a> reduce [#id join-of "toc" count: ++ 1]
      ]
    ]
    if 'body = name [dot-toc :t toc-content]
    if t [dot/append-existing node to-node :t]
    case [
      empty? node [node: _]
      all [2 = length of node | %.txt = node/1] [
        node: node/2
      ]
    ]
    node/value: attributes
    dot/make-element/target name empty node
  ]
  node: to-node: function [x [block!]] [
    if dot/maybe-node? x [return x]
    node: dot/make-node
    while [not tail? x] [
      t: do/next x 'x
      if string? :t [
        t: maybe-process-text t
      ]
      if maybe [char! any-string! any-number!] :t
      [ t: dot/make-text t ]
      if block? :t [
        dot/append-existing node to-node t
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
      :process-text = true [smart-text x]
      any-function? :process-text [process-text x]
      true [dot/make-text x]
    ]
  ]
  smart-text: function [x] [
    x: copy x
    c: t: _
    node: dot/make-node
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
      (if v > "" [dot/append-existing node v])
      [ "\" [newline | spaces]
        (dot/append-existing node br)
      | newline some [
          any spaces newline
          (dot/append-existing node br)
        ]
        (dot/append-existing node br)
      | remove "\" set c: skip
        (dot/append-existing node c)
      | copy c: [skip [spaces | newline]]
        (dot/append-existing node c)
      | set c: "*" get-markdown
        (dot/append-existing node b v)
      | set c: "/" get-markdown
        (dot/append-existing node i v)
      | set c: "^^" get-markdown
        (dot/append-existing node sup v)
      | set c: "_" get-markdown
        (dot/append-existing node sub v)
      | set c: "`" get-markdown
        (dot/append-existing node unspaced ["`" v "`"])
      | set v xchar
        (dot/append-existing node v)
      ]
    ]]
    node
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
          | "{" (n: ++ 1)
          | "}" (n: -- 1)
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
