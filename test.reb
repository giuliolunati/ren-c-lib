html: import 'html

dot: html/split-html
%test.html
;"<tr><td style='my: 4' >testo<br a='b'></td></tr>"
dot: html/load-html dot
dot: html/clean dot [
  attributes --
  tags -
  <html> + <body> +
  <p> + <br/> +
  <b> + <i> +
  <td> <p>
]
print
html/mold-html dot

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
