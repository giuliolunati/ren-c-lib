import 'rem
import 'html

for-each x [
  [br]
  [p]
  [p "<testo&html>"]
  [p ["---" br "==="]]
  [p /align 'center "text"]
  [p #id .claz "text"]
  [a http://a.b "text"]
  [img %../]
  [p bg: 'red font: "bo?"]
  [(x: rem "a" br "b") p x]
  [(f: func [x y] [rem [b x br i y]]) f 3 4] 
  [style {p {bg: red}}]
][
  unless block? x [quit]
  print '=====
  probe mold-html
  probe load-rem
  probe x
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
