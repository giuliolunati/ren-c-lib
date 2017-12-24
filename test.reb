markup: import 'markup
decode-markup: :markup/decode-markup

html: import 'html
load-html: :html/load-html

probe dot: decode-markup
"<?><b style='my: 4' >testo<br a='b'>"
%test.html

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
