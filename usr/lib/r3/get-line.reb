REBOL [
  Name: input-line
  Type: module
  Author: ["@draegtun" "Giulio Lunati"]
  Description: "read lines from pipe"
  Exports: [input-line get-line]
]

get-line: function [
    p [port! blank!]
    <static> buffer (make binary! 4096)
  ][
  data: _
  forever [
    if f: try find buffer #{0D} [
      remove f
    ]
    if f: try find buffer #{0A} [
      remove f
      break
    ]
    if any [not p | same? p system/ports/input]
    [ data: read system/ports/input ]
    else
    [ data: read/part p 4096 ]
    if empty? data [
      f: length of buffer
      break
    ]
    append buffer data
  ]
  if all [empty? data empty? buffer] [
    return _
  ]
  to-text take/part buffer f
]

input-line: specialize :get-line [p: _]

; vim: set sw=2 ts=2 sts=2 expandtab:

