REBOL [ 
  Title: "Text utils for REBOL 3"
  Type: module
  Name: text
  Exports: [
    smart-decode-text
    quote-text
    unquote-text
  ]
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
]


;=== FUNCTIONS ===
smart-decode-text: function [ {convert binary! to text!"
    support utf8 and cp1252 (autodetect)}
    binary [binary!]
    /utf8 "force utf8"
    /cp1252 "force cp1252"
  ][
  if all [
    not cp1252
    any [utf8 (invalid-utf8? binary) = _]
  ] [return to text! binary]
  cp1252-map: "^(20ac)^(81)^(201A)^(0192)^(201E)^(2026)^(2020)^(2021)^(02C6)^(2030)^(0160)^(2039)^(0152)^(8d)^(017D)^(8f)^(90)^(2018)^(2019)^(201C)^(201D)^(2022)^(2013)^(2014)^(02DC)^(2122)^(0161)^(203A)^(0153)^(017E)^(9e)^(0178)"
  mark: :binary
  ret: copy #{}
  x80: charset[#"^(80)" - #"^(ff)"]
  while [mark: try find binary x80][
    append ret copy/part binary mark
    i: mark/1
    either i >= 160
      [append ret to char! i]
      [append ret cp1252-map/(i - 127)]
    binary: next mark
  ]
  append ret binary
  to text! ret
]

quote-text: function [
    {Quote text s with " + escape with \}
    s [text!] "MODIFIED!"
    /single "use single quotes"
    /html {<"'> as entities}
  ] [
  if html [
    q: charset either single [{<'>}] [{<">}]
    parse s [any [
      to q set c: and skip (c: switch c [
        #"^"" ["&quot;"]
        #"'" ["&apos;"]
        #"<" ["&lt;"]
        #">" ["&gt;"]
      ]) change skip c
    ]]
  ] else [
    q: charset either single [{\'}] [{\"}]
    parse s [any [to q insert "\" skip]]
  ]
  unspaced either single ;\
    [[{'} s {'}]]
    [[{"} s {"}]]
]

unquote-text: function [
    {Remove \ escape and  quotes}
    s [text!]
  ] [
  parse s [ any [
    to #"\" remove skip skip
  ] ]
  copy/part next s back tail s
]

; vim: set syn=rebol ts=2 sw=2 sts=2 expandtab:
