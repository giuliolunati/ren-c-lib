REBOL [ 
  Title: "ASCII plot tools"
  Type: module
  Name: aplot
  Author: "giuliolunati@gmail.com"
]

make-canvas: function [width height] [
	o: make object! [
		w: width
		h: height
		atx: aty: 0
		style: #"*"
    buf: make text! w + 1 * h
		loop h [
		  append/dup buf space w
			append buf newline
		]
		show: method [/half] [
		  if not half [print buf return]
			; half:
			h2: round/floor h + 1 / 2
			b: make text! to-integer w + 1 * h2
		  ?? b
			p1: buf
			p2: skip p1 w + 1
			loop h2 [
			  loop w [
					c: if any [not p2 p2/1 = space] [
						if p1/1 = space [space] else [#"'"]
					] else [
						if p1/1 = space [#","] else [#"¦"]
					]
					append b c
					p1: next p1 p2: attempt [next p2]
				]
				append b newline
				p1: skip p1 w + 2 p2: attempt [skip p2 w + 2]
			]
		  print b
		]
		at: goto: method [x y] [
		  atx: x
			aty: y
		]
		dot: method [] [
		  x: to-integer atx
			y: to-integer aty
			if all [x >= 0 y >= 0 x < w y < h] [
		    i: w + 1 * (to-integer aty)
				  + (to-integer atx)
				  + 1
		    poke buf i style
			]
		]
		line-to: method [x y] [
		  dot
			if all [
			  2 > abs (to-integer atx) - to-integer x
				2 > abs (to-integer aty) - to-integer y
			] [at x y dot return]
			line-to atx + x / 2 aty + y / 2
			line-to x y
		]
		line-to: method [tox toy] [
			x0: to-integer atx
			y0: to-integer aty
			tox: my to-integer
			toy: my to-integer
		  if (abs atx - tox) > (abs aty - toy) [
				dx: sign-of tox - atx
			  dy: toy - aty / (tox - atx) * dx
				x: atx y: aty
				dot loop abs tox - atx [
				  x: x + dx y: y + dy
					at x y dot
				]
			] else [
				dy: sign-of toy - aty
			  dx: tox - atx / (toy - aty) * dy
				y: aty x: atx
				dot loop abs toy - aty [
				  y: y + dy x: x + dx
					at x y dot
				]
			]
		]
	]
]

left: 0
right: _
step: 1
dot: #"*"
line: copy ""

histogram: function [x /x2 [any-number! logic!]] [
  clear line
  if x [
	  if all [right x > right] [x: right]
	  x: to-integer x - left / step + 1
	] else [x: 0]
  if not null? x2 [
    if x2 [
	    if all [right x2 > right] [x2: right]
		  x2: to-integer x2 - left / step + 1
		] else [x2: 0]
    single: if x > x2 ["▀"] else ["▄"]
    append/dup line "█" min x x2
    append/dup line single abs x - x2
  ] else [
    append/dup line dot x
  ]
]

scale: function [width n /f [action!]] [
  s: append/dup (make text! 0) space width + 1
	d: n * step
  if :f [a: left]
	else [
		x: power 10 round/ceiling log-10 d
		for-each i [0.2 0.5 1] [
			if x * i >= d [d: x * i break]
		]
    a: round/ceiling/to left d
		f: x -> [x]
	]
  b: width * step + left
  cfor x a b d [
    i: to-integer round x - left / step + 1
    change at s i "^^"
    change at s i + 1 format n - 1 f x
  ]
  s
]


; vim: set syn=rebol sw=2 ts=2:
