REBOL [
  Title: "Customize functions"
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
  Type: module
  Name: custom
  Exports: [custom customize has-custom-type?]
]


;; GLOBALS

indented-line: "^/"
indent+: does [append indented-line "    "]
indent-: does [loop 4 [take/last indented-line]]
mold-stack: lib/make block! 8

mold-recur?: function [x] [
  for-each y mold-stack [
    if same? x y [return true]
  ]
  false
]

is-custom-type?: function [x] [
  all [map? x same? x :x/custom-type]
]

has-custom-type?: function [x] [
  all [map? x is-custom-type? :x/custom-type]
]

fail-invalid-parameter: function [
  func-name [text! word!]
  params [block! word!]
][
  if word? params [
    fail/where unspaced [
      "Invalid parameter for " func-name ": "
      custom/form get params
    ] params
  ] else [
    fail/where unspaced [
      "Invalid parameters for " func-name ": "
      map-each x params [custom/form get x]
    ] params/1
  ]
]

try-method: function [method arg] [
  all [
    attempt [method: :arg/custom-type/:method]
    attempt [method arg]
  ]
]

try-method-1: function [method arg1 arg2] [
  all [
    attempt [method: :arg1/custom-type/:method]
    attempt [method arg1 arg2]
  ]
]

try-method-2: function [method arg1 arg2] [
  all [
    attempt [method: :arg2/custom-type/:method]
    attempt [method arg1 arg2]
  ]
]

rad-to-deg: 180 / pi
deg-to-rad: pi / 180


;; CUSTOM OBJECT

custom: append make object! [] [< _ <= _ > _ >= _] ;; dirty trick :-/
custom: make custom [

make: enclose :lib/make function [f [frame!]] [
  if is-custom-type? f/type [
    return f/type/make f/type f/def
  ]
  else [do f]
]

to: function [
    type [datatype! map!]
    value [any-value!]
  ][
  if has-custom-type? :value [
    value/custom-type/to type value
  ]
  else [lib/to type value]
]

to-action: specialize :to [type: action!]
to-word: specialize :to [type: word!]
to-set-word: specialize :to [type: set-word!]
to-get-word: specialize :to [type: get-word!]
; to-lit-word: specialize :to [type: lit-word!] ; TODO: fix
; to-refinement: specialize :to [type: refinement!] ; TODO: fix
to-issue: specialize :to [type: issue!]
to-path: specialize :to [type: path!]
to-set-path: specialize :to [type: set-path!]
to-get-path: specialize :to [type: get-path!]
; to-lit-path: specialize :to [type: lit-path!] ; TODO: fix
to-group: specialize :to [type: group!]
to-block: specialize :to [type: block!]
to-binary: specialize :to [type: binary!]
to-text: specialize :to [type: text!]
to-file: specialize :to [type: file!]
to-email: specialize :to [type: email!]
to-url: specialize :to [type: url!]
to-tag: specialize :to [type: tag!]
to-bitset: specialize :to [type: bitset!]
to-image: specialize :to [type: image!]
to-vector: specialize :to [type: vector!]
to-map: specialize :to [type: map!]
to-varargs: specialize :to [type: varargs!]
to-object: specialize :to [type: object!]
to-frame: specialize :to [type: frame!]
to-module: specialize :to [type: module!]
to-error: specialize :to [type: error!]
to-port: specialize :to [type: port!]
to-logic: specialize :to [type: logic!]
to-integer: specialize :to [type: integer!]
to-decimal: specialize :to [type: decimal!]
to-percent: specialize :to [type: percent!]
to-money: specialize :to [type: money!]
to-char: specialize :to [type: char!]
to-pair: specialize :to [type: pair!]
to-tuple: specialize :to [type: tuple!]
to-time: specialize :to [type: time!]
to-date: specialize :to [type: date!]
to-datatype: specialize :to [type: datatype!]
to-typeset: specialize :to [type: typeset!]
to-gob: specialize :to [type: gob!]
to-event: specialize :to [type: event!]
to-handle: specialize :to [type: handle!]
to-struct: specialize :to [type: struct!]
to-library: specialize :to [type: library!]
to-blank: specialize :to [type: blank!]
to-void: specialize :to [type: void!]
to-function: specialize :to [type: action!]
to-string: specialize :to [type: text!]
to-paren: specialize :to [type: group!]

form: enclose :lib/form function [f] [
  value: f/value
  if all [
    has-custom-type? value
    r: try attempt [value/custom-type/form value]
  ] [return r]

  if match [block! group!] :value [
    value: as block! :value
    r: copy "" begin: true
    for-next value value [
      if not begin [append r space]
      begin: false
      append r form value/1
    ]
    return r
  ]

  if map? :value [
    r: copy ""
    if mold-recur? value [append r "..."]
    else [
      append/only mold-stack value
      for-each i value [repend r [
        mold i space
        mold select value i
        indented-line
      ]]
      take/last mold-stack
    ]
    return r
  ]

  if object? :value [
    r: copy ""
    if mold-recur? value [append r "..."]
    else [
      append/only mold-stack value
      for-each i value [repend r [
        mold i ": "
        mold select value i
        indented-line
      ]]
      take/last mold-stack
    ]
    return r
  ]

  do f
] ; form

mold: enclose :lib/mold function [f] [
  value: :f/value only: f/only all: f/all flat: f/flat limit: f/limit
  if not err: trap [
    r: applique :value/custom-type/mold [value: :value only: only all: all flat: flat limit: limit]
  ] [return r]
  ; else [lib/print lib/form err] ; for debug
  line: either flat [:newline] [:indented-line]

  r: case [
    match [block! group!] :value [
      if group? value [only: false]
      if not only [indent+]
      r: copy either group? value ["("]
      [either only [""] ["["]]
      lines: false
      if mold-recur? value [append r "..."]
      else [
        append/only mold-stack value
        for-next value value [
          if new-line? value [
            lines: true
            if r > "" [append r line]
          ]
          append r applique 'mold [value: value/1 only: false all: all flat: flat]
          append r space
        ]
        take/last mold-stack
      ]
      if not only [indent- if lines [append r line]]
      if space = try last r [take/last r]
      append r either group? value [")"]
      [either only [""] ["]"]]
    ]
    map? :value [
      r: copy either all ["#[map! ["]
      ["make map! ["]
      if mold-recur? value [append r "..."]
      else [
        append/only mold-stack value
        indent+
        for-each i value [repend r [
            line
            mold i space
            applique 'mold [value: select value i only: false all: all flat: flat]
        ]]
        indent-
        append r line
        take/last mold-stack
      ]
      append r either all ["]]"] [#"]"]
    ]
    object? :value [
      r: copy either all ["#[object! ["]
      ["make object! ["]
      if mold-recur? value [append r "..."]
      else [
        append/only mold-stack :value
        indent+
        repend r [line "[self: "]
        for-each i value [repend r [mold i space]]
        take/last r
        repend r [#"]" line #"["]
        indent+
        for-each i value [repend r [
            line
            mold i ": "
            applique 'mold [value: select :value i only: false all: all flat: flat]
        ]]
        indent-
        repend r [line #"]"]
        indent-
        take/last mold-stack
      ]
      repend r [line either all ["]]"] ["]"]]
    ]
    default [do f]
  ] ; case
  if limit and [limit < length of r] [
    r: head clear change r at r limit "..."
  ]
  return r
] ; mold

delimit: enclose :lib/delimit function [f] [
  block: reduce f/block
  r: copy ""
  if mold-recur? block [append r "..."]
  else [
    append/only mold-stack block
    for-next block block [
      if not head? block [append r f/delimiter]
      append r form block/1
    ]
    take/last mold-stack
  ]
  r
]

spaced: specialize :delimit [delimiter: space]

unspaced: specialize :delimit [delimiter: ""]

print: adapt :lib/print [
  line: form reduce line
]

??: probe: function [
    value [<opt> any-value!]
    return: [<opt> any-value!]
    /form
  ][
  if form [print :value]
  else [print mold :value]
  :value
]

!!: dump: function [
    :value [word! text! block! group!]
  ][
  elide case [
    word? value [print [
        mold value "=>" mold reduce value
    ]]
    group? value [print [
        mold value "=>" mold do value
    ]]
    text? value [
      print ["---" mold value "---"]
    ]
    block? value [for-next value value [
        do reduce ['dump value/1]
    ] ]
  ]
]

at: function [series index /only] [any [
  attempt [applique :lib/at [series: series index: index only: only]]
  all [
    attempt [method: :series/custom-type/at]
    attempt [applique :method [series: series index: index only: only]]
  ]
  fail-invalid-parameter 'at [series index]
]]

pick: function [
    location [any-value!]
    picker [any-value!]
  ][any [
  attempt [lib/pick location picker]
  try-method-1 'pick location picker
  fail-invalid-parameter 'pick [location picker]
]]

custom-func: enfix function [:name :arg] [
  set-name: name
  name: to-word name
  set :name function compose [(arg)]
  compose/deep [
    ;; try not customized version
    if not err: trap [r: lib/(name) (arg)]
    [return r]
    ;; try arg method
    if attempt [(set-name) (to-get-path reduce [arg 'custom-type name])]
    [ err: trap [r: (name) (arg)] ]
    ;; return or fail
    if error? err [fail err]
    r
  ]
]

custom-func2: enfix function [:name :arg1 :arg2] [
  set-name: name
  name: to-word name
  set :name function compose [(arg1) (arg2)]
  compose/deep [
    ;; try not customized version
    err: trap [r: lib/(name) (arg1) (arg2)]
    if not error? err [return r]
    ;; try arg1 method
    if attempt [(set-name) (to-get-path reduce [arg1 'custom-type name])]
    [ err: trap [r: (name) (arg1) (arg2)] ]
    if not error? err [return r]
    ;; try arg2 method
    if attempt [(set-name) (to-get-path reduce [arg2 'custom-type name])]
    [ err: trap [r: (name) (arg1) (arg2)] ]
    ;; return or fail
    if error? err [fail err]
    r
  ]
]

*: enfix
multiply: custom-func2 value1 value2
+: enfix
add: custom-func2 value1 value2
-: enfix
subtract: custom-func2 value1 value2
div: enfix
divide: custom-func2 value1 value2
**: enfix
power: custom-func2 number exponent
abs: custom-func value
negate: custom-func number
zero?: custom-func value
log-e: custom-func value
exp: custom-func power 
square-root: custom-func value 
sin: custom-func angle 
cos: custom-func angle 
asin: custom-func sine 
acos: custom-func cosine 
atan: custom-func tangent 

tan: function [angle] [any [
  attempt [lib/tangent/radians :angle]
  try-method 'tan angle
  attempt [lib/tangent/radians to-decimal :angle]
  fail-invalid-parameter 'tan 'angle
]]

sine: function [angle /radians] [any [
  attempt [applique :lib/sine [angle: :angle radians: radians]]
  attempt [ if not radians [
    angle: multiply angle deg-to-rad
  ] sin angle ]
  fail-invalid-parameter 'sine 'angle
]]

cosine: function [angle /radians] [any [
  attempt [applique :lib/cosine [angle: :angle radians: radians]]
  attempt [ if not radians [
    angle: multiply angle deg-to-rad
  ] cos angle ]
  fail-invalid-parameter 'cosine 'angle
]]

tangent: function [angle /radians] [any [
  attempt [applique :lib/tangent [angle: :angle radians: radians]]
  attempt [ if not radians [
    angle: multiply angle deg-to-rad
  ] tan angle ]
  fail-invalid-parameter 'tangent 'angle
]]

arcsine: function [sine /radians] [any [
  attempt [applique :lib/arcsine [sine: :sine radians: radians]]
  attempt [a: asin sine if not radians [
    a: multiply a rad-to-deg
  ] a]
  fail-invalid-parameter 'arcsine 'sine
]]

arccosine: function [cosine /radians] [any [
  attempt [applique :lib/arccosine [cosine: :cosine radians: radians]]
  attempt [a: acos cosine if not radians [
    a: multiply a rad-to-deg
  ] a]
  fail-invalid-parameter 'arccosine 'cosine
]]

arctangent: function [tangent /radians] [any [
  attempt [applique :lib/arctangent [tangent: :tangent radians: radians]]
  attempt [a: atan tangent if not radians [
    a: multiply a rad-to-deg
  ] a] 
  fail-invalid-parameter 'arcsine 'sine
]]

=: enfix equal?: function [value1 value2 r:] [
  if map? value1 [
    r: try attempt [value1/custom-type/equal? value1 value2]
    if any [r == true | r == false] [return r]
  ]
  if map? value2 [
    r: try attempt [value2/custom-type/equal? value1 value2]
    if any [r == true | r == false] [return r]
  ]
  lib/equal? value1 value2
]

!=: enfix not-equal?: function [value1 value2 r:] [
  not equal? value1 value2
]

==: enfix strict-equal?: function [value1 value2 r:] [
  if map? value1 [
    r: try attempt [value1/custom-type/strict-equal? value1 value2]
    if any [r == true | r == false] [return r]
  ]
  if map? value2 [
    r: try attempt [value2/custom-type/strict-equal? value1 value2]
    if any [r == true | r == false] [return r]
  ]
  lib/equal? value1 value2
]

!==: enfix strict-not-equal?: function [value1 value2 r:] [
  not strict-equal? value1 value2
]

set '< enfix lesser?: function [value1 value2 r:] [
  r: try attempt [lib/lesser? value1 value2]
  if any [r == true | r == false] [return r]
  r: try attempt [value1/custom-type/lesser? value1 value2]
  if any [r == true | r == false] [return r]
  r: try attempt [value2/custom-type/lesser? value1 value2]
  if any [r == true | r == false] [return r]
  false
]

set '> enfix greater?: function [value1 value2] [
  lesser? value2 value1
]

set '<= enfix lesser-or-equal?: function [value1 value2 r:] [
  r: try attempt [lib/lesser-or-equal? value1 value2]
  if any [r == true | r == false] [return r]
  r: try attempt [value1/custom-type/lesser-or-equal? value1 value2]
  if any [r == true | r == false] [return r]
  r: try attempt [value2/custom-type/lesser-or-equal? value1 value2]
  if any [r == true | r == false] [return r]
  false
]

set '>= enfix greater-or-equal?: function [value1 value2] [
  lesser-or-equal? value2 value1
]

] ; custom object

customize: function [
    code [block! object! word! action!]
    /words
  ][
  switch type of :code [
    word! [
      set :code :custom/:code
    ]
    object! [
      for-each w
        bind (intersect words-of custom words of :code) :code
        [ customize :w ]
    ]
    action! [bind body of :code custom]
    block! [
      if words [for-each w code [customize :w]]
      else [bind :code custom]
    ]
  ]
  :code
] 

; vim: set syn=rebol ts=2 sw=2 sts=2:
