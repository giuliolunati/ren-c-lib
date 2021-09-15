#!/usr/bin/r3
REBOL[]

format: function [format data] [
  r: make text! 0
  format: my blockify
  data: my blockify
  for-each f format [
    if integer? f [
      x: form data/1
      l: length-of x
      if l > abs f [
        clear at x 1 + abs f
      ] else [if l < abs f [
        if f >= 0 [
          append/dup x " " (abs f) - l
        ] else [
          insert/dup x " " (abs f) - l
        ]
      ]]
      data: my next
    ] else [
      x: form f
    ]
    append r x
  ]
  r
]

usage: {ARGS:
  INPUT-FILE [TIME] # trend
}
sqrt: :square-root
stat: import 'stat
aplot: import 'aplot

plot: function [d wid] [
  a: b: d/2
  t: d/1
  for-skip x d 2 [
    if x/2 < a [a: x/2]
    if x/2 > b [b: x/2]
    if x/1 < t [t: x/1]
  ]
  t: zero + t
  aplot/left: a
  aplot/step: b - a / wid
  forever [
    if tail? d [break]
    a: b: false
    if (zero + d/1 - t) = 0 [
      a: d/2
      d: skip d 2
    ]
    if all [not tail? d (zero + d/1 - t) = 1]
    [
      b: d/2
      d: skip d 2
    ]
    print unspaced [
      format [-2 "/"] (t/day)
      format wid aplot/histogram/x2 a b
      space opt format -5 a
    ]
    t: t + 2
  ]
]

last-days: function [d days] [
  for-skip d d 2 [
    if d/1 + days > 0 [return d]
  ]
  tail d
]

bound: function [v b d] [
  v: case [
    v < (b - d) [b - d]
    v > (b + d) [b + d]
  ] else [v]
  v
]

trend: function [d n] [
  stat/clear
  for-skip d d 2 [
    if d/1 + n < 0 [continue]
    stat/put d/1 d/2
  ]
  o: stat/linear-regression
]

load-data: function [lines] [
  d: make block! 0
  t0: _
  for-each l lines [
    parse l [
      copy date to space
      skip
      copy rest to end
    ]
    peso: try attempt [to-decimal trim rest]
    if not date? date [date: my to-date]
    if not date/time [date/time: 8:00:00]
    date/zone: zero/zone
    rest: trim rest
    t: date - zero
    p0: peso
    case [
      peso [
        if t0 and (1 < n: t - t0) [
          dp: (peso - last d) / n
          for i n - 1 [
            append d reduce head mutable [
              t0 + i
              peso - (n - i * dp)
            ]
          ]
        ]
        t0: t
        append d :[t peso]
      ]
      rest = "-" [tot: me + 1]
      ;rest = "+" [t+: t]
    ]
  ]
  new-line/all d false
  new-line/skip d true 2
]

smooth-0: function [data k] [
  if not k [return data]
  y: map-each [t p] data [p]
  l: length-of y
  d: make block! l
  append/dup d 1 + k l
  d/1: d/:l: 1
  x: copy d
  repeat l - 1 [
    c: k / d/1
    d/2: me - (k * c) 
    y/2: me + (y/1 * c)
    d: next d
    y: next y
  ]
  x: back tail x
  x/1: 1 - k * y/1 / d/1
  repeat l - 1 [
    x: back x
    y: back y
    d: back d
    x/1: k * x/2 + (1 - k * y/1) / d/1
  ]
  d: copy data
  repeat l [d/2: x/1 d: skip d 2 x: next x]
  head d
]

smooth-1: function [data k] [
  if any [not k, k = 0] [return data]
  k: 1 / k
  y: map-each [t p] data [p * k]
  l: length-of y
  d: make block! 5 * l
  append/dup d
    reduce [1  -4  6 + k  -4  1]
    l
  d/3: 1 + k
  d/7: d/4: -2
  d/8: 5 + k
  d: skip tail d -10
  d/3: 5 + k
  d/7: d/4: -2
  d/8: 1 + k
  d: head d
  ; d: matrice 5-diagonale 
  ; d3  d4  d5              . | y1
  ; d7  d8  d9  d10         . | y2
  ; d11 d12 d13 d14 d15     . | y3
  ;     d16 d17 d18 d19 d20 . | y4
  ; ......................... | ..
  for-skip d d 5 [
    y/2 or (break)
    c: d/7 / d/3
    d/8: me - (c * d/4)
    d/9: me - (c * d/5)
    y/2: me - (c * y/1)
    if y/3 [
      c: d/11 / d/3
      d/12: me - (c * d/4)
      d/13: me - (c * d/5)
      y/3: me - (c * y/1)
    ]
    y: next y
  ]
  d: tail d
  y: tail y
  loop [not head? y] [
    d: skip d -5
    y: back y
    if y/2 [y/1: me - (y/2 * d/4)]
    if y/3 [y/1: me - (y/3 * d/5)]
    y/1: me / d/3
  ]
  d: copy data
  repeat l [d/2: y/1 d: skip d 2 y: next y]
  head d
]

smooth-2: function [data k] [
  if k = 0 [return copy data]
  k: 1 / (k + 1)
  d: copy data
  for-skip d d 2 [
    if 6 > length-of d [break]
    d/6: me * k + (
      (1 - k) * (d/4 * 2 - d/2)
    )
  ]
  head d
]

score: function [d data] [
  stat/clear
  x: d/2 - data/2
  l: length-of d
  cfor i 4 l 2 [
    y: d/:i - data/:i
    stat/put x y
    x: y
  ]
  o: stat/linear-regression
  reduce [o/q o/m] 
]
    
;; MAIN ;;

args: system/options/args
argc: length of args

if argc > 3 [
  print usage quit 0
]

zero: now

change-dir :system/options/path

days: any [
  attempt [reduce [to-decimal args/2]] 
  [60 15 4]
]
if not empty? args [
  data: read/lines to-file args/1
] else [
  data: make block! 0
  for-each l read-lines _ [append data l]
]
data: load-data data
d: data
;print mold/only d quit 0
for-next days days [
  if head? days [
    data: last-days d days/1 + 1
    plot
      fit: smooth-1 data 1
      36
    print unspaced [
      "   " aplot/scale 36 6]
  ]
  [p t]: unpack trend fit days/1
  print [
    format ["giorni " -3 -8 -5 -7] reduce [
      to-integer days/1
      round/to p 0.01
      to-integer round t * 1000
      to-integer round t * 1000 * days/1
    ]
  ]
]

; vim: set sw=2 rs=2 sts=2:
