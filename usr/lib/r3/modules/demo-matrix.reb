REBOL [
  Title: "Demo for 'matrix module"
  Type: script
  Require: [matrix custom-types]
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
]

import %demo.reb

;;; MAIN

demo [
  _
  "=== DEMO FOR MATRIX MODULE ==="
  input
  _
  "Import the module:"
  (matrix: import 'matrix)
  _
  {It provides the custom-type MATRIX!:
  MATRIX! is the prototype for concrete matrices, made with MAKE-MATRIX [rows cols data]}
  [ M: make-matrix [2 3 [1 2 3 4 5 6]]
    same? M.custom-type matrix!
  ]
  [ M.nrows ]
  [ M.ncols ]
  {MATRIX? is a shortcut for the former test }
  [matrix? M]
  _
  {DO-CUSTOM enables the custom methods:}
  [do-custom [form M]]
  _
  {PICK, POKE:
    index = [r c] => M[r,c]
    integer = n => n-th element, in row order
  }
  [do-custom [pick M 4]]
  [do-custom [poke M 4 -4]]
  [do-custom [form M]]
  [do-custom [poke M [2 1] 4]]
  [do-custom [pick M [2 1]]]
  _
  "NEGATE, TRANSPOSE, ID-MATRIX: "
  [do-custom [form negate M]]
  [do-custom [form T: transpose M]]
  [do-custom [form I3: id-matrix 3]]
  _:
  "Arithmetics:"
  [do-custom [form :[M + M, M - M]]]
  [do-custom [form :[
    M * T
    T * M
  ]]]
  _
  "SOLVE, LEFT DIVISION"
  "'?' is the left division: M * (M ? B) = B"
  [ do-custom [
    M: make-matrix [ 3 3 [
      1 2 3
      0 4 7
      5 6 0
    ]]
    B: make-matrix [3 1 [ 4 0 -1]]
    X: M ? B
    form M * X
  ]]
  "It doesn'T modify operands:"
  [ do-custom [-- (form M) -- (form B)]]
  {SOLVE do the same, but modifies operands.
   NOTE: It doesn'T return the result, but store it in B.} 
  [do-custom [
    M2: copy/deep M
    solve M2 B
    -- (form M2) -- (form B) -- (form X)
  ]]
  _
  "RIGHT INVERSE"
  [do-custom [
    I: right-inverse M
    form M * I
  ]]
  _
  "QR factorization:"
  [ do-custom [
    M: make-matrix [ 4 4 [
      1 2  3 3
      0 4  4 7
      5 6 11 0
      2 1  3 0
    ]]
    [Q T]: qr-factor M
    -- (form T)
    -- (form M)
    -- (form Q * T)
  ]]
  "... and its modifyng version (T replaces M)"
  [ do-custom [
    M2: copy/deep M
    Q: qr-factor M2
    -- (form M2)
  ]]
  _
  {As the factorization shows, M has rank 3,
  so M * x = B probably hasn't exact solution}
  {In that case, SOLVE minimizes the error E,
  i.e. the columns of E and M are orthogonal.}
  [ do-custom [
    B: make-matrix [4 3 [
      2 -1 6
      0  1 3
      -2 4 1
      5 -2 3
    ]]
    X: solve M B
    E: M * X - B
    form (transpose E) * M
  ]]
  _
]

; vim: set et sw=2:
