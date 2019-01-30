#!/usr/bin/r3
REBOL []

; record:
; 1: description
; 2: due
; 3: length

find-due: function [
  todo [block!] weight [time!]
  ][
  free: 0
  t: now
  for-each x todo [
    free: free - x/3
    if x/2 < t [continue]
    free: (subtract-date x/2 t) * ratio + free
    t: x/2
    if free >= weight [break]
  ]
  t: weight - free / ratio + t
  x: t/time
  x: x / 3 + case [
    x < 04:30 [11:00]
    x < 19:30 [13:00]
    x < 21:00 [17:00]
    true      [27:00]
  ]
  t/time: round/to x 0:5
  t
]

fix-date: function [d zone [time!]] [
  if any [not date? d | set? 'd/zone] [return d]
  d: d + zone
  d/zone: zone
  d
]

form-date: function [d [date!]] [
  s: make string! 48
  append s d/date append s space
  append s pick d 'time
]

load-todo: function [io [file!]] [
  l: read/lines io
  b: make block! (length l) / 2
  forskip l 2 [
    r: load l/2
    insert r l/1
    append/only b r
  ]
  b
]

move-item: procedure [
    todo [block!] i [integer!]
  ][
  x: take at todo i
  x/2: find-due todo x/3
  append/only todo x
]

print-all: procedure [todo [block!] /long] [
  sort-todo todo
  for i length todo 1 -1 [
    if long [print-item todo i]
    else [print-item/brief todo i]
  ]
  set 'index 1
]

print-item: procedure [
    todo [block!] i [integer!]
    /brief
  ][
  x: todo/:i
  print/only [
    i ": " x/1 
    " !" x/3
    newline
  ]
  if not brief [ print/only [
    "  " to-time subtract-date x/2 now
    "  " x/2
    newline
  ] ]
]

read-date: function [s [string!]] [
  r: now
  switch s [
    "t" "o" [s: "00:0"] ; today, oggi
    "a" "p" [s: "18:0"] ; afternoon, pomeriggio
    "m"     [s: "12:0"] ; morning, mattino, noon
  ]
  case [
    time? try [t: to-time s] [
      if t <= r/time [t: t + 24:0]
      d: r/date z: r/zone
      r/time: t
      r/date: d
      fix-date r z
    ]
    date? try [r: to-date s] [r]
    integer? try [i: to-integer s] [
      t: r/time
      if i <= r/day [r/month: r/month + 1]
      r/day: i
      r/time: t
      r
    ]
    #"+" = s/1 [
      i: to-decimal next s
      fix-date r + i r/zone
    ]
    i: index-of find [
      "lun" "mar" "mer" "gio" "ven" "sab" "dom"
      "mon" "tue" "wed" "thu" "fri" "sat" "sun"
    ] s [
      i: i - r/weekday // 7
      if i <= 0 [i: i + 7]
      fix-date r + to-decimal i r/zone
    ]
  ]
]

read-time: function [s [string!]] [
  case [
    time? try [r: to-time s] [r]
    integer? try [r: to-integer s] [to-time (r * 60)]
  ] else _  
]

sort-todo: procedure [todo [block!]] [
  t: now
  sort/compare todo func [a b] [
    ((to-integer b/3) * subtract-date a/2 t) < ((to-integer a/3) * subtract-date b/2 t)
  ]
]

subtract-date: function [a [date!] b [date!]] [
  a/date - b/date * 86400 + to-integer (a/time - b/time)
]

write-todo: procedure [io [file!] todo [block!]] [
  s: make string! 80 * length todo
  for-each x todo [
    repend s [x/1 newline x/2 space x/3 newline]  ]
  write io s
]

;;;;;;;; MAIN ;;;;;;;;

parse help-me: {
  d    : delete current item
  h, ? : this help
  p    : print todo list
  q    : quit
  w    : write to file (save)
  x    : save and exit
  N    : select Nth item
} [any [thru #"^/" opt remove ["^-" | "  "]]]

cd :system/options/path
arg: system/options/args
xchar: charset {@!}
index: 1
ratio: 0.25
zone: now/zone
io: todo: _

forall arg [
  io: to-file arg/1
]
io: default [join-of system/options/home %main.todo]
todo: any [attempt [load-todo io] | make block! 16]
print-all todo

forever [
  print/only "> "
  c: input
  item: todo/:index
  case [
    "" = c [print-all todo]
    find ["h" "?"] c [print help-me]
    "d" = c [remove at todo index]
    "m" = c [
      move-item todo index
      print-all todo
    ]
    "p" = c [print-all/long todo]
    "q" = c [break]
    find ["w" "x"] c [
      io: default
      [ print/only "file> " to-file input ]
      write-todo io todo
      if "x" = c [break]
    ]
    #"@" = c/1 [
      item/2: read-date next c
      print-item todo index
    ]
    #"!" = c/1 [
      item/3: read-time next c
      print-item todo index
    ]
    #">" = c/1 [
      if c: attempt [to-decimal next c]
      [ item/2: fix-date (item/2 + c) zone ]
      print-item todo index
    ]
    #"<" = c/1 [
      if c: attempt [to-decimal next c]
      [ item/2: fix-date (item/2 - c) zone ]
      print-item todo index
    ]
    attempt [i: to-integer c] [
      set 'index i
      print-item todo i
    ]
  ]
  else [
    weight: 0:5
    due: _
    x: _
    parse c [while [
      to space
      [ remove copy x [skip xchar [to " " | to end]]
        ( x: next x
          case [
            #"@" = x/1 [due: read-date next x]
            #"!" = x/1 [weight: read-time next x]
          ]
        )
      | skip
      ]
    ]]
    due: default [find-due todo weight]
    append/only todo reduce [c due weight]
    new-line back tail todo true
  ]
]

; vim: set sw=2 ts=2 sts=2 expandtab:
