REBOL [
  Type: module
  Name: markup
  Exports: [markup-parser]
  Description: {}
]

letter: charset [#"a" - #"z" #"A" - #"Z" ]
number: charset "0123456789"
ent-name: [some letter opt ";" | "#" some number opt ";"]

deamp: function [txt [text!]] [
  t: n: _
  if not parse? txt [while [
    to #"&"
    [ change copy t [
        "&#" copy n some number opt ";"
        ;:(256 > n: to-integer n)
      ] (to-char to-integer n)
    | skip
    ]
   ] to end ] [fail txt]
  txt
]

markup-parser: make object! [
  html: true ; -> parse as HTML
  ; html: false -> parse as XML
  indent: _
  indent-text: ""
  html-empty-tags: [
    "area" "base" "br" "col" "embed"
    "hr" "img" "input" "keygen" "link"
    "meta" "param" "source" "track" "wbr"
  ]
  ;; HOOKS TO BE CUSTOMIZED
  error: meth [x] [
    write-stdout "ERROR @ "
    print [copy/part x 80 "...."]
  ]
  ; declaration <!...>
  DECL: meth [t] [
    if indent [write-stdout indent-text]
    print ["DECL" mold t]
  ]
  ; processing instruction <?...>
  PROC: meth [t] [
    if indent [write-stdout indent-text]
    print ["PROC" mold t]
  ]
  ; comment <!--...-->
  COMM: meth [t] [
    if indent [write-stdout indent-text]
    print ["COMM" mold t]
  ]
  ; empty tag <...[/]>
  ETAG: meth [n a] [
    if indent [write-stdout indent-text]
    print ["ETAG" mold n mold a]
  ]
  ; open tag <...>
  OTAG: meth [n a] [
    if indent [
      write-stdout indent-text
      append/dup indent-text space indent
    ]
    print ["OTAG" mold n mold a]
  ]
  ; close tag </...>
  CTAG: meth [n] [
    if indent [
      repeat indent [take/last indent-text]
      write-stdout indent-text
    ]
    print ["CTAG" mold n]
  ]
  ; text
  TEXT: meth [t] [
    if indent [write-stdout indent-text]
    print ["TEXT" mold t]
  ]
 
  ;; LOCALS
  x: y: _
  buf: make block! 0

  ;; CHARSETS
  !not-lt: complement charset "<"
  !space: charset { ^-}
  !wspace: union !space charset newline
  !not-space: complement !space
  !not-name-char: union !space charset {/>'"=}
  !name-char: complement !not-name-char

  ;; RULES
  !spaces: [some !space]
  !wspaces: [some !wspace]
  !text: [copy x [
    !not-lt [to "<" | to end]
  ] (TEXT deamp as text! x)]
  !name: [!name-char to !not-name-char]
  !quoted-value: [{"} thru {"} | {'} thru {'}]
  !attribute: [
    (y: _)
    copy x !name
    [ opt !spaces "="
      opt !spaces copy y !quoted-value
    | (y: _)
    ] (repend buf [as text! x (take/last y as text! next y)])
  ]
  !tag: ["<"
    [ "/" copy x to ">" skip
      (CTAG as text! x)
    | "!--" copy x to "-->" 3 skip
      (COMM as text! x)
    | "!" copy x to ">" skip
      (DECL as text! x)
    | "?" copy x to "?>" 2 skip
      (PROC as text! x)
    | [copy x !name | !error]
      (clear buf append buf as text! x)
      while [!spaces opt !attribute]
      ; MUST use "first buf", NOT "buf/1"
      [ "/>" (ETAG first buf next buf)
      | html :(not null? find html-empty-tags pick buf 1)
        (ETAG first buf next buf)
      | ">" (OTAG first buf next buf)
      ]
      opt
      [ ; TODO: manage inner <!--comments-->
        html :(x = "script")
        copy y [to "</script>" | !error]
        (CTAG as text! y)
      ]
    ]
  ]

  !error: [x: (error x quit)] 

  !content: [
    while [ !tag | !text]
    [end | !error]
  ]

  run: meth [x] [parse x !content]
]

;; vim: set et sw=2:
