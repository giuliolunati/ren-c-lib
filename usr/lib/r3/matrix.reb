REBOL [
  Title: "Matrix math"
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
  Type: module
  Name: matrix
  Exports: [matrix! matrix? to-matrix transpose]
]

custom: import 'custom
custom: custom/custom

matrix!: make map! 8

matrix?: func [x] [
  either attempt [same? x/custom-type matrix!]
  [true] [false]
]

matrix!/make: function [type def] [
  assert [same? type matrix!]
  if matrix? def [return copy def]
  if block? def [
    if empty? def [fail "make matrix!: def can't be empty"]
    h: def/1
    w: any [pick def 2 | h]
    return make map! reduce [
      'custom-type matrix!
      'nrows h
      'ncols w
      'data make vector! reduce/opt [
        'decimal! 64 h * w
        opt attempt [def/3]
      ]
    ]
  ]
  fail ["can't make matrix! from" def]
]

make-matrix: specialize :matrix!/make [type: matrix!]

matrix!/mold: function [value /only /all /flat ] [
  lib/unspaced ["make matrix! ["
    value/nrows space value/ncols " ["
    lib/form value/data
  "]]" ]
]

matrix!/form: function [value] [
  r: unspaced ["[ " value/nrows "x" value/ncols]
  i: value/data
  loop value/nrows [
    append r "^/   "
    loop value/ncols [
      append r space append r form i/1
      i: next i
    ]
  ] append r "^/]"
]

matrix!/add: function [a b] [
  ((matrix? a) and (matrix? b))
  or (fail ["Can't add matrix and non-matrix."])
  ((a/nrows = b/nrows) and (a/ncols = b/ncols))
  or (fail "Wrong dimensions.")
  r: a/nrows c: a/ncols
  m: make-matrix reduce [r c]
  ia: a/data ib: b/data i: m/data
  for-next i [
    i/1: ia/1 + ib/1
    ia: next ia ib: next ib
  ]
  m
]

matrix!/subtract: function [a b] [
  ((matrix? a) and (matrix? b))
  or (fail ["Can't add matrix and non-matrix."])
  ((a/nrows = b/nrows) and (a/ncols = b/ncols))
  or (fail "Wrong dimensions.")
  r: a/nrows c: a/ncols
  m: make-matrix reduce [r c]
  ia: a/data ib: b/data i: m/data
  for-next i [
    i/1: ia/1 - ib/1
    ia: next ia ib: next ib
  ]
  m
]

matrix!/multiply: function [a b] [
  ((matrix? a) and (matrix? b))
  or (fail ["Can't add matrix and non-matrix."])
  (a/ncols = b/nrows)
  or (fail "Wrong dimensions.")
  r: a/nrows c: b/ncols
  l: a/ncols ; = b/nrows
  m: make-matrix reduce [r c]
  pm: m/data
  repeat y r [ repeat x c [
    pa: skip a/data y - 1 * l
    pb: skip b/data x - 1
    t: 0
    loop l [
      t: pa/1 * pb/1 + t
      pa: next pa
      pb: skip pb c
    ]
    pm/1: t
    pm: next pm
  ]]
  m
]

transpose: function [m] [
  matrix? m or (fail "Transpose: arg isn't a matrix.")
  r: m/ncols c: m/nrows
  t: make-matrix reduce [r c]
  pt: t/data
  pm: m/data
  repeat y r [
    pm: skip m/data y - 1
    loop c [
      pt/1: pm/1
      pt: next pt pm: skip pm r
    ]
  ]
  t
]

to-matrix: specialize :custom/to [type: matrix!]

; vim: set sw=2 ts=2 sts=2 expandtab:
