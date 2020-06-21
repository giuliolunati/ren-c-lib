REBOL [
  type: module
  name: liturgia
  exports: [liturgical-date]
]
moon-age: function [d [date!]] [
  y: d/year
  m: d/month
  if m < 3 [y: y - 1 m: m + 9]
  else [m: m - 3]
  k: round/floor y / 100
  p: round/floor 8 * k + 13 / 25
  q: round/floor k / 4
  a: y mod 19 * 11 - k + q + p - 20 mod 30 + 1 ; Moon's age at 1 March
  a + m + d/day - 3 mod 30 + 1
]

easter: function [
  "https://en.m.wikipedia.org/wiki/Computus"
  year [integer!]
][
  r: make date! reduce [year 3 22]
  a: year mod 19
  k: round/floor year / 100
  p: round/floor 8 * k + 13 / 25
  q: round/floor k / 4
  M: 15 + k - p - q mod 30
  d: 19 * a + M mod 30
  r: r + d

  e: 7 - r/weekday

  if any [
    all [ e = 6 d = 29 ]
    all [
      e = 6
      d = 28
      M + 1 * 11 mod 30 < 19
    ]
  ][ e: e - 7 ]
  r + e
]

nweek: function [days [any-number!]] [
  to-integer round/floor days / 7 + 1
]

liturgical-date: function [d [date!]] [
  y: d/year
  pas: easter y
  avv: make date! reduce [y 11 26]
  avv: avv + 7 - avv/weekday
  b: make date! reduce [y 1 6]
  b: b + 7 - b/weekday
  nat: make date! reduce [y 12 25]
  case [
    d >= nat [t: "nat8" y: y + 1]
    d >= avv [
      t: "avv"
      y: y + 1
      n: nweek d - avv
    ]
    d - 49 > pas [
      t: "to"
      n: 34 + nweek d - avv
    ]
    d >= pas [
      t: "pas"
      n: nweek d - pas
    ]
    d + 46 >= pas [
      t: "qua"
      n: 6 + nweek d - pas
    ]
    d > b [
      t: "to?"
      n: nweek d - b
    ]
  ] else [
    t: "nat"
    n: 2 + nweek d - b
  ]
  join t n
]

; vim: set sw=2 expandtab:
