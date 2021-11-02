REBOL [
  Type: module
  Name: markup
  Exports: [xml html tml]
  Description: {}
]

Stack: make block! 8
Push: func [x] [append Stack quote x]
Pop: func [] [take/last Stack]

Flat-buf: make block! 8
Text-buf: make text! 8
Text-buf: make text! 8

Flush-text: func [] [
  if not empty? Text-buf [
    append Flat-buf :[
      'text copy Text-buf
    ]
    clear Text-buf
  ]
]

Vtag: func [buf] [
  Flush-text
  append Flat-buf :[
    'vtag buf
  ]
]

Otag: func [buf] [
  Flush-text
  append Flat-buf :[
    'otag buf
  ]
]

Ctag: func [tagname] [
  Flush-text
  append Flat-buf :[
    'ctag tagname
  ]
]

Comm: func [t] [
  append Flat-buf :['comm t
  ]
]

Error: func [x] [
  write-stdout "ERROR @ {"
  print [copy/part x 80 "...}"]
  quit 1
]
; text
Text: func [t] [
  append Flat-buf :['text t
  ]
]
; declaration <!...>
Decl: func [t] [
  append Flat-buf :['decl t
  ]
]
; processing instruction <?...>
Proc: func [t] [
  append Flat-buf :['proc t
  ]
]
; comment <!--...-->

amp-escape: func [t] [
  replace/all t "&" "&amp;"
]

xml: make object! [
  ;; LOCALS
  x: y: z: _
  buf: make block! 0

  ;; CUSTOMIZABLE
  void-tags: _
  text-tags: _
  raw-text-tags: _

  ;; CHARSETS
  !not-lt: complement charset "<"
  !space: charset { ^-^/}
  !not-value-char: union !space charset {/>'"}
  !not-name-char: union !not-value-char charset {=}
  !name-char: complement !not-name-char
  !value-char: complement !not-value-char

  ;; RULES
  !spaces: [some !space]
  !text: [copy x [
    !not-lt [to "<" | to end]
  ] (Text as text! x)]
  !name: [!name-char to !not-name-char]
  !attribute: [
    (y: _)
    copy x !name
    [ opt !spaces "="
      opt !spaces [
        {"} copy y to {"} skip
        | {'} copy y to {'} skip
        | copy y some !value-char
      ]
      (append buf :[as issue! as text! x as text! y])
    | (append buf :[as issue! as text! x true])
    ]
  ]
  !tag: ["<"
    [ "/" copy x to ">" skip
      (Ctag as tag! x)
    | "!--" copy x to "-->" 3 skip
      (Comm as text! x)
    | "!" copy x to ">" skip
      (Decl as text! x)
    | "?" copy x to "?>" 2 skip
      (Proc as text! x)
    | [copy x !name | !error]
      (clear buf, append buf as tag! x)
      while [!spaces opt !attribute]
      [ "/" ">"
        (Vtag copy buf)
      | ">"
        [ :(not null? find void-tags x)
          (Vtag copy buf)
        | :(not null? find text-tags x)
          (Otag copy buf)
          (y: unspaced ["</" x ">"])
          copy y [to y | !error]
          (y: as text! y)
          (if not null? find raw-text-tags x [y: amp-escape y])
          (Text y)
        | (Otag copy buf)
        ]
      | !error
      ]
    ]
  ]

  !error: [x: here (Error x)] 

  !content: [
    while [ !tag | !text]
    [end | !error]
  ]

  load: func [x] [
    clear Flat-buf
    parse x !content
    return Flat-buf
  ]
]

html: make xml [
  void-tags: [
    "area" "base" "br" "col" "embed"
    "hr" "img" "input" "keygen" "link"
    "meta" "param" "source" "track" "wbr"
  ]
  raw-text-tags: ["script" "style"]
  text-tags: join raw-text-tags ["textarea" "title"]
]

tml: make object! [

  x: txt: tagname: _
  name: value: _
  buf-a: make block! 8
  clone-tag: func [txt] [
    let x: _
    let s: tail Stack
    forever [
      if head? s [break]
      s: back s
      if s/1 = "[" [continue]
      assert [block? x: s/1]
      break
    ]
    if x and (find [<p> <div> <tr>] x/1) [
      Ctag x/1, Otag x
    ] else [append Text-buf txt]
  ]

  !error: [x: here (Error x)] 
  !hspace: charset " ^-"
  !space: charset " ^-^/"
  !nchar: charset [#"a" - #"z" #"A" - #"Z" #"0" - #"9" "-_.#"]
  !prop-char: union !nchar !space
  !stop-char: union !nchar charset "[\]^/!"
  !attributes: [ (clear buf-a)
    "{"
    some [
      while !space
      copy name some !nchar
      [ "=" while !space
        [ {"} copy value to {"} skip
        | {'} copy value to {'} skip
        | copy value some !nchar
        ] ( append buf-a as issue! as text! name
            append buf-a as text! value )
      | ":" while !space
        copy value some !prop-char opt ";"
        ( append buf-a as file! name
          append buf-a as text! trim value )
      | ( append buf-a as issue! as text! name
          append buf-a true )
      ] 
    ]
    thru "}"
  ]
  !raw-text: [
    "[" copy x while !nchar ">"
    (x: unspaced ["<" x "]"])
    copy txt to x, x
  ]
     
  load: func [
    "Convert TML text to rebol code"
    tml [file! binary! text!] "TML text"
  ] [
    if file? tml [tml: read tml]
    if binary? tml [tml: as text! tml]
    clear Flat-buf
    clear Text-buf
    parse tml [
      while further
        [ copy tagname some !nchar
          opt !attributes
          [ !raw-text (
              insert buf-a as tag! tagname
              Otag copy buf-a
              append Text-buf txt
              Ctag as tag! tagname
            )
          | "[" (
              insert buf-a as tag! tagname
              x: copy buf-a
              Otag x, Push x
            )
          | :(not empty? buf-a)
            ( insert buf-a as tag! tagname
              Vtag copy buf-a )
          | (append Text-buf tagname)
          ]
        | !raw-text (append Text-buf txt)
        | "[" (append Text-buf "[", Push "[")
        | "]" (
            x: Pop
            if x = "[" [append Text-buf "]"]
            else [Ctag first x]
          )
        | "\" opt
          [ "\" (append Text-buf "\")
          | some !space (Vtag [<br>])
          ]
        | newline
          [ copy txt some [while !hspace newline]
            (insert txt newline, clone-tag txt)
          | (append Text-buf newline)
          ]
        | "!["
          [ copy txt to "]!" "]!" (Comm txt)
          | !error
          ]
        | "!" (append Text-buf "!") 
        | copy txt [to !stop-char | to end]
          (append Text-buf txt)
        | end (Flush-text)
      ]
    ]
    return Flat-buf
  ]
]

;; vim: set et sw=2:
