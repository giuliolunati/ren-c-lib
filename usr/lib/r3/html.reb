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

; vim: sw=2 ts=2 sts=2 expandtab:
