REBOL [
  Title: "Matrix math"
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
  Type: module
  Name: matrix
  Exports: [
    id-matrix
    matrix!
    matrix?
    to-matrix
    transpose
    tri-reduce
  ]
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
    def: reduce def
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
  (matrix? a and [matrix? b])
  or [fail ["Can't add matrix and non-matrix."]]
  (a/nrows = b/nrows and [a/ncols = b/ncols])
  or [fail "Wrong dimensions."]
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
  (matrix? a and [matrix? b])
  or [fail ["Can't add matrix and non-matrix."]]
  (a/nrows = b/nrows and [a/ncols = b/ncols])
  or [fail "Wrong dimensions."]
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
  (matrix? a and [matrix? b])
  or [fail ["Can't add matrix and non-matrix."]]
  (a/ncols = b/nrows)
  or [fail "Wrong dimensions."]
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

dilate: function [
    "Apply dilatation to colums (rows) of m" 
    return: <void>
    m "matrix or vector (modified)"
    v [vector!]
      "dilatation vector"
    k "dilatation factor, -1 for reflection"
    /skip n "skip n columns"
    /rows "apply to rows"
    /both "apply to rows and columns"
  ][
  if not skip [n: 0]
  if vector? m [
    r: c: 1
    data: m
    if rows [c: length-of m]
    else [r: length-of m]
  ] else [
    data: m/data
    r: m/nrows
    c: m/ncols
  ]
  l: length-of v
  // normalize v
  s: 0
  for-each x v [s: x * x + s]
  s: square-root s
  assert [not zero? s]
  for-next v [v/1: v/1 / s]
  if rows or [both] [
    for j 1 + n r 1 [
      s: 0
      p: at data j * c - l + 1
      repeat i l [
        s: p/1 * v/:i + s
        p: next p
      ]
      s: k - 1 * s
      p: at data j * c - l + 1
      repeat i l [
        p/1: me + (v/:i * s)
        p: next p
      ]
    ]
  ]
  if both or [not rows] [
    for i 1 + n c 1 [
      s: 0
      p: at data r - l * c + i
      repeat j l [
        s: p/1 * v/:j + s
        p: lib/skip p c
      ]
      s: k - 1 * s
      p: at data r - l * c + i
      repeat j l [
        p/1: me + (v/:j * s)
        p: lib/skip p c
      ]
    ]
  ]
]

id-matrix: function [
    {Make identity matrix n x n}
    n [integer!]
  ][
  m: make-matrix [n n]
  p: m/data
  loop n [
    p/1: 1
    p: skip p n + 1
  ]
  m
]

reflect-both: specialize :dilate [k: -1 both: true]

reflect-columns: specialize :dilate [k: -1]

reflect-rows: specialize :dilate [k: -1 rows: true]

to-matrix: specialize :custom/to [type: matrix!]

transpose: function [m] [
  matrix? m or [fail "Transpose: arg isn't a matrix."]
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

tri-reduce: function [
    {Reduce matrix a to upper triangular form r = q * a, where q is orthogonal.}
    return: <void>
    a "matrix, modified to r = q * a"
    /also b "matrix, modified to q * b"
    /symm "a is symmetric, r = q * a * q' is tri-diagonal"
  ][
  r: a/nrows
  c: a/ncols
  l: min r - 1 c
  v: make vector! reduce ['decimal! 64 r]
  if symm [
    l: l - 1
    v: next v
  ]
  repeat i l [
    p: at a/data (either symm [i] [i - 1]) * c + i
    s: 0
    repeat j length-of v [
      v/:j: p/1
      s: p/1 * p/1 + s
      p: skip p c
    ]
    s: square-root s
    v/1: v/1 - s
    reflect-columns/skip a v i - 1
    if symm [reflect-rows/skip a v i - 1]
    if also [reflect-columns b v]
    v: next v
  ]
]
  
; vim: set sw=2 ts=2 sts=2 expandtab:
