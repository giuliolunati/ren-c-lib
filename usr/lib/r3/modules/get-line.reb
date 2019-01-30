REBOL [
  Name: input-line
  Type: module
  Author: ["@draegtun" "Giulio Lunati"]
  Description: "read lines from pipe"
  Exports: [
    input-line
    input-lines
    get-line
    get-lines
  ]
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

get-lines: function [
    p [port! blank!]
  ][
  data: make block! 0
  while [l: get-line p] [append data l]
]

input-line: specialize :get-line [p: _]
input-lines: specialize :get-lines [p: _]

; vim: set sw=2 ts=2 sts=2 expandtab:

