REBOL [
	Title: "Demo for 'complex module"
	Type: 'script
	Require: 'complex
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
]

demo: func [code] [
  for-each code code [
    case [
      string? code [
        for-each x split code [
          newline some space
        ] [print x]
      ]
      block? code [
        print [">>" mold/only code]
        print ['== do code]
      ]
      group? code [
        code: to block! code
        print [">>" mold/only code]
        do code
      ]
      code = _ [print/only newline]
    ]
  ]
]
;;; MAIN
demo [
  _
  "=== COMPLEX MODULE DEMO ==="
  _
  "First of all, import:"
  (import 'complex)
  _
  {NOTE: 'complex module is based on 'custom, 
  that needs to be enabled:}
  (customize self)
  _
  {Make complex value with MAKE
  from number, block or string: ...}
	[make complex! 3]
	[a: make complex! [1 2]]
	[make complex! "1-i2"]
  _
  {... or with '+i and '-i operators:}
  [b: 2 +i 1]
  [c: 2 -i 3]
  _
  "NOTE: 'i is imaginary unit: "
  [i]
  _
  "Convert to BLOCK! or to STRING!:"
  [mold to block! a]
  [mold to string! a]
  _
  "Test a value with 'complex? :"
  [complex? b] [complex? 3.1]
  _
  "Some arithmetics:"
  [[a "," b]]  [a + b] [a - b] [a * b] [a / b]
  _
  "Also mixed with real numbers:"
  [2 +i 3 * 2] [1 / (1 -i 2)]
  _
  "Logarithm and exponential:"
  [y: log (-1 +i 0)]
  [exp y]
  [y: exp (3 +i (2 * pi + 1))]
  [log y]
]
; vim: set syn=rebol ts=2 sw=2 sts=2:
