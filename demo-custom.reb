demo: function [x [block!] /quiet] [
  for-each x x [switch type-of x [
    text! x [
      print replace/all x "^/  " " "
    ]
    block! [
      print [">>" lib/mold/only x "^/--"]
      r: do x
      print [
        "=="
        either quiet ["..."] [lib/mold :r]
        newline
      ]
    ]
    'quit = x [quit 0]
    default: [fail [
      {Invalid argument for DEMO:} x
    ]]
  ]]
]

demo [
import

{** CUSTOM TYPES & VALUES **

A *custom type* is a map with a key 'type-of set to a word (the name of the type)
}
[custom-type?: function [x] [ 
  to-logic try all [
    map? x
    word? try select x 'type-of
  ]
]]

{A *custom value* is a map with a key 'custom-type
  set to its custom type
}
[custom-value?: function [x] [
  to-logic try all [
    map? x
    custom-type? try select x 'custom-type
  ]
]]

{Let's define a custom type for fraction numbers:
}
[fraction!: make map! [type-of fraction!]]

{** CUSTOM METHODS **

  A custom type defines some customized "methods".
  First, we need a method to make a custom value
  (NOTE it must set the 'custom-type key!)
}
[
  fraction!/make: function [spec] [
    if 0 = d: spec/2 [fail "Denominator must be not 0"]
    n: spec/1
    if d < 0 [d: 0 - d n: 0 - n]
    make map! reduce [
      'custom-type fraction!
      'num n
      'den d
    ]
  ]
]

{Let's customize the MAKE function,
  to manage custom types and custom values:
}
[
  make: adapt :make [
    if custom-type? type
    [ return type/make def ]
    if custom-value? type
    [ return type/custom-type/make def ]
  ]
]

{Make some fraction numbers, in 3 different ways,
  and check they're custom values:
}
[ custom-value? f12: fraction!/make [1 2] ]
[ custom-value? f-23: make fraction! [-2 3] ]
[ custom-value? f3-4: make f12 [3 -4] ]

{Customize the TYPE-OF function,
  and use it to define the FRACTION? checker:
}
[
  type-of: adapt :type-of [
    if custom-value? :value
    [ return value/custom-type ]
    if custom-type? :value
    [ return value/type-of ]
  ]
]
[
  fraction?: function [x] [same? fraction! type-of x]
]

{Now check the type of prev made f12, in 3 ways:}
[ type-of type-of f12 ]
[ same? fraction! type-of f12 ]
[ fraction? f12 ]

{FORMing a fraction number produces an ugly result:
}
[form f12]

{Then, we need a better custom FORM method...
}
[fraction!/form: function [x] [
  unspaced [x/num "/" x/den]
]]
[fraction!/form f12]

{... and finally we customize the FORM function and use it:
}
[
  form: adapt :form [
    if custom-value? :value
    [ return value/custom-type/form value ]
  ]
]
[
  print form f12
  print form f-23
  print form f3-4
]

{The customization of previous functions is easy enough, because
  1: only one arg is customized
  2: that arg admits the MAP type

  When the condition 2 is false, we can't use ADAPT.
  Instead we must re-define the function, ax in the case of TO function
}
[
  to: function [
    'type [<blank> quoted! word! path! datatype! map!]
    value [<blank> <dequote> any-value!]
    return:[<opt> any-value!]
  ][
    if custom-type? get type
    [ return (get type)/to get type value ]
    if custom-value? value
    [ return (type-of value)/to get type value ]
    lib/to type value
  ]
]
[fraction!/to: function [type value] [
  if same? fraction! type[
    if fraction? value [return value]
    if integer? value [return make type reduce [value 1]]
  ]
  if all [
    fraction? value
    decimal! = type
  ] [ return value/num / value/den ]
  fail ["Can't convert" value "to" type]
]]

[form f2: to fraction! 2]
[same? f2 to fraction! f2]
[to decimal! f3-4]


{Next step is to customize a binary function,
  for which condition 1 is false.
  Let's try with MULTIPLY and *:
}

[
  multiply: function [
    value1 [<dequote> any-scalar! date! binary! map!]
    value2 [<dequote> any-scalar! date! binary! map!]
  ][
    if all [
      custom-value? value1
      action? f: try select value1/custom-type 'multiply
      not error? trap [r: f value1 value2]
    ] [return r]
    if all [
      custom-value? value2
      action? f: try select value2/custom-type 'multiply
      not error? trap [r: f value1 value2]
    ] [return r]
    lib/multiply value1 value2
  ]
]
[
  fraction!/multiply: function [x y] [
    x: to fraction! x
    y: to fraction! y
    make fraction! reduce [
      lib/multiply x/num y/num
      lib/multiply x/den y/den
    ]
  ]
]
[ *: enfix :multiply ]

[ form f12 * f-23 ]
[ form f12 * 3 ]
[ form 2 * f-23 ]

] ; end demo

; vim: et sw=2
