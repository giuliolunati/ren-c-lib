#!/usr/bin/r3
REBOL[]
help-me: {ARGS: [OPTS] INPUT [OUTPUT]
INPUT: HTML file to be cleaned [def. stdin]
OUTPUT: cleaned file [def. stdout]
OPTS: -h|-help|--help : print this help
}

import 'markup
&: enfix :join

cleaner: make markup-parser [
  D: [x] -> [emit "<!" & x & ">"]
  P: [x] -> [emit "<?" & x & "?>"]
  !: [x] -> [emit "<!--" & x & "-->"]
  O: [x] -> [emit "<" & x/1 & ">"]
  E: [x] -> [emit "<" & x/1 & "/>"]
  C: [x] -> [emit "</" & x & ">"]
  T: [x] -> [emit x]
]

change-dir system/options/path
infile: outfile: _

for-next a system/options/args [
  case [
    find ["-h" "--help" "-help"] a/1
    [ help-me QUIT 0 ]
    not infile [infile: to-file a/1]
    not outfile [outfile: to-file a/1]
    
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

cleaner/run html
