#!/usr/bin/r3
REBOL []

args: system/script/args
ifile: join system/options/path args/1
dt: to-time args/2

text: deline read ifile

!digit: charset "0123456789"
!number: [some !digit]
!timechar: union !digit charset ":.,"
!time: [some !timechar]

parse text [ while [
  [ copy t newline 
  | copy t !number newline
  | copy t1 !time some space
    "-->" some space
    copy t2 !time newline
    (t: spaced [dt + to-time t1 "-->" dt + to-time t2])
  | copy t to newline skip
  ] (print t)
]]

