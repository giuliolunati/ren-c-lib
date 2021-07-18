REBOL [
  Type: module
  Name: markup
  Exports: [xml-parser html-parser]
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

xml-parser: make object! [
  indent: _
  indent-text: ""
  void-tags: false
  text-only-tags: false

  ;; HOOKS TO BE CUSTOMIZED
  error: meth [x] [
    write-stdout "ERROR @ {"
    print [copy/part x 80 "...}"]
    quit 1
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
  x: y: z: _
  buf: make block! 0

  ;; CHARSETS
  !not-lt: complement charset "<"
  !space: charset { ^-^/}
  !not-name-char: union !space charset {/>'"=}
  !name-char: complement !not-name-char

  ;; RULES
  !spaces: [some !space]
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
      (clear buf, append buf as text! x)
      while [!spaces opt !attribute]
      (x: first buf)
      [ "/>" (ETAG x next buf)
      | ">" (OTAG x next buf)
      ]
    ]
  ]

  !error: [x: here (error x)] 

  !content: [
    while [ !tag | !text]
    [end | !error]
  ]

  run: meth [x] [parse x !content]
]

html-parser: make xml-parser [
  void-tags: [
    "area" "base" "br" "col" "embed"
    "hr" "img" "input" "keygen" "link"
    "meta" "param" "source" "track" "wbr"
  ]
  text-tags: ["script" "style" "textarea" "title"]

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
      (clear buf, append buf as text! x)
      while [!spaces opt !attribute]
      (x: first buf)
      [ opt "/" ">"
        :(not null? find void-tags x)
        (ETAG x next buf)
      | ">" :(not null? find text-tags x)
        (OTAG x next buf)
        (x: unspaced ["</" x ">"])
        copy y [to x | !error]
        (TEXT as text! y)
      | ">" (OTAG x next buf)
      | !error
      ]
    ]
  ]
]

; testing
p: t: _
if all [
  not system/script/parent/path
  system/script/header/type = 'module
  system/script/header/name = 'markup
] [
  t: {
    <!DOCTYPE html>
    <head>
      <title> Title <br/> </title>
      <link href="" rel="stylesheet">
      <meta name=
        "viewport"
      />
      <script>"<br>"</script>

    </head>

    <!-- vim: set et sw=2: -->
  }
  print "=== PARSE AS HTML: ==="
  p: make html-parser [indent: 2]
  p/run t
  print "=== PARSE AS XML: ==="
  p: make xml-parser [indent: 2]
  p/run t
]



;; vim: set et sw=2:
