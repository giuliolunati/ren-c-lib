#!/usr/bin/r3
REBOL[]
help-me: {ARGS: [OPTS] INPUT [OUTPUT]
INPUT: HTML file to be cleaned [def. stdin]
OUTPUT: cleaned file [def. stdout]
OPTS: -h|-help|--help : print this help
}

import 'markup
&: enfix :join

change-dir system/options/path
infile: outfile: _
dump: false

for-next a system/options/args [
  case [
    find ["-h" "--help" "-help"] a/1
    [ help-me QUIT 0 ]
    a/1 = "-d" [dump: true]
    not infile [infile: to-file a/1]
    not outfile [outfile: open/write to-file a/1]
    
  ] else [print help-me QUIT 1]
]

emit: either outfile
[ specialize :write [destination: outfile] ]
[ :write-stdout ]

either infile [html: to-text/relax read infile] [
  html: make text! 0
  while [not empty? t: read system/ports/input]
  [ append html t ]
]

filter-tag: function [a x b] [
  if block? x [x: x/1]
  case [
    find ["font" "span"] x [
      return ""
    ]
  ]
  return a & x & b
]

cleaner: either dump
  [markup-parser]
  [
    make markup-parser [
      D: [x] -> [emit "<!" & x & ">"]
      P: [x] -> [emit "<?" & x & "?>"]
      !: [x] -> [emit "<!--" & x & "-->"]
      O: [x] -> [emit filter-tag "<" x ">"]
      E: [x] -> [emit filter-tag "<" x "/>"]
      C: [x] -> [emit filter-tag "</" x ">"]
      T: [x] -> [emit x]
    ]
  ]

cleaner/run html

if outfile [close outfile]
; vim: set et sw=2:
