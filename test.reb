import 'complex

my!: make map! reduce [
  'custom-type true
  'form func [value] ["I'm a my!"]
]

m: make map! reduce [
  'custom-type my!
]

print m

print 1 +i 2
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
