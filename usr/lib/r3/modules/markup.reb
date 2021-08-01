REBOL [
  Type: module
  Name: markup
  Exports: [xml html tml]
  Description: {}
]

amp-escape: func [t] [
  replace/all t "&" "&amp;"
]

xml: make object! [
  ;; LOCALS
  x: y: z: _
  buf: make block! 0
  output: make block! 8

  ;; CUSTOMIZABLE
  void-tags: _
  text-tags: _
  raw-text-tags: _

  error: meth [x] [
    write-stdout "ERROR @ {"
    print [copy/part x 80 "...}"]
    quit 1
  ]
  ; text
  text: meth [t] [
    repend output ['text t
    ]
  ]
  ; declaration <!...>
  decl: meth [t] [
    repend output ['decl t
    ]
  ]
  ; processing instruction <?...>
  proc: meth [t] [
    repend output ['proc t
    ]
  ]
  ; comment <!--...-->
  comm: meth [t] [
    repend output ['comm t
    ]
  ]
  ; close tag </...>
  ctag: meth [t] [
    repend output ['ctag t
    ]
  ]
  ; empty tag <...[/]>
  vtag: meth [t] [
    repend output ['vtag t
    ]
  ]
  ; open tag <...>
  otag: meth [t] [
    repend output ['otag t
    ]
  ]

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
  ] (text as text! x)]
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
      (repend buf [as issue! x as text! y])
    | (repend buf [as issue! x true])
    ]
  ]
  !tag: ["<"
    [ "/" copy x to ">" skip
      (ctag as tag! x)
    | "!--" copy x to "-->" 3 skip
      (comm as text! x)
    | "!" copy x to ">" skip
      (decl as text! x)
    | "?" copy x to "?>" 2 skip
      (proc as text! x)
    | [copy x !name | !error]
      (clear buf, append buf as tag! x)
      while [!spaces opt !attribute]
      [ "/" ">"
        (vtag copy buf)
      | ">"
        [ :(not null? find void-tags x)
          (vtag copy buf)
        | :(not null? find text-tags x)
          (otag copy buf)
          (y: unspaced ["</" x ">"])
          copy y [to y | !error]
          (y: as text! y)
          (if not null? find raw-text-tags x [y: amp-escape y])
          (text y)
        | (otag copy buf)
        ]
      | !error
      ]
    ]
  ]

  !error: [x: here (error x)] 

  !content: [
    while [ !tag | !text]
    [end | !error]
  ]

  load: meth [x] [
    clear output
    parse x !content
    return output
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

;; vim: set et sw=2:
