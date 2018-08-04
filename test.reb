import 'complex

customize self

random/seed now

rand: enclose :random function [f] [
  v: f/value
  f/value: v + v
  (do f) - v
]

!~: enfix function [a b] [
  1e-9 < (abs a / b - 1)
]

failed: function [] [print "FAILED!" quit]

crand: function [x] [
  to-complex reduce [rand x rand x]
]

write-stdout "Test: sin (a + b) ... "
loop 10 [
  a: crand 10.0
  b: abs a
  b: crand b / 2
  c: a + b
  t: (sin a) * (cos b) + ((cos a) * (sin b))
  if (sin c) !~ t [failed]
]
print "OK."

write-stdout "Test: deg-vs-rad (1) ... "
loop 10 [
  r: crand 10.0
  d: r * 180 / pi
  if (sin r) !~ (sine d) [failed]
  if (cos r) !~ (cosine d) [failed]
  if (tan r) !~ (tangent d) [failed]
  if (sin r) !~ (sine/radians r) [failed]
  if (cos r) !~ (cosine/radians r) [failed]
  if (tan r) !~ (tangent/radians r) [failed]
  if (asin r) * 180 !~ (arcsine r) * pi [failed]
  if (acos r) * 180 !~ (arccosine r) * pi [failed]
  if (atan r) * 180 !~ (arctangent r) * pi [failed]
  if (asin r) !~ (arcsine/radians r) [failed]
  if (acos r) !~ (arccosine/radians r) [failed]
  if (atan r) !~ (arctangent/radians r) [failed]
]
print "OK."

write-stdout "Test: arc-* functions ..."
loop 10 [
  v: crand 10.0
  if (sin asin v) !~ v [failed]
  if (cos acos v) !~ v [failed]
  if (tan atan v) !~ v [failed]
]
print "OK."


; vim: set sw=2 expandtab:
