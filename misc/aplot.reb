REBOL [ 
  Title: "ASCII plot tools"
  Type: 'module
  Name: 'aplot
  Author: "giuliolunati@gmail.com"
]

left: 0 step: 1
dot: #"*"
line: copy ""

histogram: function [x /two x2 /label text] [
  clear line
  if label [append line text]
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

; vim: set syn=rebol sw=2 ts=2:
