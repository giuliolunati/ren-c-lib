
REBOL [
  Title: "Demo module"
  Type: module
  Exports: [demo --]
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
]

indent: func [x] [
  replace/all form x "^/" "^/   "
]

--: func ['x [word! group!]] [
  let v: either word? x [get x] [do x]
  print ["--" mold x ":" v]
]

demo: func [code] [
  for-each code code [
    let res
    case [
      code = _ [print newline]
      code = 'quit [quit]
      text? code [
        print ["##" code]
      ]
      block? code [
        print [">>" indent mold/only code]
        res: do code
        trap [print ["==" indent res]]
      ]
      group? code [
        print [">>" indent mold/only as block! code]
        do code
      ]
    ]
  ]
]

