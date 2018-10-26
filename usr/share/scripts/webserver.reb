REBOL [Name: "webserver"]
-help: does [lib/print {
USAGE: r3 webserver.reb [OPTIONS]
OPTIONS:
  -h, -help, --help : this help
  -q      : verbose: 0 (quiet)
  -v      : verbose: 2 (debug)
  INTEGER : port number [8000]
  OTHER   : web root [system/options/path]
  -a name : access-dir via name.*
EXAMPLE: 8080 /my/web/root -q -a index
}]

;; INIT
port: 8888
root-dir: %""
access-dir: false
verbose: 1

a: system/options/args
for-next a [case [
    "-a" = a/1 [access-dir: a/2 a: next a]
    find ["-h" "-help" "--help"] a/1 [-help quit]
    "-q" = a/1 [verbose: 0]
    "-v" = a/1 [verbose: 2]
    integer? load a/1 [port: load a/1]
    true [root-dir: to-file a/1]
]]

;; LIBS

import 'httpd

if error? rem-to-html: trap [
  rem: import 'rem
  to-html: import 'to-html
  chain [:rem/load-rem :to-html/to-html]
] [fail rem-to-html]

ext-map: [
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
  "wasm" wasm
]

mime: make map! [
  html "text/html"
  jpeg "image/jpeg"
  r "text/plain"
  text "text/plain"
  js "application/javascript"
  json "application/json"
  css "text/css"
  wasm "application/wasm"
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
  if error? trap [list: read dir] [return _]
  ;;for-next list [if 'dir = exists? join-of dir list/1 [append list/1 %/]]
  ;; ^-- workaround for #838
  sort/compare list func [x y] [
    case [
      all [dir? x not dir? y] [true]
      all [not dir? x dir? y] [false]
      y > x [true]
      true [false]
    ]
  ]
  if dir != %/ [insert list %../]
  data: copy {<head>
    <meta name="viewport" content="initial-scale=1.0" />
    <style> a {text-decoration: none} </style>
  </head>}
  for-each i list [
    append data unspaced [
      {<a href="} i 
      either dir? i [{?">&gt; }] [{">}]
      i </a> <br/>
    ]
  ]
  data
]

handle-request: function [
    request [object!]
  ][
  path-elements: next split request/target #"/"
  if parse request/request-uri ["/http" opt "s" "://" to end] [
    ; 'extern' url /http://ser.ver/...
    if all [
      3 = length path-elements
      #"/" != last path-elements/3
    ] [; /http://ser.ver w/out final slash
      path: unspaced [
        request/target "/"
        if request/query-string unspaced [
          "?" to-text request/query-string
        ]
      ]
      return redirect-response path
    ]
    path: to-url next request/request-uri
    path-type: 'file
  ] else [
    path: join-of root-dir request/target
    path-type: try exists? path
  ]
  if path-type = 'dir [
    if not access-dir [return 403]
    if request/query-string [
      if data: html-list-dir path [
        return reduce [200 mime/html data]
      ] 
      return 500
    ]
    dir-index: map-each x [%.reb %.rem %.html %.htm] [join-of to-file access-dir x]
    for-each x dir-index [
      if 'file = try exists? join-of path x [dir-index: x break]
    ] then [dir-index: "?"]
    return redirect-response join-of request/target dir-index
  ]
  if path-type = 'file [
    pos: try find/last last path-elements
      "."
    file-ext: (if pos [copy next pos] else [_])
    mimetype: try attempt [ext-map/:file-ext]
    if error? data: trap [read path] [return 403]
    if mimetype = 'rebol [
      parse last path-elements [ to ".cgi.reb" end ] else [mimetype: 'text]
    ] 
    if all [
      action? :rem-to-html
      any [
        mimetype = 'rem
        all [
          mimetype = 'html
          "REBOL" = uppercase to-text copy/part data 5
        ]
      ]
    ][
      rem/rem/request: request
      if error? data: trap [
        rem/rem/reset
        rem-to-html data
      ] [ data: form data mimetype: 'text ]
      else [ mimetype: 'html ]
    ]
    if mimetype = 'rebol [
      mimetype: 'html
      data: trap [
        data: do data
      ]
      if action? :data [
        data: trap [data request]
      ]
      if block? data [
        mimetype: first data
        data: next data
      ] else [
        if error? data [mimetype: 'text]
      ]
      data: form data
    ]
    return reduce[200 try select mime :mimetype data]
  ]
  404
]

redirect-response: function [target] [
  reduce [200 mime/html unspaced [
    {<html><head><meta http-equiv="Refresh" content="0; url=}
    target {" /></head></html>}
  ]]
]

;; MAIN
server: open compose [
  scheme: 'httpd (port) [
    res: handle-request request
    if integer? res [
      response/status: res
      response/type: "text/html"
      response/content: unspaced [
        <h2> res space select status-codes res </h2>
        <b> request/method space request/request-uri </b>
        <br> <pre> mold request </pre>
      ]
    ] else [
      response/status: res/1
      response/type: res/2
      response/content: to-binary res/3
    ]
    if verbose >= 2 [lib/print mold request]
    if verbose >= 1 [
      lib/print spaced [
        request/method
        request/request-uri
      ]
      lib/print spaced ["=>" response/status]
    ]
  ]
]
if verbose >= 1 [lib/print spaced ["Serving on port" port]]
if verbose >= 2 [
  lib/print spaced ["root-dir:" root-dir]
  lib/print spaced ["access-dir:" access-dir]
]

wait server

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
