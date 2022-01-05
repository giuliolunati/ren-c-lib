csv-fields: "Name,Given Name,Additional Name,Family Name,Name Prefix,Name Suffix,Initials,Nickname,Short Name,Maiden Name,Birthday,Gender,Location,Billing Information,Directory Server,Mileage,Occupation,Hobby,Sensitivity,Priority,Subject,Notes,Language,Photo,Group Membership,E-mail 1 - Type,E-mail 1 - Value,Phone 1 - Type,Phone 1 - Value"

clean: func [s] [
  replace/all s "_" " "
]

dquote: func [s] [
  if not s [return {""}]
  replace/all s "\" "\\"
  replace/all s {"} {\"}
  return unspaced[{"} s {"}]
]

to-csv: func [m] [
  let t: make text! 32
  for-each i reduce [
    spaced [m.name m.fname] m.name _ m.fname
    _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ m.notes _ _ _
    "Principale" m.emails.1
    "Principale" m.phones.1
  ] [
    if bad-word? i [i: _]

    if not empty? t [append t ","]
    append t dquote i
  ]
  return t
]

wspace: charset " ^-^/"
space?: [while wspace]
nspace: complement wspace

empty-line: [space? [end | ";" to end]]

digit: charset "0123456789"
integer: [some digit]

id: ["#" some nspace]

pchar: union charset ".-" digit
phone: [opt "+" 5 pchar while pchar]

echar: complement union wspace charset "@"
nchar: complement
  union charset "@#" union wspace digit
name: [some nchar ahead not "@"]
email: [some echar "@" some echar]

print csv-fields

loop compose [l: (input-lines)] [
  ; [#id] name [name] [tel | email]...
  if not parse? l [
    [ empty-line
    | (
        m: make map! 8
        m.phones: make block! 0
        m.emails: make block! 0
      )
      opt [
        copy x id (m.id: x)
      ]
      space?
      copy x name (m.name: clean x)
      space?
      opt [copy x name (m.fname: clean x)]
      space?
      while
      [ copy x phone (append m.phones x)
        space?
      | copy x email (append m.emails x)
        space?
      ]
      copy x to end ((empty? x) or (m.notes: x))
      (print to-csv m)
    ]
  ] [fail l]
]
