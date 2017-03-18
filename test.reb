import 'rem
import 'html

args: system/options/args
a: args/1
test: either a [
  load-html read/string to-file a
][
  load-rem [
    doc [
    header [ title "hello" ]
    body [
    div [
      p ["line1" br "line2"]
      hr
      p ["text" b "bold" i "italic"]
    ]
    ]
    ]
  ]
]
test: mold-rem test
print test
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
