import 'rem
import 'html

print mold-html load-rem [
toggle: enfix function [x y] [node[
a /onclick "toggleNext(this)" x
span display: "none" node y
]]
script {function toggleNext(x) {
  var s
  s=x.nextSibling.style
  if (s.display=="none") s.display="inline"
  else s.display="none"
}}
h1 "header 1" toggle [
p "first"

h2 "header 2" toggle [
p "second"
]

] ;h1
] 
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
