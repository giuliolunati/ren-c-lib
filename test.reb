matrix: import 'matrix
customize self

m: make matrix! [2 3 [1 2 3 4 5 6]]
print [pick m 2x2] quit 
t: transpose m
t: t * m
print [t]
q: id-matrix t/nrows
tri-reduce/also/symm t q
print [t]
print [(transpose q) * t * q]
quit
print [m + m]
print [m * t]
print [t * m]


; vim: set sw=2 expandtab:
