help-me: {ARGS: [/CMD] [SOURCE] [OPTS]
    SOURCE: INPUT_FILE  (default makefile.reb)
    CMD:    /gmake | /dump (default /gmake)
OPTS: 
    /gmake: OUT_FILE (default build/makefile)
    /dump:  OUT_FILE (default stdout)
}

do %tools/bootstrap-shim.r
if not void? :tighten [
    enfix: enfix adapt :enfix [action: tighten :action]
]

blockify: default [function [x] [
    either block? x [x] [reduce [x]]
]]

wchar: charset [
    #"A" - #"Z" "_"
]

expand: function [
    template [block! group! text! file! tag!]
][
    esc: #"$"
    t: r: _
    if any [block? template group? template] [
        r: make type-of template 0
        for-next t template [
            new-line tail r new-line? t
            switch type-of t/1 [
                block! group! [append/only r expand t/1]
                text! file! tag! [append r expand t/1]
            ] else [append r t/1]
        ]
        new-line tail r new-line? template
        return r
    ]
    r: make block! 0
    if not find template esc [return template]
    parse as text! template [
        any [
            copy t to esc skip
            (if not empty? t [append r t])
            [ 
                [ "(" copy t to #")" skip
                | copy t some wchar
	        ]
                ( t: blockify load t
	            append/only r to-group t
	        )
            | opt esc (append r esc)
            ]
        ]
        copy t to end
        (if not empty? t [append r t])
    ]
    either text? template 
    [ reduce ['unspaced r] ]
    [ reduce ['to (type-of template) 'unspaced r] ]
]

&: enfix :join

find-files: function [
  dir [file!]
  test [file! blank!]
][
  filter: function [b [block!]] [
    if not test [return b]
    map-each x b [
      if any [
        dir? x
        x = test
      ] [x]
    ]
  ]
  if 'dir != exists? dir [return null]
  dir: dirize dir
  b: map-each x (filter read dirize dir) [dir/:x]
  while [not tail? b] [
    d: b/1
    if dir? d [
      remove b
      insert b
        map-each x (filter read d) [d/:x]
    ] else [b: next b]
  ]
  b: head b
]

dump: function [
    makefile [block!]
    target [any-string! blank!]
][
    r: (mold makefile) & "^/; vim: set syn=rebol:"
    if empty? target [print r]
    else [write to-file target r]
]

gmake: function [
    makefile [block!]
    target [any-string! blank!]
][
    r: make text! 0
    for-each [t s c] makefile [
        if text? t [
            append r spaced [".PHONY:" t newline]
        ]
        append r unspaced [t ": " s newline]
        for-each c blockify c [
            append r tab
            append r c
            append r newline
        ]
        append r newline
    ]
    if empty? target [print r]
    else [write to-file target r]
]

=== MAIN ===
change-dir system/options/path
args: system/script/args
cmd: either first args [take args] [_]
if cmd/1 != #"/" [
    makefile: cmd cmd: _
] else [
    makefile: either first args
    [ take args ][ "makefile.reb" ]
]
output: either first args [take args] [_]
cmd: default ["/gmake"]

makefile: reduce do expand load to-file makefile

;; selectively reduce and flatten fields
m: makefile
while [not tail? m] [
    while [block? m/1] [
        insert m take m
    ]
    m/2: reduce m/2 
    if block? m/2 [m/2: flatten m/2]
    m/3: reduce m/3
    if block? m/3 [
        m/3: flatten m/3
        new-line/all m/3 true
    ]
    m: skip m 3
]

switch cmd [
    "/dump" [dump makefile output]
    "/gmake" [gmake makefile output]
] else [ print help-me ]

; vim: set et sw=4:
