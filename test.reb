rem: import 'rem
load-rem: :rem/load-rem
dot: import 'doc-tree
html: import 'html
node: load-rem [
process-text: true
{1 br
2 br

*bold* /italic/ ^^sup^^ _sub_ }
]

probe html/mold-html node
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
