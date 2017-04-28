import 'rem
import 'html

probe mold-html
probe load-rem [
body [
  div #toc _
  h1 "header 1"
  p "paragraph 1"
  h2 ["header" b "2"]
  p "par 2"
]
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
