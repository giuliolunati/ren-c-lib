REBOL [
  Type: module
  Name: markup
  Exports: [markup-parser]
  Description: {}
]

show1: enfix function ['n] [
   set n function [x] compose/deep [print [(to-text to-word n) mold x]]
]

show2: enfix function ['n] [
  set n function [x y] compose/deep [
    print [
      (to-text to-word n)
      mold x
      mold y
    ]
  ]
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
  html-empty-tags: [
    "area" "base" "br" "col" "embed"
    "hr" "img" "input" "keygen" "link"
    "meta" "param" "source" "track" "wbr"
  ]
  ;; HOOKS TO BE CUSTOMIZED
  error: function [x] [
    write-stdout "ERROR @ "
    print [copy/part x 80 "...."]
  ]
  DECL: show1 ; declaration <!...>
  PROC: show1 ; processing instruction <?...>
  COMM: show1 ; comment <!--...-->
  ETAG: show2 ; empty tag <...[/]>
  OTAG: show2 ; open tag <...>
  CTAG: show1 ; close tag </...>
  TEXT: show1 ; text
 
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
