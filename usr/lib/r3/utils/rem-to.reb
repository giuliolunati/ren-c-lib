#!/usr/bin/r3
REBOL[]
rem: import 'rem
html: import 'html
args: system/options/args
change-dir system/options/path

dot: rem/load-rem to-file args/1
print html/mold-html dot
;; vim: set sw=2 ts=2 sts=2:
