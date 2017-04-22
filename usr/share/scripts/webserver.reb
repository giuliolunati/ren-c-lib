-help: does [print {
USAGE: r3 webserver.reb [OPTIONS]
OPTIONS:
  -h, -help, --help : this help
  -q      : verbose: 0 (quiet)
  -v      : verbose: 2 (debug)
  INTEGER : port number [8000]
  OTHER   : web root [system/options/path]
  -a val  : access-dir [true]
     val = true  : list directory content
     val = false : access forbidden
     val = INDEX : show directory/INDEX
        (if no extension try .reb, .rem, .html)
EXAMPLE: 8080 /my/web/root -q -a index
}]

;; INIT
port: 8888
root: %""
access-dir: true
verbose: 1

a: system/options/args
forall a [case [
    "-a" = a/1 [
        access-dir: a/2
        a: next a
    ]
    find ["-h" "-help" "--help"] a/1 [-help quit]
    "-q" = a/1 [verbose: 0]
    "-v" = a/1 [verbose: 2]
    integer? load a/1 [port: load a/1]
    true [root: to-file a/1]
]]

;; LIBS
import 'httpd

rem-to-html: attempt [
  rem: import 'rem
  html: import 'html
  chain [:rem/load-rem :html/mold-html]
]

ext-map: make block! [
  "css" css
  "gif" gif
  "htm" html
  "html" html
  "jpg" jpeg
  "jpeg" jpeg
  "js" js
  "json" json
  "png" png
  "r" rebol
  "r3" rebol
  "reb" rebol
  "rem" rem
  "txt" text
]

mime: make map! [
  html "text/html"
  jpeg "image/jpeg"
  r "text/plain"
  text "text/plain"
  js "application/javascript"
  json "application/json"
  css "text/css"
]

status-codes: [
  200 "OK" 201 "Created" 204 "No Content"
  301 "Moved Permanently" 302 "Moved temporarily" 303 "See Other" 307 "Temporary Redirect"
  400 "Bad Request" 401 "No Authorization" 403 "Forbidden" 404 "Not Found" 411 "Length Required"
  500 "Internal Server Error" 503 "Service Unavailable"
]

html-list-dir: function [
  "Output dir contents in HTML."
  dir [file!]
  ][
  if error? try [list: read dir] [
    return _
  ]
  sort/compare list func [x y] [
    case [
      all [dir? x not dir? y] [true]
      all [not dir? x dir? y] [false]
      y > x [true]
      true [false]
    ]
  ]
  insert list %../
  data: copy {<head>
    <meta name="viewport" content="initial-scale=1.0" />
    <style> a {text-decoration: none} </style>
  </head>}
  for-each i list [
    append data ajoin [
      {<a href="} i {">}
      if dir? i ["&gt; "]
      i </a> <br/>
    ]
  ]
  data
]

handle-request: function [
    req [object!]
  ][
  path-elements: next split req/target #"/"
  either parse req/request-uri ["/http" opt "s" "://" to end] [
    path: to-url req/request-uri: next req/request-uri
    path-type: 'file
  ][
    path: join-of root req/target
    path-type: exists? path
  ]
  if path-type = 'dir [
    unless access-dir [return 403]
    while [#"/" = last path] [take/last path]
    append path #"/"
    dir-index: _
    either any-string? access-dir [
      dir-index: join-of path to-file access-dir
      either find access-dir "." [
        dir-index: reduce [join-of path to-file access-dir]
      ][
        dir-index: map-each x [%.reb %.rem %.html] [join-of dir-index x]
      ]
      for-each x dir-index [
        if 'file = path-type: exists? x [path: x break]
      ]
      unless 'file = path-type [return 403]
      ;; drop to path-type = 'file below
    ][
      if data: html-list-dir path [
        return reduce [200 mime/html data]
      ]
      return 403
    ]
  ]
  if path-type = 'file [
    pos: find/last last path-elements "."
    file-ext: either pos [copy next pos] [_]
    mimetype: ext-map/:file-ext
    if error? data: trap [read path] [return 403
]
    if all [
      function? :rem-to-html
      any [
        mimetype = 'rem
        all [
          mimetype = 'html
          "REBOL" = uppercase to-string copy/part data 5
        ]
      ]
    ][
      either error? data: trap [
        rem-to-html load data
      ]
      [ data: form data mimetype: 'text ]
      [ mimetype: 'html ]
    ]
    if mimetype = 'rebol [
      mimetype: 'html
      if error? data: trap [
        data: do data
      ] [mimetype: 'text]
      if any-function? :data [
        data: data request
      ]
      if block? data [
        mimetype: first data
        data: next data
      ]
      data: form data
    ]
    return reduce[200 any [select mime :mimetype 'text] data]
  ]
  404
]

;; MAIN
server: open compose [
  scheme: 'httpd (port) [
    res: handle-request request
    either integer? res [
      response/status: res
      response/type: "text/html"
      response/content: unspaced [
        <h2> res space select status-codes res </h2>
        <b> request/method space request/request-uri </b>
        <br> <pre> mold request </pre>
      ]
    ][
      response/status: res/1
      response/type: res/2
      response/content: res/3
    ]
    if verbose >= 2 [print mold request]
    if verbose >= 1 [
      print spaced [
        request/method
        request/request-uri
      ]
      print spaced ["=>" response/status]
    ]
  ]
]
if verbose >= 1 [print spaced ["Serving on port" port]]
if verbose >= 2 [
  print spaced ["root:" root]
  print spaced ["access-dir:" access-dir]
]
wait server

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
