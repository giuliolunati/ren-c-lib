rem: import 'rem
load-rem: :rem/load-rem
dot: import 'doc-tree
html: import 'html
node: load-rem {
f: func [x] [node [p bg: 'yel c: 8 i b["ciao" x]]] 
f "777"
}

probe html/mold-html node
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
