cmp: function [a b] [
  a: words of a
  b: words of b
  to-logic all [
    empty? exclude a b
    empty? exclude b a
  ]
]

add-to: function [group [map!] v] [
  flag: true
  while [flag] [
    flag: false
    for-each x group [
      y: x . v
      if not find group y [
        lock y
        group/:y: flag: true
      ]
      y: v . x
      if not find group y [
        lock y
        group/:y: flag: true
      ]
    ]
  ]
  group
]

normalize: function [n [map!] g [map!]] [
  flag: true
  while [flag] [
    flag: false
    for-each x g [
      if find n x [continue]
      for-each y n [
        z: (inv x) . y . x
        if not find n z [
          flag: true
          add-to n z
        ]
      ] 
    ]
  ]
  n
]

; rubik group

; Front Back
; Right Left
; Up Down

cube: {

      2-----------3        +-----4-----+
     /'          /|       /'          /| 
    / '         / |     11 '         2 | 
   /  '        /  |     /  9        /  12 
  1-----------4   |    +-----1-----+   | 
  |   '       |   |    |   '       |   | 
  |   7 . . . | . 6    |   . . . 7 | . + 
  |  ,        |  /     6  ,        3  /  
  | ,         | /      | 8         | 5  
  |,          |/       |,          |/    
  8-----------5        +----10-----+
}

null: [
  corn-pos [0 0 0 0 0 0 0 0]
  corn-or [0 0 0 0 0 0 0 0]
  edge-pos [ 0 0 0 0 0 0 0 0 0 0 0 0]
  edge-or [ 0 0 0 0 0 0 0 0 0 0 0 0]
  form ""
  parent _
]
id: [
  corn-pos [1 2 3 4 5 6 7 8]
  corn-or [1 1 1 1 1 1 1 1]
  edge-pos [ 1  2  3  4  5  6  7  8  9 10 11 12]
  edge-or [ 1  1  1  1  1  1  1  1  1  1  1  1]
  form ""
]
f: [
  corn-pos [4 2 3 5 8 6 7 1]
  corn-or [2 1 1 3 2 1 1 3]
  edge-pos [ 3  2 10  4  5  1  7  8  9  6 11 12]
  edge-or [ 2  1  2  1  1  2  1  1  1  2  1  1]
  form "f"
]
b: [
  corn-pos [1 7 2 4 5 3 6 8]
  corn-or [1 3 2 1 1 3 2 1]
  edge-pos [ 1  2  3  9  5  6 12  8  7 10 11  4]
  edge-or [ 1  1  1  2  1  1  2  1  2  1  1  2]
  form "b"
]
r: [
  corn-pos [1 2 6 3 4 5 7 8]
  corn-or [1 1 3 2 3 2 1 1]
  edge-pos [ 1 12  2  4  3  6  7  8  9 10 11  5]
  edge-or [ 1  1  1  1  1  1  1  1  1  1  1  1]
  form "r"
]
l: [
  corn-pos [8 1 3 4 5 6 2 7]
  corn-or [3 2 1 1 1 1 3 2]
  edge-pos [ 1  2  3  4  5  8  7  9 11 10  6 12]
  edge-or [ 1  1  1  1  1  1  1  1  1  1  1  1]
  form "l"
]
u: [
  corn-pos [2 3 4 1 5 6 7 8]
  corn-or [1 1 1 1 1 1 1 1]
  edge-pos [11  1  3  2  5  6  7  8  9 10  4 12]
  edge-or [ 1  1  1  1  1  1  1  1  1  1  1  1]
  form "u"
]
d: [
  corn-pos [1 2 3 4 6 7 8 5]
  corn-or [1 1 1 1 1 1 1 1]
  edge-pos [ 1  2  3  4  7  6  8 10  9  5 11 12]
  edge-or [ 1  1  1  1  1  1  1  1  1  1  1  1]
  form "d"
]

