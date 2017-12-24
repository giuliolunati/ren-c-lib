html: import 'html

dot: html/load-html/quiet
"<?><b style='my: 4' >testo<br a='b'>"
%test.html
print
html/mold-html dot

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
