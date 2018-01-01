rem: import 'rem
load-rem: :rem/load-rem
html: import 'html
dot: load-rem
{"abc" div "def" br "ghi"}
dot/type: 'element
dot/name: 'body
probe html/mold-html dot
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
