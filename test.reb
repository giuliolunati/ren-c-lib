smt: import 'smart-text
smart-text: :smt/smart-text
html: import 'html
node: smart-text/inline to-file system/options/args/1 
probe html/mold-html node
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
