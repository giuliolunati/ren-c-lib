REBOL [ 
  Title: "ASCII plot tools"
  Type: 'module
  Name: 'aplot
  Author: "giuliolunati@gmail.com"
]

left: 0 step: 1
dot: #"*"
line: copy ""

histogram: function [x /two x2] [
  clear line
  x: if x [to-integer x - left / step + 1]
    else [0]
  if two [
    x2: if x2
    [ to-integer x2 - left / step + 1 ]
    else [0]
    single: if x > x2 ["'"] else [","]
    append/dup line "¦" min x x2
    append/dup line single abs x - x2
  ] else [
    append/dup line dot x
  ]
]

scale: function [width n] [
  d: n * step
  x: power 10 round/ceiling log-10 d
  for-each i [0.2 0.5 1] [
    if x * i >= d [d: x * i break]
  ]
  s: append/dup (make text! 0) space width + 1
  a: round/ceiling/to left d
  b: width * step + left
  for x a b d [
    i: to-integer round x - left / step + 1
    change at s i "^^"
    change at s i + 1 format n - 1 x
  ]
  s
]
; vim: set syn=rebol sw=2 ts=2:
