REBOL [
  Title: "HTML utils for Ren/C"
  Type: 'module
  Name: 'html
  Exports: [
    load-html
    mold-html
  ]
  Author: "giuliolunati@gmail.com"
  Version: 0.1.1
]
text-mod: import 'text
smart-decode-text: :text-mod/smart-decode-text
unquote-string: :text-mod/unquote-string
;=== RULES === 
  !?: charset "!?"
  alpha!: charset [#"A" - #"Z" #"a" - #"z"]
  hexa!: charset [#"A" - #"F" #"a" - #"f" #"0" - #"9"]
  num!: charset [#"0" - #"9"]
  space!: charset " ^/^-^M "
  spacer!: [and string! into[any space!]] 
  mark!: charset "<&"
  quo1!: charset {'\}
  quo2!: charset {"\}
  name!: use [w1 w+] [
    w1: charset [ "ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(02FF)" #"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)" #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)" ]
    w+: charset [ "-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" #"^(B7)" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(203F)" - #"^(2040)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)" #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)" ]
    [w1 any w+]
  ]
;=== END RULES === 

is-empty: make map! [
  ! true
  ? true
  area true
  base true
  br true
  col true
  embed true
  hr true
  img true
  input true
  keygen true
  link true
  meta true
  param true
  source true
  track true
  wbr true
]

split-html: function [
    data [file! binary! string!]
  ] [
  if file? data [data:  read data]
  if binary? data [data: smart-decode-text data]
  a: b: k: n: t: v: _
  ret: make block! 32
  emit: function [x] [
    if x = "" [return _]
    if char? x [x: to string! x]
    if string? x [
      t: to-value last ret
      if string? t [return append t x]
    ]
    append/only ret x
  ]
  entity!: [ #"&"
    [  #"#"
      [  #"x" copy t some hexa! (
          emit do [ ajoin[{"^^(} t {)"}] ]
        )
      |  copy t some num! (
          emit to char! to integer! t
        )
      ]
    | copy t some alpha! (
        emit switch t [
          "nbsp" [#"^(a0)"]
          "amp" [#"&"]
          "lt" [#"<"]
          "gt" [#">"]
          "quot" [#"^""]
          (to-issue t)
        ]
      )
    ]
    opt #";"
  ]
  value!:
    [  copy v [
      #"'" any [to quo1! #"\" skip] thru #"'"
      |
      #"^"" any [to quo2! #"\" skip] thru #"^""
      ] (v: unquote-string v)
    |  copy v to [space! | #">"]
    ]
  attribs!: [ (a: _)
    any [some space!
      copy k name! (v: true )
      opt [any space! #"=" any space! value!]
      (  unless a [a: make block! 8]
        k: to word! k
        if k = 'style [
          b: make block! 8
          parse v [ any [
            any space
            copy n name! any space! #":" any space
            copy k to [#";" | end] opt #";"
            (  
              append b to word! n
              append b k
            )
          ]  ]
          k: 'style v: b
        ] 
        append a k
        append/only a v
      )
    ]
    any space!
  ]
  comment!: ["!--" thru "--" and #">"]
  !tag!: [#"!" to #">"]
  ?tag!: [#"?" to #">"]
  atag!: [
    #"<" copy t name! attribs! opt #"/" #">"
    (emit to word! t if a [emit a])
  ]
  ztag!: [
    "</" copy t name! #">"
    (emit to refinement! t)
  ]
  data-tag!: [
    and copy t ["<script"|"<style"]
    atag! (insert t "</" append t #">")
    copy t to t (emit t) ztag!
  ]
  html!: [ any [
      copy t to mark! (emit t)
      [  #"<" copy t [comment! | !tag!] #">"
        (emit '! emit reduce [next t])
      |  #"<" copy t ?tag! #">"
        (emit '? emit reduce [next t])
      |  data-tag! | atag! | ztag! | entity!
      |  set t skip (emit t)
      ]
    ]
    copy t to end (emit t)
  ]
  either parse to string! data html! [ret] [false]
]

load-html: func [
    x [block! string! file!]
    get-tag: dot: t:
  ][
  get-tag: func [c: node: t: tag:] [
    tag: x/1
    x: next x
    node: make block! 8
    if any [tag = '?  tag = '!] [
      unless tail? x [
        repend node [tag x/1]
        x: next x
      ]
      return reduce [to-tag tag node]
    ]
    if block? x/1 [
      foreach [k v] x/1 [
        repend node [to-issue k v]
      ]
      x: next x
    ]
    either find is-empty tag
    [tag: append to-tag tag "/"]
    [
      c: make block! 8
      forever [
        if tail? x [break]
        t: x/1
        case [
          refinement? t [
            ;if tag != to-word t
            [
              fail ajoin ["unmatched " tag space t]
            ]
            x: next x  break
          ]
          word? t [
            append c get-tag
          ]
          string? t [
            repend c [%.txt t]  x: next x
          ]

          true [fail ajoin ["invalid " t]]
        ]
      ]
      append node c
    ]
    new-line/skip node true 2
    if empty? node [node: _]
    reduce [to-tag tag node]
  ]

  if maybe [string! file! binary!] x [x: split-html x]
  dot: make block! 8
  forever [
    if tail? x [break]
    t: x/1
    case [
      word? t [
        t: get-tag
        append dot get-tag
      ]
      string? t [repend dot [%.txt t] x: next x]
      true [fail ajoin ["invalid " t]]
    ]
  ]
  switch length dot [
    1 [dot: dot/1]
    0 [dot: _]
  ]
  new-line/skip dot true 2
  dot
]

mold-style: function [
    x [block! string!]
  ][
  if string? x [x] else [
    delimit map-each [k v] x [
      unspaced [k ":" space v]
    ] "; "
  ]
]

quote-html: function [
    x [string!]
  ][
  q: charset "<&>"
  parse x [any [to q [
    "&" insert "amp;"
    | remove "<" insert "&lt;"
    | remove ">" insert "&gt;"
  ]]]
  x
]

mold-html: function [
    x
    /into ret
  ][
  if not x [return x]
  ret: default [make string! 256]
  if not block? x [
    return append ret quote-html form x
  ]
  for-each [k v] x [
    case [
      %.txt = k [append ret quote-html form v]
      find [%.css %.js] k [append ret form v]
      tag? k [
        switch k [
          <doc> [
            join ret "<!DOCTYPE html>"
            k: <html>
          ]
          <header> [k: <head>]
        ]
        k: to-string k
        if empty: (#"/" = last k) [take/last k]
        join ret ["<" k]
        if block? v [while [issue? pick v 1] [
          join ret [
            space next to-string v/1 "="
            quote-string (if #style = v/1 [
              mold-style v/2
             ] else [
              to-string v/2
            ])
          ]
          v: skip v 2
        ]]
        if empty [append ret " /"]
        append ret ">"
        if not empty [
          mold-html/into v ret
          join ret ["</" k ">"]
        ]
     ]
    ]
  ]
  ret
]

quote-string: function [
    {Quote string s with " + escape with \}
    s [string!]
    /single "use single quotes"
  ][
  q: charset (if single [{\'}] else [{\"}])
  parse to string! s [any[to q insert "\" skip]]
  unspaced (if single [[{'} s {'}]] else [[{"} s {"}]])
]

clean-dot: function [dot rules] [
  while [not tail? dot] [
    k: dot/1
    if blank? k [fail mold dot]
    x: select*/skip rules k 2
    unless set? 'x [
      x: select*/skip rules case [
        issue? k ['attributes]
        tag? k ['tags]
        word? k ['properties]
        file? k ['strings]
        true fail mold k
      ] 2
    ]
    unless set? 'x [
      x: select*/skip rules 'default 2
    ]
    if set? 'x [
    case [
      x = '-- [remove/part dot 2 continue]
      x = '- [
        x: dot/2
        remove/part dot 2
        case [
          block? x [insert dot x]
          string? x [insert dot [%.txt x]]
        ]
        continue
      ]
      x = '+ []
      true [change dot x new-line dot true]
    ] ]
    if block? dot/2 [clean dot/2 rules]
    dot: skip dot 2
  ]
  head dot
]

scan-dot: procedure [dot [block!] /recur list] [
  unless recur [list: make block! 16]
  assert [even? length dot] 
  forskip dot 2 [
    k: dot/1
    unless find list k [append list k]
    if block? dot/2 [scan-dot/recur dot/2 list]
  ]
  unless recur [probe list]
]

; vim: sw=2 ts=2 sts=2 expandtab:
