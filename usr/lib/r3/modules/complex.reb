REBOL [
  Title: "Complex numbers"
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
  Type: module
  Name: complex
  Exports: [complex! complex? to-complex i +i -i]
]

custom: import 'custom
custom: custom/custom

complex!: make map! 8
complex!/custom-type: complex!

complex?: function [x] [
  either all [map? x same? complex! :x/custom-type]
  [true] [false]
]

complex!/make: function [type def] [
  assert [same? type complex!]
  if complex? def [return copy def]
  o: make map! reduce [
    'custom-type complex!
    'r 0 'i 0
  ]
  case [
    any-number? def [o/r: def return o]
    match [block! pair!] def [o/r: def/1 o/i: def/2 return o]
    text? def [
      if attempt [
        t: split def #"i"
        insert t/2 take/last t/1
        o/r: to-decimal t/1
        o/i: to-decimal t/2
      ] [return o]
    ]
  ]
  fail/where unspaced [
    "Cannot make complex! from " mold def
  ] backtrace 4
]

make-complex: specialize :complex!/make [type: complex!]

complex!/to: function [
    type [datatype! map!]
    value [any-value!]
  ][
  switch type [
    block! [reduce [value/r value/i]]
    pair! [to-pair reduce [value/r value/i]]
    text! [complex!/form value]
    default [
      fail/where [
        "Cannot convert complex! to" mold type
      ] 'type
    ]
  ]
]

to-complex: specialize :custom/to [type: complex!]

i: make-complex [0 1]

+i: enfix function [
  v1 [any-number!]
  v2 [any-number!]
] [
  make-complex reduce [v1 v2]
]

-i: enfix function [
  v1 [any-number!]
  v2 [any-number!]
] [
  make-complex reduce [v1 negate v2]
]

complex!/form: c-form: function [
  value [<opt> any-value!]
] [
  i: value/i r: value/r
  case [
    i < 0 [unspaced [
      if r != 0 [r]
      "-i" if i != -1 [negate value/i]
    ]]
    i > 0 [unspaced [
      if r != 0 [r]
      if r != 0 ["+"]
      "i"
      if i != 1 [i]
    ]]
    r != 0 [form r]
    default ["0"]
  ]
]

complex!/mold: function [value /only /all /flat ] [
  lib/unspaced ["make complex! [" value/r space value/i "]"]
]

complex!/add: c-add: function [v1 v2] [
  v1: make-complex v1 v2: make-complex v2
  v: make-complex reduce[
    add v1/r v2/r
    add v1/i v2/i
  ]
]

complex!/subtract: c-sub: function [v1 v2] [
  v1: make-complex v1 v2: make-complex v2
  v: make-complex reduce[
    subtract v1/r v2/r
    subtract v1/i v2/i
  ]
]

complex!/multiply: c-mul: function [v1 v2] [
  v1: make-complex v1 v2: make-complex v2
  v: make-complex reduce[
    subtract
      multiply v1/r v2/r
      multiply v1/i v2/i
    add
      multiply v1/r v2/i
      multiply v1/i v2/r
  ]
]

complex!/divide: c-div: function [v1 v2] [
  v1: make-complex v1 v2: make-complex v2
  v: make-complex reduce[
    add
      multiply v1/r v2/r
      multiply v1/i v2/i
    subtract
      multiply v1/i v2/r
      multiply v1/r v2/i
  ]
  r2: add
      multiply v2/r v2/r
      multiply v2/i v2/i
  v/r: divide v/r r2
  v/i: divide v/i r2
  v
]

complex!/absolute: c-abs: function [v] [
  square-root add
    multiply v/r v/r
    multiply v/i v/i
]

complex!/negate: function [z] [
  z: copy z
  z/r: negate z/r
  z/i: negate z/i
  z
]

complex!/zero?: c-zero?: function [z] [
  all [zero? z/r  zero? z/i]
]

atan2: function [y x] [
  if (absolute x) >= (absolute y) [
    if zero? x [return 0]
    a: arctangent/radians (y / x)
  ] else [
    a: (pi / 2) - arctangent/radians (x / y)
  ]
  if x + y < 0 [a: a - pi]
  if all [x + y = 0  x < 0] [a: a + pi]
  if a + pi <= 0 [a: a + pi + pi]
  a
]

angle: function [z] [
  atan2 z/i z/r
]

complex!/log-e: c-log: function [z] [
  o: make map! 3
  if not o/r: log-e c-abs z [
    make error! _
  ]
  o/custom-type: complex!
  o/i: atan2 z/i z/r
  o
]

custom/log-e: adapt :custom/log-e [
  if all [any-number? value  value < 0] [
    value: make-complex value
  ]
]

complex!/exp: c-exp: function [z] [
  o: make map! 3
  o/custom-type: complex!
  r: exp z/r
  o/i: r * sine/radians z/i
  o/r: r * cosine/radians z/i
  o
]

complex!/power: function [z k] [
  if all [integer? k  k > 0] [
    r: 1
    while [k > 0] [
      if odd? k [k: me - 1 r: c-mul r z]
      k: k / 2
      z: c-mul z z
    ]
    return r
  ]
  z: make-complex z
  k: make-complex k
  if c-zero? z [
    if k/r > 0 [return 0]
    return make error! _
  ]
  c-exp c-mul k c-log z
]

complex!/square-root: c-sqrt: function [z] [
  r: square-root c-abs z
  a: (angle z) / 2
  o: make map! 3
  o/custom-type: complex!
  o/i: r * sine/radians a
  o/r: r * cosine/radians a
  o
]

custom/square-root: adapt :custom/square-root [
  if all [any-number? value  value < 0] [
    value: make-complex value
  ]
]

complex!/sin: c-sin: function [z] [
  z: c-exp c-mul i z
  z: c-add z c-div -1 z
  t: z/r / -2  z/r: z/i / 2  z/i: t ;t=z/2i
  z
]

complex!/asin: c-asin: function [z] [
  z: c-mul z i
  t: c-sqrt (c-add 1 c-mul z z)
  if z/r >= 0 [
    t: c-add z t
  ] else [
    t: c-div -1 c-sub z t
  ]
  c-div c-log t i
]

complex!/cos: c-cos: function [z] [
  z: c-exp c-mul i z
  z: c-add z c-div 1 z
  c-div z 2
]

complex!/acos: function [z] [
  c-sub (pi / 2) c-asin z
]

complex!/tan: function [z] [
  c-div c-sin z c-cos z
]

complex!/atan: function [z] [
  z: c-mul z i
  z: c-div c-add 1 z c-sub 1 z
  z: c-div c-log z 2
  c-div z i
]

complex!/equal?: c-=: function [a b] [
  unless all [complex? a complex? b] [
    a: make-complex a  b: make-complex b
  ]
  all [a/r = b/r  a/i = b/i]
]

complex!/strict-equal?: function [a b] [
  if all [complex? a complex? b] [
    return all [a/r == b/r  a/i == b/i]
  ]
  false
]

; vim: set syn=rebol ts=2 sw=2 sts=2:
