use [t] [
  t: split system/options/boot "/"
  take/last/part t 2
  t: join to-file delimit "/" t "/lib/r3/modules/"
  insert either set? 'mutable
  [ mutable system/options/module-paths ]
  [ system/options/module-paths ]
  t
]

; vim: set syn=rebol et sw=2 ts=2:
