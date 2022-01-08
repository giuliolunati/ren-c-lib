
REBOL [
  Title: "Demo module"
  Type: module
  Exports: [demo]
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
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
        print [">>" mold/only code]
        res: do code
        trap [print [res]]
      ]
      group? code [
        print [">>" mold/only as block! code]
        do code
      ]
    ]
  ]
]

