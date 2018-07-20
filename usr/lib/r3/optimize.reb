REBOL [ 
  Title: "Optimization tools"
  Type: module
  Name: optimize
  Author: "giuliolunati@gmail.com"
]

optimize: function [
    score [action!]
    guess [block!]
    precision [any-number!]
  ][
  x0: guess
  x: copy x0
  n: length of x
  r: 1
  v0: _
  forever [
    v: score x
    if any [not v0 | v < v0] [
      v0: v x0: copy x
      r: me * 2
    ] else [
      r: me * 0.9
      if r < precision [break]
    ]
    repeat i n [
      x/:i: x0/:i + (2 * random r) - r
    ]
  ]
  x0
]

phi: (square-root 5) - 1 / 2

golden-search: function [
    a [any-number!]
    b [any-number!]
    precision [any-number!]
    f [action!]
  ][
  d: b - a
  d: d * phi * phi
  a: a + d
  x: b - d
  d: d * phi
  y0: f a
  while [precision < abs d] [
    y: f x
    if y > y0 [
      x: x - d
      d: 0 - d
    ] else [y0: y]
    d: d * phi
    x: x + d
  ]
  return x - (d / 2)
]

; vim: set syn=rebol ts=2 sw=2 sts=2 expandtab:
