REBOL [
  Title: "HTML utils for Ren/C"
  Type: 'module
  Name: 'html
  Exports: [
    mold-html
  ]
  Author: "giuliolunati@gmail.com"
  Version: 0.1.1
]

mold-style: func [
  x [block! string!]
  ret:
  ][
  if string? x [return x]
  ret: make string! 32
  foreach [k v] x [
    if not empty? ret [append ret "; "]
    append ret k
    append ret ": "
    append ret v
  ]
  ret
]

quote-html: func [
    x [string!] q:
  ] [
  q: charset "<&>"
  parse x [any [to q
		[ #"&" insert "amp;"
		| remove #"<" insert "&lt;"
		| remove #">" insert "&gt;"
		]
  ] ]
  x
]

mold-html: func [
  x
  /into ret
  empty:
  ][
  unless into [ret: make string! 256]
  unless x [return x]
  unless block? x [
    return append ret quote-html form x
  ]
  for-each [k v] x [
    case [
      %.txt = k [append ret quote-html form v]
      tag? k [
        switch k [
          <doc> [k: <html>]
          <header> [k: <head>]
        ]
        k: to-string k
        if empty: (#"/" = last k) [take/last k]
        append ret #"<"
        append ret k
        if block? v [while [word? v/1] [
          append ret space
          append ret v/1
          append ret #"="
          append ret quote-string either
            'style = v/1
            [ mold-style v/2 ]
            [ to-string v/2 ]
          v: skip v 2
        ]]
        if empty [append ret " /"]
        append ret #">"
        unless empty [
          mold-html/into v ret
          append ret ajoin ["</" k #">"]
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
  ] [
  q: charset either single [{\'}] [{\"}]
  parse to string! s [any[to q insert "\" skip]]
  ajoin either/only single
  [{'} s {'}] 
  [{"} s {"}] 
]

; vim: syn=rebol sw=2 ts=2 sts=2 expandtab:
