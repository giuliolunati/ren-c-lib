smt: import 'smart-text
smart-text: :smt/smart-text
html: import 'html
node: smart-text {0br \
1 br
2 br

*bold* /italic/ ^^sup^^ _sub_ }

probe html/mold-html node
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
