REBOL [
  Title: "Demo/test utilities"
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
  Type: module
  Name: demo
  Exports: [demo]
]


demo: function [
    return: [<opt> any-value!]
    group [<end> <opt> blank! group! block! text! file! url! module!]
    /test
][
  ;; defined here, so will customized together demo
  demo1: function [
    b [block!]
    return: [<opt> any-value!]
  ][
    if empty? b [return true]
    if (2 = length of b) [
      if b/1 = 'comment and (text? b/2) [
        s: replace/all copy b/2 "^/" "^/;; "
        if not empty? s [write-stdout ";; "]
        print s
        return true
      ]
      if b/1 = 'elide [return do b/2]
    ]
    print [">>" mold/only b]
    print ["==" opt r: try do b]
    r
  ]

  if not set? 'group or (not group) [group: help-dialect]

  if module? group [return demo group/demo]

  if match [file! url! text!] group [group: load group]

  if block? group [ for-each t group [
    if group? t [
      if r: apply 'demo [group: t test: test]  [return r]]
  ] return _ ]

  assert [group? group]
  b: make block! 0
  r: true
  for-next group [
    if new-line? group [
      set* 'r demo1 b
      b: make block! 0
    ]
    new-line b false
    append/only b group/1
    new-line b false
  ]
  if not empty? b [set* 'r demo1 b]
  if (test) and (not try r) [return group]
  _
]

help-dialect: use [a] [[(
  comment "DEMO DIALECT:"
  comment ""
  comment "Demo code is a series of GROUPS."
  comment "With /test, if the last result of any group is false|blank|null|void demo returns with a FAILED message."
  comment ""
)(comment "Every line of code is REPL'ed:"
  2 + 3
  comment ""
)(comment "BUT:"
  comment ""
  comment {`COMMENT "blah"` insert a comment:} 
  comment "blah"
  comment {`COMMENT "blah^^/blah` insert multiline comment:"}
  comment "blah^/blah"
  comment {`COMMENT ""` insert an empty line:}
  comment ""
)(comment "`ELIDE (a: 3)` perform hidden evaluation:"
  elide (a: 3)
  7 + a
)]]


;; vim: set sw=2 sts=2 expandtab:
