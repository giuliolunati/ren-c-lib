rem: import 'rem
load-rem: :rem/load-rem
dot: import 'doc-tree
html: import 'html
node: load-rem
{a #id8 .c1 http://example.com .c2 ["testo" img %../a.jpg]}

dot/make-element/target 'body false node
probe
;dot/mold-tree
html/mold-html
node
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
