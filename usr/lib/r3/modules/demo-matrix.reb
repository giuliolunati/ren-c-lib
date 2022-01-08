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
  (import 'matrix)
  _
  {It provides the custom-type matrix!
  A CUSTOM-TYPE is a special map! :}
  [mold matrix!]
  _
  {It contains the custom methods, plus the CUSTOM-TYPE key, that refers to the map itself:}
  [same? matrix! matrix!.custom-type]
  "MATRIX! is the prototype for concrete matrices, made with MAKE-MATRIX [rows cols data]"
  (m: make-matrix [2 3 [1 2 3 4 5 6]])
  [same? matrix! m.custom-type]
  [m.nrows]
  [m.ncols]
  [m.data]
  _
  {The fun starts!
  When the code is executed with DO-CUSTOM, the custom methods are enabled:}
  [do-custom [form m]]
  "(m has been form'ed through the custom method m.custom-type.form i.e. matrix!.form)"
  _
  "Now some math:"
  [do-custom [form :[m + m, m - m]]]
  [do-custom [form t: transpose m]]
  [do-custom [form :[
    m * t
    t * m
  ]]]
]

; vim: set et sw=2:
