Rebol [
	Type: module
	Name: html
]

text: import 'text
dot: import 'dot

mchar: charset "<&>"
mchar+quot: union mchar charset #"^""
mchar+apos: union mchar charset #"'"

entities: make map! [
	#"<" "&lt;"
	#">" "&gt;"
	#"&" "&amp;"
	#"^"" "&quot;"
	#"'" "&apos;"
]

++: enfix :repend

mold-text: function [txt /quot /apos t:] [
  r: make text! 2
	xchar: case [
	  quot [mchar+quot]
		apos [mchar+apos]
		default [mchar]
	]
	parse txt [any
		[ set t xchar (r ++ entities/:t)
		| copy t [to xchar | to end]
		  (r ++ t)
		]
	]
	case [
		quot [unspaced [{"} r {"}]]
		apos [unspaced [{'} r {'}]]
		default [r]
	]
]
		
mold-attribute: function [a v] [
	if not text? v [v: form v]
	unspaced [to-word a "=" mold-text/quot v]
]

mold-property: function [name val] [
	name: to-set-word name
	if quoted? val [v: mold-text/apos form val]
	r: spaced [to-set-word name val]
]

to-html: function [
  tok [quoted! block!]
] [
  t: a: v: _
	style: make text! 2
  r: make text! 2
  if quoted? tok [tok: eval tok]
  parse tok [any
    [ set t text! (r ++ mold-text t)
		| set t get-word!
			(r ++ ["</" to-word t ">"])
    | set t [word! | set-word!]
      (clear style | r ++ ["<" to-word t])
      any
			[ set a refinement! set v skip
        (r ++ [" " mold-attribute a v])
			| set a path! 
				:(all [2 = length-of a
					not a/1 set-word? a/2])
				set v skip
				(style ++ unspaced [
					if not empty? style [space]
					mold-property a/2 v ";"
				])
      ]
			(if not empty? style [r ++ [
				" " mold-attribute 'style style
			]])
      (r ++ either word? t ["/>"] [">"])
    | skip
    ]
  ] 
  r
]


; vim: set sw=2 ts=2 sts=2:
