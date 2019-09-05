#!/usr/bin/r3
REBOL []
; card:
; [
;  1: Question
;  2: Answer
;  3: q: Last quality [0-5]
;  4: d: Delay = t - date of last repetition
;  5: t: Date of next repetition
; ]

context-length: 4
tmin: 60
zone: now/zone
rate: 0

t-factor: func[
  q1 [any-number!] q2 [any-number!]
  ][ 2 ** ((3 * q2) - q1 - 8 / 2)
]

fix-date: function [d t [time!]] [
  if any [not date? d | set? 'd/zone] [return d]
  d: d + t
  d/zone: t
  d
]

load-desk: function [
    desk [file! text! block! blank!]
	][
  if not desk [fail "Missing desk!"]
  text: make block! 0 x: _
  if all [file? desk not exists? desk] [
    desk: make block! 16
  ]
  if not block? desk [desk: load/all/type desk _]
  parse desk [while
    [ set x remove text! (append text x)
    | skip ]
  ]
  if empty? text [text: _]
  else [
    assert [(length of desk) <= (length of text)]
    while [(length of desk) < (length of text)] [
      repend/only desk [1 + length of desk _ _ _ _]
    ]
  ]
  set 'rate 0
	repeat i length of desk [
    d: desk/:i
    new-line/all d false
    while [6 > length of d] [append d _]
    d/6: i
    if d/4
    [ set 'rate (86400 / d/4 + rate) ] ; queries/day
    d/5: fix-date d/5 zone ; next date
	]
	reduce [desk text]
]

save-desk: func [
    desk [block!]
    text [block! blank!]
    out [file!]
  ][
  sort/compare desk :cmp5
  new-line/all desk true 
  write out mold/only desk
  if text [
    write/append out reduce [newline mold/only text]
  ]
]

add-cards: function [
    desk [block!]
    src [file! text!]
    /two
    /txt
  ][
  spc: charset " ^-"
  if txt [
    src: read/lines src
    for-next src src [
      if parse src/1 [any spc] [
        remove src src: back src
      ]
    ]
    d: desk
    for-next desk desk
    [ if block? desk/1 [d: desk break] ]
    insert d src
    d: (index-of d) - 1 
    repeat i length of src [
      repend/only desk [i + d _ _ _ _]
    ]
  ] else [
    src: load/type src _
    new-line/all src false
    forskip src 2 [
      if tail? next src [break]
      repend/only desk [src/1 src/2 _ _ _]
      if two [
        repend/only desk [src/2 src/1 _ _ _]
      ]
    ]
  ]
  desk
]

cmp45: func [a [block!] b [block!]] [
  case [
    all [a/4 | not b/4] [true]
    all [b/4 | not a/4] [false]
    all [not a/4 | not b/4] [a/6 < b/6]
    a/4 < b/4 [true]
    a/4 > b/4 [false]
    all [a/5 | b/5 ] [a/5 < b/5]
  ] else [a/6 < b/6]
]

cmp5: func [a [block!] b [block!]] [
  case [
    all [a/5 | not b/5] [true]
    all [b/5 | not a/5] [false]
    all [not a/5 | not b/5] [a/6 < b/6]
  ] else [a/5 < b/5]
]

stats: function [
    desk [block!]
    /only
  ][
  w: r: 0
  t: now
  t0: _
  s: append make block! 10 [0 0 0 0 0 0]
  for-each x desk [
    if x/3 [
      i: x/3 + 1
      s/:i: s/:i + 1
    ]
    if x/4 [r: 1 / x/4 + r]
    if x/5 [
      if x/5 < t [
        w: (subtract-date t x/5) / x/4 + w
      ]
      if any [not t0 | x/5 < t0] [t0: x/5]
    ]
  ]
  r: r * 86400
  if only [return r]
  repend s ['rate r 'older t0 'delay w]
]

print-stats: function [
    desk [block!]
  ][
  s: stats desk
  x: 0
  for i 6 1 -1 [
    x: x + s/:i
    print ["  "
      i - 1
      to-percent round/to/ceiling (x / length of desk) .01
    ]
  ]
  print ["  q/day:" to-integer s/rate]
  print ["  delay:" s/delay]
  older: s/older
  if older [
    print ["  wait:" to-time subtract-date older now]
    print ["  " older]
  ]
]
  
subtract-date: function [a [date!] b [date!]] [
  a/date - b/date * 86400 + to-integer (a/time - b/time)
]

;; MAIN
cd :system/options/path
arg: system/options/args
cmd: src: desk-file: last-q: _
t0: now

for-next arg arg [
  case [
    "-auto" = arg/1 [
      arg: next arg
      b: make block! 16
      r: 0
      t: x: _
      for-next arg arg [
        desk: first load-desk to-file arg/1
        if not trap [desk/1/5 > t0] [continue]
        s: stats desk
        repend/only b [
          s/delay
          s/rate
          arg/1
        ]
      ]
      if empty? b [quit]
      sort/all b
      for-each b b [
        print format [-6 -8 " "] reduce [
          round/ceiling/to b/1 0.1
          round/to b/2 0.1
          b/3
        ]
      ]
      print format [-6 -8 " "]
      [ "DELAY" "Q/DAY" "FILE" ]
      b: last b
      desk-file: to-file b/3
      print ["^/Opening" desk-file]
      write-stdout "Hit ENTER when ready.^/"
      input
      break
    ]
    "-stat" = arg/1 [
      arg: next arg
      if 1 < length of arg [
        b: make block! 16
        r: 0
        t: x: _
        for-next arg arg [
          desk: first load-desk to-file arg/1
          s: stats desk
          r: r + s/rate
          o: s/older
          if any [not t | all [o o < t]] [t: o]
          repend/only b [
            s/delay
            s/rate
            arg/1
          ]
        ]
        sort/all b
        for-each b b [
          print format [-6 -8 " "] reduce [
            round/ceiling/to b/1 0.1
            round/to b/2 0.1
            b/3
          ]
        ]
        print format [-6 -8 " "]
        [ "DELAY" "Q/DAY" "FILE" ]
        print format [-6 -8] reduce
        [ "=====" to-integer r " ======" ]
        t: subtract-date t now
        if t > 0 [print format 14 reduce
        [ " wait for:" space to-time t ]]
        quit
      ]
      else [
        print-stats first load-desk to-file arg/1
        quit
      ]
    ]
    find ["+" "+2" "+txt"] arg/1
    [ cmd: arg/1 | src: to-file arg/2 | arg: next arg ]
    true [desk-file: to-file arg/1]
  ]
]
set [desk text] load-desk desk-file
if text [sort desk]
else [sort/compare desk :cmp45]
if cmd [ case [
  cmd = "+" [
    save-desk
      add-cards desk src
      _
      desk-file
    quit
  ]
  cmd = "+2" [
    save-desk
      add-cards/two desk src
      _
      desk-file
    quit
  ]
  cmd = "+txt" [
    save-desk
      add-cards/txt desk src
      _
      desk-file
    quit
  ]
]]

do-command: function [] [
  c: input
  if c = "" [return _]
  case [
    c = "q" [quit]
    c = "x" [
      save-desk desk text desk-file
      print-stats desk
      quit
    ]
    c = "w" [
      save-desk desk text desk-file
    ]
    c = "?" [
      print-stats desk
    ]
    c/1 = #"%" [
      save-desk desk text to-file next c
      print-stats desk
      quit
    ]
  ]
  c
]

forever [
  t: now
  d: d0: _
  for-each x desk [
    if all [x/5 | any [not d0 | x/5 < d0/5]] [d0: x ]
    if all [x/5 | x/5 > t] [continue]
    d: x
    break
  ]
  print ["  (" round/to rate 0.1 " queries/day)"] 
	if not d [
    print ["retry at" d0/5]
    print ["[" to-time subtract-date d0/5 now "]"]
    do-command
    continue
  ]
  assert [any [not d/5 | d/5 <= t]]
	if text [
    i: d/1
    if any [not last-q | last-q + 1 != i] [
	    print "  ================="
      p: skip at text i 1 - context-length
      for-next p p [
        print p/1
        if i = index-of p [break]
      ]
    ]
	  write-stdout if d/5 ["  ............... ? "]
    else ["  ............... [NEW] ? "]
    last-q: i
  ]
  else [
	  print "  ================="
    print form reduce d/1
	  write-stdout case [
      d/5 ["? "]
      d/2 ["[NEW] ? "]
    ] else ["  >>>>>>>>>>>>>>>>> "]
  ]
  uinput: do-command
  bind d 'uinput
  d/2: default [uinput]
  if text [print (
    if i < length of text [text/(i + 1)]
    else ["=== END ==="]
  )]
  else [
    trap [q: reduce d/2]
    print form q
    if error? q [continue]
  ]
  print "  -----------------"
  write-stdout "  quality? [0-5] > "
  while [not attempt [q: to-integer do-command]] []
  if q < 0 [q: 0]
  if q > 5 [q: 5]
  d/3: default [0]
  if d/4 [set 'rate (-86400 / d/4 + rate)]
  d/4: default [tmin / t-factor 0 0]
  ;if d/5 [d/4: d/4 + subtract-date t d/5]
  t: t-factor d/3 q
  t: 0.95 + (random 0.1) * t
  t: d/4 * t
  if q < 3 [
    t: exp (
      q * (log-e t)
      + (3 - q * log-e tmin)
      / 3
    )
  ]
  d/4: if t < tmin [tmin] else [t]
  set 'rate (86400 / d/4 + rate)
  d/3: q
  d/5: now + (d/4 / 86400)
  d/5: fix-date d/5 zone
	if text [sort desk]
  else [sort/compare desk :cmp45]
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
