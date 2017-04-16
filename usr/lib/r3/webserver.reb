REBOL [
  Title: "Static web server"
  Type: module
  Name: 'webserver
  Exports: [webserver rem-to-html html-list-dir]
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Date: 2017-02-24
]

import 'shttpd
import 'android
rem: import 'rem
html: import 'html

rem-to-html: chain [:rem/load-rem :html/mold-html]

html-list-dir: function [
  "Output dir contents in HTML."
  dir [file!]
  ][
  if error? try [list: read dir] [
    return build-error-response 400 request ""
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
      {<a href="} join-of dir i {">}
      if dir? i ["&gt; "]
      i </a> <br/>
    ]
  ]
  data
]

deurl: function [
    "decode an url encoded string"
    s [string!]
][
    dehex replace/all s #"+" #" "
]

webserver: make object! [
  ;; config
  access-dir: true ;; 
  verbose: 0 ;; [0 1 2]
  root: %"" ;;
  
  ;; internal
  port: _

  code-map: make map! [
    200 "OK"
    400 "Forbidden"
    404 "Not Found"
    410 "Gone"
    500 "Internal Server Error"
    501 "Not Implemented"
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

  template-error: ;; from Ingo Hohmann's websy.reb
  {<html><head>
    <title>$code $text</title></head>
    <body><h1>$text</h1>
    <h2>Info</h2>
    <p>$info</p>
    <h2>Request:</h2>
    <pre>$request</pre>
    <hr>
    <i>server.reb</i>
    on <a href="http://github.com/metaeducation/ren-c/">Ren/C</a> $version
    </body></html>
  }

  build-error-response: function [
    ;; from Ingo Hohmann's websy.reb
    "Create a block containing return-code(code), mime-type(html), and html content (error, containin request info(molded))"
    status-code [integer!] "http status code"
    request [map!] "parsed request"
    info [string!] "additional error information"
    ][
    reduce [
      'status status-code
      'type mime/html
      'content reword template-error reduce [
        'code status-code
        'text code-map/:status-code
        'info info
        'request form reduce [
          request/method
          request/url
          newline newline
          mold request
        ]
        'version system/version
      ]
    ]
  ]

  handle-request: func [
    request [map!]
    mimetype: path: filetype:
    data: file-index:
    ][
    switch verbose [
      1 [print [request/method request/url]] 
      2 [print [newline request]]
    ]
    mimetype: ext-map/(request/file-type)
    either parse request/url ["/http" opt #"s" "://"to end] [
      path: to-url request/url: next request/url
      filetype: 'file
      request/Host: request/path-elements/3
      request/path-elements: skip request/path-elements 3
      unless mimetype [mimetype: 'html]
    ][
      path: join-of root request/path
      filetype: exists? path
    ]
    if filetype = 'dir [
      while [#"/" = last path] [take/last path]
      append path #"/"
      file-index: join-of path %index.reb
      either 'file = filetype: exists? file-index [
        mimetype: 'rebol
        path: file-index
      ][
        if access-dir [ 
          return reduce [
            'status 200
            'type mime/html
            'content html-list-dir path
          ]
        ]
        return build-error-response
          400 request "No folder access."
      ]
    ]
    if filetype = 'file [
      case [
        error? data: trap [read path] [
          return build-error-response
            400
            request
            join-of "Cannot read file " path
        ]
        any [ mimetype = 'rem all [
          mimetype = 'html 
          "REBOL" = uppercase to-string copy/part data 5
        ] ] [
          either error? data: trap [
            rem-to-html load data
          ] [data: form data mimetype: 'text]
          [mimetype: 'html]
        ]
        mimetype = 'rebol [
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
      ]
      return reduce [
        'status 200
        'type any[select mime :mimetype 'text]
        'content data
      ]
    ]
    return build-error-response 404 request ""
  ]

  start: func [
    port-number [integer!]
    ][
    wait port: open [
      Scheme: 'httpd
      Port-ID: port-number
      Awake: :handle-request
    ]
  ]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