.: enfix function [#a #b] [
  r: copy/deep a
  ro: r/corn-or ao: a/corn-or bo: b/corn-or
  rp: r/corn-pos ap: a/corn-pos bp: b/corn-pos
  repeat i 8 [
    j: ap/:i  rp/:i: bp/:j
    ro/:i: 1 + mod (ao/:i + bo/:j + 1) 3
  ]
  ro: r/edge-or ao: a/edge-or bo: b/edge-or
  rp: r/edge-pos ap: a/edge-pos bp: b/edge-pos
  repeat i 12 [
    j: ap/:i  rp/:i: bp/:j
    ro/:i: 1 + mod (ao/:i + bo/:j) 2
  ]
  r/form: lock join-of a/form b/form
  r
]

;; definitions
  f2: f . f
  f2/form: "f2"
  f': f2 . f
  f'/form: "f'"
  b2: b . b
  b2/form: "b2"
  b': b2 . b
  b'/form: "b'"
  r2: r . r
  r2/form: "r2"
  r': r2 . r
  r'/form: "r'"
  l2: l . l
  l2/form: "l2"
  l': l2 . l
  l'/form: "l'"
  u2: u . u
  u2/form: "u2"
  u': u2 . u
  u'/form: "u'"
  d2: d . d
  d2/form: "d2"
  d': d2 . d
  d'/form: "d'"

move: function [s [string!] /count] [
  ret: copy id
  n: 0
  m: _
  parse s [ any [
    [ "f" 
      [ "2" (m: f2) 
      | "'" (m: f')
      | (m: f)
      ]
    | "b"
      [ "2" (m: b2)
      | "'" (m: b')
      | (m: b)
      ]
    | "r"
      [ "2" (m: r2)
      | "'" (m: r')
      | (m: r)
      ]
    | "l"
      [ "2" (m: l2)
      | "'" (m: l')
      | (m: l)
      ]
    | "u"
      [ "2" (m: u2)
      | "'" (m: u')
      | (m: u)
      ]
    | "d"
      [ "2" (m: d2)
      | "'" (m: d')
      | (m: d)
      ]
    ] (ret: me . m)
  ] ]
  ret
]

check: function [pos filter] [
  if find filter 'corn-pos [
    p: pos/corn-pos
    f: filter/corn-pos
    repeat i 8 [
      if f/:i = 0 [continue]
      if p/:i != f/:i [return false]
    ]
  ]
  if find filter 'corn-or [
    p: pos/corn-or
    f: filter/corn-or
    repeat i 8 [
      if f/:i = 0 [continue]
      if p/:i != f/:i [return false]
    ]
  ]
  if find filter 'edge-pos [
    p: pos/edge-pos
    f: filter/edge-pos
    repeat i 12 [
      if f/:i = 0 [continue]
      if p/:i != f/:i [return false]
    ]
  ]
  if find filter 'edge-or [
    p: pos/edge-or
    f: filter/edge-or
    repeat i 12 [
      if f/:i = 0 [continue]
      if p/:i != f/:i [return false]
    ]
  ]
  true
] 

last-move: function [m] [
  m: back tail m
  if find "2'" m [m: back m]
  m
]

moves: reduce [
  ( ;1
    m: make map! 6
    for-each x ["f" "f2" "r" "r2" "u" "u2"]
    [ m/:x: move x ]
    m
  ) ( ;2
    m: make map! 6
    for-each x [
      "fu" "fu2" "fu'" "fr" "fr2" "fr'"
      "f2u" "f2u2" "f2r" "f2r2"
      "ru" "ru2" "ru'" "rf" "rf2" "rf'"
      "r2" "r2u2" "r2f" "r2f2"
      "uf" "uf2" "uf'" "ur" "ur2" "ur'"
      "u2f" "u2f2" "u2r" "u2r2"
    ] [ m/:x: copy null ]
    m
  )
]

gen-moves: function [m deep] [
  c1: first last-move m
  for-each x reduce [f f2 f' b b2 b' u u2 u' d d2 d' r r2 r' l l2 l'] [
    c2: first x/form
    if any [
      c1 = c2
      all [c1 = #"b" c2 = "f"]
      all [c1 = #"l" c2 = "r"]
      all [c1 = #"d" c2 = "u"]
    ] [continue]
    x: join-of m x/form
    if deep > 1 [gen-moves x deep - 1]
  ]
]
for-each m moves/2 [
  gen-moves m to-integer system/options/args/1
]
;; vim: set sw=2 ts=2 sts=2:
