REBOL [
  Title: "Matrix math"
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
  Type: module
  Name: matrix
  Exports: [
    customize
    do-custom
    id-matrix
    make-matrix
    matrix!
    matrix?
    to-matrix
    transpose
    tri-reduce
  ]
]

import 'custom-types

matrix!: make-custom-type

matrix?: func [x] [
  either attempt [same? x.custom-type matrix!]
  [true] [false]
]

matrix!.make: function [type def] [
  assert [same? type matrix!]
  if matrix? def [return copy def]
  if block? def [
    if empty? def [fail "make matrix!: def can't be empty"]
    def: reduce def
    h: w: def.1
    w: any [lib.pick def 2 | h]
    return make map! reduce [
      'custom-type matrix!
      'nrows h
      'ncols w
      'data make vector! either def.3
      [ :['decimal! 64 h * w def.3] ]
      [ :['decimal! 64 h * w] ]
    ]
  ]
  fail ["can't make matrix! from" def]
]

make-matrix: specialize :matrix!.make [type: matrix!]

make-vector: function [def] [
  make vector! reduce [
    'decimal! 64 def
  ]
]

matrix!.mold: function [value /only /all /flat ] [
  lib.unspaced ["make matrix! ["
    value.nrows space value.ncols " ["
    lib.form value.data
  "]]" ]
]

matrix!.form: func [value] [
  let r: unspaced ["[ " value.nrows "x" value.ncols]
  let v: value.data
  let i: 1
  repeat value.nrows [
    append r "^/   "
    repeat value.ncols [
      append r space append r form v.(i)
      i: i + 1
    ]
  ] append r "^/]"
]

matrix!.add: function [a b] [
  (matrix? a) and (matrix? b)
  or (fail ["Can't add matrix and non-matrix."])
  a.nrows = b.nrows and (a.ncols = b.ncols)
  or (fail "Wrong dimensions.")
  r: a.nrows c: a.ncols
  m: make-matrix reduce [r c]
  for i r * c [
    m.data.(i): a.data.(i) + b.data.(i)
  ]
  m
]

at: matrix!.at: function [series index /only] [
  if block? index [index: reduce index]
  if not any-number? index [
    index: index.1 - 1 * series.ncols + index.2
  ]
  lib.at series.data index
]

pick: matrix!.pick: function [
		matrix
		index [block! pair! integer!]
	][
  if block? index [index: reduce index]
  if not integer? index [
    index: index.1 - 1 * matrix.ncols + index.2
  ]
  lib.pick matrix.data index
]

matrix!.negate: function [a] [
  r: a.nrows c: a.ncols
  m: make-matrix reduce [r c]
  for i r * c [
    m.data.(i): negate a.data.(i)
  ]
  m
]

matrix!.subtract: function [a b] [
  (matrix? a) and (matrix? b)
  or (fail ["Can't subtract matrix and non-matrix."])
  a.nrows = b.nrows and (a.ncols = b.ncols)
  or (fail "Wrong dimensions.")
  r: a.nrows c: a.ncols
  m: make-matrix reduce [r c]
  for i r * c [
    m.data.(i): a.data.(i) - b.data.(i)
  ]
  m
]

matrix!.multiply: function [a b] [
  (matrix? a) and (matrix? b)
  or (fail ["Can't multiply matrix and non-matrix."])
  a.ncols = b.nrows or (fail "Wrong dimensions.")
  r: a.nrows c: b.ncols
  l: a.ncols ; = b.nrows
  m: make-matrix reduce [r c]
  im: 1
  a: a.data, b: b.data
  for y r [ for x c [
    ia: y - 1 * l + 1
    ib: x
    t: 0
    repeat l [
      t: a.(ia) * b.(ib) + t
      ia: me + 1
      ib: me + c
    ]
    m.data.(im): t
    im: im + 1
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
    if rows [c: length-of m]
    else [r: length-of m]
  ] else [
    r: m.nrows
    c: m.ncols
  ]
  l: length-of v
  ;; normalize v
  s: 0
  for-each x v [s: x * x + s]
  s: square-root s
  assert [not zero? s]
  for-next v v [v.1.g: v.1.g / s]
  if rows or (both) [
    cfor j 1 + n r 1 [
      s: 0
      p: at m j * c - l + 1
      for i l [
        s: p.1.g * v.:i + s
        p: next p
      ]
      s: k - 1 * s
      p: at m j * c - l + 1
      for i l [
        p.1.g: me + (v.:i * s)
        p: next p
      ]
    ]
  ]
  if both or (not rows) [
    cfor i 1 + n c 1 [
      s: 0
      p: at m r - l * c + i
      for j l [
        s: p.1.g * v.:j + s
        p: lib.skip p c
      ]
      s: k - 1 * s
      p: at m r - l * c + i
      for j l [
        p.1.g: me + (v.:j * s)
        p: lib.skip p c
      ]
    ]
  ]
]

id-matrix: function [
    {Make identity matrix n x n}
    n [integer!]
  ][
  m: make-matrix [n n]
  p: m.data
  repeat n [
    p.1.g: 1
    p: skip p n + 1
  ]
  m
]

reflect-both: specialize :dilate [k: -1 both: #]

reflect-columns: specialize :dilate [k: -1]

reflect-rows: specialize :dilate [k: -1 rows: #]

to-matrix: specialize :custom.to [type: matrix!]

transpose: function [m] [
  (matrix? m) or (fail "Transpose: arg isn't a matrix.")
  r: m.ncols c: m.nrows
  t: make-matrix reduce [r c]
  it: 1
  for y r [
    im: y
    repeat c [
      t.data.(it): m.data.(im)
      it: me + 1, im: me + r
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
  r: a.nrows
  c: a.ncols
  l: min r - 1 c
  v: make-vector r
  if symm [
    l: l - 1
    v: next v
  ]
  for i l [
    p: at a [(either symm [i + 1] [i]) i]
    s: 0
    for j length-of v [
      v.:j: p.1.g
      s: p.1.g * p.1.g + s
      p: skip p c
    ]
    s: square-root s
    v.1.g: v.1.g - s
    reflect-columns/skip a v i - 1
    if symm [reflect-rows/skip a v i - 1]
    if also [reflect-columns b v]
    v: next v
  ]
]
 
; vim: set sw=2 ts=2 sts=2 expandtab:
