REBOL [
	System: "REBOL [R3] Language Interpreter and Run-time Environment"
	Title: "Build extension module"
	Rights: {
		Copyright 2012 REBOL Technologies
		REBOL is a trademark of REBOL Technologies
	}
	License: {
		Licensed under the Apache License, Version 2.0
		See: http://www.apache.org/licenses/LICENSE-2.0
	}
	Author: ["Carl Sassenrath" "Giulio Lunati"]
	Needs: 2.100.100
	Purpose: {
		make reb-leptonica.h from reb-leptonica.r
	}
]

secure none

form-header: func [title [string!] file [file!] /gen by] [
	print ["..." title]
	by: either gen [
		rejoin [{**  AUTO-GENERATED FILE - Do not modify. (From: } by {)^/**^/}]
	][""]

	rejoin [
{/***********************************************************************
**
**  Title: } title {
**  Date:  } now/date {
**  File:  } file {
**
} by 
{***********************************************************************/

}
	]
]

;-- Conversion to C strings, depending on compiler ---------------------------

to-cstr: either system/version/4 = 3 [
	; Windows format:
	func [str /local out] [
		out: make string! 4 * (length? str)
		out: insert out tab
		forall str [
			out: insert out reduce [to-integer first str ", "]
			if zero? ((index? str) // 10) [out: insert out "^/^-"]
		]
		;remove/part out either (pick out -1) = #" " [-2][-4]
		head out
	]
][
	; Other formats (Linux, OpenBSD, etc.):
	func [str /local out data] [
		out: make string! 4 * (length? str)
		forall str [
			data: copy/part str 16
			str: skip str 15
			data: enbase/base data 16
			forall data [
				insert data "\x"
				data: skip data 3
			]
			data: tail data
			insert data {"^/}
			append out {"}
			append out head data
		]
		head out
	]
]

;-- Collect Sources ----------------------------------------------------------

collect-files: func [
	"Collect contents of several source files and return combined with header."
	files [block!]
	/local source data header
][
	source: make block! 1000

	foreach file files [
		data: load/all file
		remove-each [a b] data [issue? a] ; commented sections
		unless block? header: find data 'rebol [
			print ["Missing header in:" file] halt
		]
		unless empty? source [data: next next data] ; first one includes header
		append source data
	]

	source
]

;-- Emit Functions -----------------------------------------------------------

out: make string! 10000
emit: func [d] [repend out d]

emit-cmt: func [text] [
	emit [
{/***********************************************************************
**
**  } text {
**
***********************************************************************/

}]
]

form-name: func [word] [
	uppercase replace/all replace/all to-string word #"-" #"_" #"?" #"Q"
]

emit-file: func [
	"Emit command enum and source script code."
	file [file!]
	source [block!]
	/local title name data exports words exported-words src prefix
][
	source: collect-files source

	title: select source/2 to-set-word 'title
	name: form select source/2 to-set-word 'name
	replace/all name "-" "_"
	prefix: uppercase copy name

	clear out
	emit form-header/gen title second split-path file %make-host-ext.r

	emit ["enum " name "_commands {^/"]

	; Gather exported words if exports field is a block:
	words: make block! 100
	exported-words: make block! 100
	src: source
	while [src: find src set-word!] [
		if all [
			<no-export> <> first back src
			find [command func function funct] src/2
		][
			append exported-words to-word src/1
		]
		if src/2 = 'command [append words to-word src/1]
		src: next src
	]

	if block? exports: select second source to-set-word 'exports [
		insert exports exported-words
	]

	foreach word words [emit [
		tab "CMD_"
		;prefix #"_"
		replace/all form-name word "'" "_LIT"
		",^/"
	]]
	emit "};^/^/"

	if src: select source to-set-word 'words [
		emit ["enum " name "_words {^/"]
		emit [
			tab "W_"
			;prefix #"_"
			"0,^/"]
		foreach word src [emit [
			tab "W_"
			;prefix #"_"
			form-name word ",^/"
		]]
		emit "};^/^/"
	]

	data: append trim/head mold/only/flat source newline
	append data to-char 0 ; null terminator may be required
	emit ["const unsigned char init_block[] = {^/" to-cstr data "^/};^/^/"]

	write rejoin [%./ file %.h] out

;	clear out
;	emit form-header/gen join title " - Module Initialization" second split-path file %make-host-ext.r
;	write rejoin [%../os/ file %.c] out
]

;-- Create Files -------------------------------------------------------------

emit-file %reb-leptonica [
	%reb-leptonica.r
]

print "   "
