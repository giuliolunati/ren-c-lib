REBOL [ 
  Title: "Statistical stuff"
  Type: module
  Name: stat
  Author: "giuliolunati@gmail.com"
]

sx: sy: sx2: sy2: sxy: sn: _

clear: func [] [
  sx: sy: sx2: sy2: sxy: sn: 0
]

put: func [
    x y
    /w "weight"
  ][
  w: default [1]
  sx: me + (w * x)
  sy: me + (w * y)
  sx2: me + (w * (x * x))
  sy2: me + (w * (y * y))
  sxy: me + (w * (x * y))
  sn: me + w
]

linear-regression: func [m: q:] [
  m: (sn * sxy - (sx * sy))
  / (sn * sx2 - (sx * sx))
  q: sy - (m * sx) / sn
  return reduce [q m]
]

; vim: set sw=2 rs=2 sts=2:
