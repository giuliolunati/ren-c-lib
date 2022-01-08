REBOL [
	Title: "Demo for 'custom-types module"
	Type: script
	Require: [custom-types]
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
]

do intern load %demo.reb

; MAIN

demo [
  _
  "=== DEMO FOR CUSTOM TYPES ==="
  _
  "Import the module:"
  (import 'custom-types)
  _
  
  "Make a new CUSTOM-TYPE:"
  (complex!: make-custom-type)
  _
  "A CUSTOM-TYPE is a special map!,"
  "it contains the CUSTOM-TYPE key, that refers to the map itself:"
  [mold complex!]
  [same? complex!.custom-type]
  _
  "We can test it with IS-CUSTOM-TYPE?"
  [is-custom-type? complex!]
  _
  "Let's define MAKE-COMPLEX to make an istance of COMPLEX! and COMPLEX? to test it:"
  ( make-complex: func [
      re [any-number!] im [any-number!]
    ][
      make map! :[
        'custom-type complex!
        're re
        'im im
      ]
    ]
    complex?: func [x] [
      did all [
        map? x
        same? complex! x.custom-type
      ]
    ]
  )
  [ mold c1: make-complex 1 2 ]
  [ complex? c1 ]
  _
  "Let's add to COMPLEX! a custom method FORM"
  [ complex!.form: func [c] [
      spaced [c.re "+i*" c.im]
    ]
    complex!.form c1
  ]
  _
  "Now the magic!"
  "DO-CUSTOM execute code calling the 'right' custom methods:" 
  [ do-custom [form c1]]
  [ do-custom [print [c1]]]
  [ do-custom [print [c1 "is complex"]]]
  _
  "We should define some other methods:"
  "e.g. if we want the standard make syntax, we need a custom MAKE:"
  ( complex!.make: func [type def] [
      assert [same? complex! type]
      all [block? def, 2 = length-of def]
      else [fail "wrong def"]
      make-complex def.1 def.2
  ])
  [ do-custom [form make complex! [3 2]] ]
  _
  "Let's define the ADD method:"
  ( complex!.add: func [c1 c2] [
      make-complex
        c1.re + c2.re
        c1.im + c2.im
  ])
  [ c2: make-complex -2 2
    do-custom [print [c1 '+ c2 '= c1 + c2]]
  ]
] ; end demo

; vim: set et sw=2:
