REBOL [
  Type: module
  Name: markup
  Exports: [markup-parser]
  Description: {}
]

args: system/script/args

markup-parser: make object! [
  ;; HOOKS TO CUSTOMIZE
  error: function [x] [
    write-stdout "ERROR @ "
    print [copy/part x 80 "...."]
  ]
  declaration: processing-instruction: comment:
  empty-tag: open-tag:
  close-tag:
  text: _
  
  ;; LOCALS
  x: y: _

  ;; STACK & BUFFER
  buf: make block! 0

  ;; CHARSETS
  !not-lt: negate charset "<"
  !space: charset { ^-}
  !wspace: union !space charset newline
  !not-space: negate !space
  !not-name-char: union !space charset {/>'"=}
  !name-char: negate !not-name-char

  ;; RULES
  !spaces: [some !space]
  !wspaces: [some !wspace]
  !text: [copy x [
    !not-lt [to "<" | to end]
  ] (text x)]
  !name: [!name-char to !not-name-char]
  !quoted-value: [{"} thru {"} | {'} thru {'}]
  !attribute: [
    (y: _)
    copy x !name
    [ opt !spaces"="
      opt !spaces copy y !quoted-value
    | (y: _)
    ] (repend buf [x (take/last y next y)])
  ]
  !tag: ["<"
    [ "/" copy x to ">" skip
      (close-tag x)
    | "!--" copy x to "-->" 3 skip
      (comment x)
    | "!" copy x to ">" skip
      (declaration x)
    | "?" copy x to "?>" 2 skip
      (processing-instruction x)
    | [copy x !name | !error]
      (clear buf append buf x)
      any [!spaces opt !attribute]
      [ "/>" (empty-tag buf)
      | ">" (open-tag buf)
      ]
    ]
  ]

  !error: [x: (error x quit)] 

  !content: [
    any
    [ !tag | !text | !comment
    | !processing-instruction | declaration
    ]
    [end | !error]
  ]

  parse: method [x] [lib/parse x !content]
]

;; vim: set et sw=2:
