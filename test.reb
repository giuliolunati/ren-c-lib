import 'rem
import 'html

args: system/options/args
a: args/1
test: either a [
  load-html read/string to-file a
][
  load-rem [
    span
    .aclass .bclass
    color: "red" bg: "cyan"
    /align "right"
    []
    img
    #idimg
    %../img.png
    img
    %img.jpg
    a
    http://example.com
    "anchor"
  ]
]
test: mold-rem probe test
print '========
print test
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
