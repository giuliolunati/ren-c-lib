REBOL [
  Name: 'input-line
  Type: module
  Author: ["@draegtun" "adapted to Ren/C by Giulio Lunati"]
  Description: "read lines from pipe"
  Exports: [input-line]
]


input-line: function [
    {Return next line (string!) from STDIN.  Returns _ when nothing left}
    <static> buffer (make string! 1024)
  ][
    data: _
    forever [
        if f: find buffer newline [
            remove f    ;; chomp newline (NB. doesn't cover Windows CRLF?)
            break
        ]

        if empty? (data: read system/ports/input) [
            f: length? buffer
            break
        ]
        append buffer to-string data
    ]

    unless all [empty? data empty? buffer] [return take/part buffer f]
    _
]

; vim: set sw=2 ts=2 sts=2 expandtab:
