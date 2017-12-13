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
quote-string: :text-mod/quote-string

markup: import 'markup

load-html: function [
    x [string! binary! file!]
    /quiet
  ][
  if file? x [x: read x]
  if binary? x [x: smart-decode-text x]
  apply 'markup/load-html [source: x quiet: quiet] 
]

is-empty?: function [t [any-string!]] [
  any [ find [
    "area" "base" "br" "col" "embed" "hr" "img" "input"
    "keygen" "link" "meta" "param" "source" "track" "wbr"
  ] t | find "!?" t/1 ]
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

mold-html: function [
    x [block!]
    /into ret
  ][
  if not x [return x]
  ret: default [make string! 256]
  if not block? x [
    return append ret quote-html form x
  ]
  switch x/type [
    comment [
      append ret "<!--"
      append ret x/value
      append ret "-->"
    ]
    document [
      append ret "<html>"
      mold-html/into x/head ret
      mold-html/into x/body ret
      append ret "</html>"
    ]
    element [
      append ret "<"
      append ret name: to-string x/name
      empty: is-empty? name
      attrib: x/value
      for-each k attrib [
        append ret unspaced [
          " " k "=" quote-string copy attrib/:k
        ]
      ]
      if empty [append ret " /"]
      append ret ">"
      x: select x 'first
      while [x] [
        mold-html/into x ret
        x: select x 'next
      ]
      if not empty [
        append ret to-tag unspaced ["/" name]
      ]
    ]
    text [append ret x/value]
  ] else [
    print ["!! unhandled type:" x/type]
  ]
  ret
]

; vim: sw=2 ts=2 sts=2 expandtab:
