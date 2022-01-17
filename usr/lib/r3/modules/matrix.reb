REBOL [
  Title: "Matrix math"
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
  Type: module
  Name: matrix
  Exports: [
    ? ; enfix solve/copy
    customize
    do-custom

    id-matrix
    make-matrix
    make-vector
    matrix!
    matrix-format
    matrix?
    qr-factor
    right-inverse
    solve
    to-matrix
    transpose
    tri-factor
  ]
]

import 'custom-types


; VECTORS

make-vector: function [def] [
  make vector! reduce [
    'decimal! 64 def
  ]
]

vector-norm: func [v] [
  let s: 0
  let x
  for i length-of v [
    x: v.(i)
    s: x * x + s
  ]
  return square-root s
]

; MATRIX! TYPE

matrix!: make-custom-type

matrix?: func [x] [
  either attempt [same? x.custom-type matrix!]
  [true] [false]
]

to-matrix: specialize :custom.to [type: matrix!]


; MAKE, TO, COPY

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

matrix!.to: func [type value] [
  if not all [
    same? type matrix!
    vector? value
  ] [fail "Can't make matrix!"]
  return make map! reduce [
    'custom-type matrix!
    'nrows length-of value
    'ncols 1
    'data value
  ]
]

matrix!.copy: m-copy: func [
  value [custom-type!]
  /part [any-number! any-series! pair!]
  /shallow
  /types [typeset! datatype!]
] [
  let r: copy value
  if not shallow [r.data: copy value.data]
  return r
]


; MOLD, FORM, FORMAT

matrix!.mold: function [value /only /all /flat ] [
  lib.unspaced ["make matrix! ["
    value.nrows space value.ncols " ["
    lib.form value.data
  "]]" ]
]

matrix!.width: 40 ; default width for matrix-format

fmt: func [
  wid [integer!]
  x [integer! decimal!]
] [
  r: form x
  w: abs wid
  case [
    0 >= n: (length-of r) + 1 - abs wid []
    ; too long
    p: find r "e" [
      remove/part (any [skip p negate n, r]) n 
    ]
    ; not exp. not.
    all [
      p: find r "."
      n <= length-of p
      0.001 <= abs x
    ] [ ; trunc decimal part
      remove/part (skip tail r negate n) n
    ]
    ; convert to exp. not.
    1 < abs x [
      r: fmt 1 + abs wid x *
        either 1e10 > abs x [1e90] [1e100]
      remove next next find r "e"
      r: trim r
    ]
    # [
      r: fmt 1 + abs wid x *
        either 1e-10 < abs x [1e-90] [1e-100]
      remove next next find r "e"
      r: trim r
    ]
  ]
  return format wid r
]

matrix-format: func [
  value [custom-type!]
  /wid [integer!] "width & align as in format; if 0, show only sign"
  /log [integer!] "as wid, but show order of maglitude"
  /tol "0 if abs(x) <= tol"
] [
  wid: default [log]
  wid: default [
    negate max 5 to-integer round/floor
    ( matrix!.width / value.ncols )
  ]
  tol: default [0]
  let r: unspaced ["[ " value.nrows "x" value.ncols if log [" <LOG>"]]
  let v: value.data
  let x
  let i: 1
  repeat value.nrows [
    append r "^/   "
    if wid = 0 [
      repeat value.ncols [
        append r space
        append r case [
          tol >= abs x: v.(i) ["0"]
          x > 0 ["+"]
          x < 0 ["-"]
        ]
        i: i + 1
      ]
    ] else [
      repeat value.ncols [
        x: v.(i)
        if log [
          x: either tol < x: abs x
          [ log-10 x ] [ "-∞" ]
        ]
        append r fmt wid x
        i: i + 1
      ]
    ]
  ] append r "^/]"
]

matrix!.form: :matrix-format
; PICK, POKE

matrix!.pick: function [
		matrix
		index [block! integer!]
	][
  if block? index [
    index: index.1 - 1 * matrix.ncols + index.2
  ]
  pick matrix.data index
]

matrix!.poke: function [
		matrix 
		index [block! integer!]
    value [any-number!]
	][
  if block? index [
    index: index.1 - 1 * matrix.ncols + index.2
  ]
  poke matrix.data index value
]


; ARITHMETIC

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
  if not all [matrix? a, matrix? b]
  [ fail "Can't multiply" ]
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


id-matrix: function [
    {Make identity matrix n x n}
    n [integer!]
  ][
  m: make-matrix [n n]
  p: m.data
  for i n [
    p.(n + 1 * i - n): 1
  ]
  m
]

; TRANSFORM

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

dilate: func [
    "Apply dilatation to colums (rows) of m" 
    m "matrix or vector (modified)"
    v [vector!]
      "dilatation vector"
    k "dilatation factor, -1 for reflection"
    /skip [integer!] "skip columns"
    /rows "apply to rows"
    /both "apply to rows and columns"
  ][
  let [p r c i j l s]
  if not skip [skip: 0]
  if vector? m [
    p: m
    r: c: 1
    if rows [c: length-of m]
    else [r: length-of m]
  ] else [
    p: m.data
    r: m.nrows
    c: m.ncols
  ]
  l: length-of v
  ;; normalize v
  s: 0
  for i l [s: v.(i) * v.(i) + s]
  s: square-root s
  if zero? s [return]
  for i l [v.(i): v.(i) / s]
  if rows or (both) [
    cfor y 1 + skip r 1 [
      s: 0
      ; [c-l+1, y]
      i: y * c - l + 1
      for j l [
        s: p.(i) * v.(j) + s
        i: i + 1
      ]
      s: k - 1 * s
      i: i - l
      for j l [
        p.(i): me + (v.(j) * s)
        i: i + 1
      ]
    ]
  ]
  if both or (not rows) [
    cfor x 1 + skip c 1 [
      s: 0
      i: r - l * c + x
      for j l [
        s: p.(i) * v.(j) + s
        i: i + c
      ]
      s: k - 1 * s
      i: i - (l * c)
      for j l [
        p.(i): me + (v.(j) * s)
        i: i + c
      ]
    ]
  ]
  m
]

reflect-both: specialize :dilate [k: -1 both: #]

reflect-columns: specialize :dilate [k: -1]

reflect-rows: specialize :dilate [k: -1 rows: #]


; FACTORIZATION

tri-factor: function [a b /symm /transpose] [
  r: a.nrows
  c: a.ncols
  p: a.data
  l: min r c
  i: 0
  t: 0
  norm: vector-norm p
  if symm [ l: l - 1, v: make-vector r - 1 ]
  else [ v: make-vector r ]
  y: 1
  for x l [
    s: 0
    i: r * c + x
    j: 1 + length-of v
    loop [j > y] [
      j: j - 1
      i: i - c
      v.(j): t: p.(i)
      s: t * t + s
      p.(i): 0
    ]
    s: square-root s
    if norm * 1e-9 > abs s [s: 0]
    p.(i): s
    v.(j): v.(j) - s
    loop [j > 1] [j: j - 1, v.(j): 0]
    if s = 0 [continue]
    reflect-columns/skip a v x
    if symm [reflect-rows/skip a v x - 1]
    if transpose [reflect-rows b v]
    else [reflect-columns b v]
    y: y + 1
  ]
]

qr-factor: func [
  m [custom-type!] "modified"
  return: [custom-type!]
  r: [custom-type!]
] [
  let [q t]
  t: either r [m-copy m] [m]
  assert [matrix? m]
  q: id-matrix m.nrows
  tri-factor/transpose t q
  if r [set r t]
  return q
]



; SOLVE, INVERT

solve: function [a b /copy] [
  if copy [
    a: m-copy a
    b: m-copy b
  ]
  r: a.nrows, c: a.ncols, pa: a.data
  cb: b.ncols, rb: b.nrows, pb: b.data
  assert [rb = r]

  res: make-matrix :[c cb]
  p: res.data
  tri-factor a b
  
  ; find last non zero row
  x: i: 0, y: 1
  forever [
    if (x: x + 1) > c [break]
    i: i + 1
    if pa.(i) != 0 [
      if (y: y + 1) > r [break]
      i: i + c
      continue
    ]
  ]
  y: y - 1
  assert [y > 0]

  loop [y > 0] [
    ; find first non zero element
    x: 0, i: y - 1 * c
    until [x: x + 1, i: i + 1, pa.(i) != 0]
    for k cb [
      t: 0
      i: y * c
      j: c - 1 * cb + k
      repeat c - x [
        t: pa.(i) * p.(j) + t
        i: i - 1, j: j - cb
      ]
      p.(j): pb.(y - 1 * cb + k) - t / pa.(i)
    ]
    y: y - 1
  ]
  return res
]

?: enfix specialize :solve [copy: #]

right-inverse: func [m [custom-type!]] [
  let i: id-matrix m.nrows
  return m ? i
]


; vim: set et sw=2:
