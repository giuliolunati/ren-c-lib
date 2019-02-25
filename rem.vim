" Vim syntax file
" Language:	REM (REbol Markup)
" Maintainer:	Giulio Lunati <giuliolunati@gmail.com>
" Filenames:	*.rem
" Last Change:	2017-03-20
"
runtime syntax/rebol.vim

syn sync fromstart
syn keyword    remMarkup   doc header title head style script body div h1 h2 h3 h4 h5 h6 p span b i table tr td br hr img 

" Strings
syn clear      rebolString1
syn clear      rebolString2
syn region      remString1     start=+"+ skip=+""+ end=+"+ contains=rem2dquote,remSpecial,remMarkdown

syn region      remString2     matchgroup=Special start=+{+ matchgroup=Special end=+}+ contains=remString2,remSpecial,remMarkdown

syn match       remSpecial   contained "\\"
syn match       rem2dquote   containedin=remString1 "\"\""
syn match       remMarkdown  contained "[*_]"
syn match       remMarkdown  contained "[a-zA-Z-]\+{"me=e-1

if version >= 508 || !exists("did_rebol_syntax_inits")
  if version < 508
    let did_rebol_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink remMarkup     Statement
  HiLink remMarkdown   PreProc
  HiLink remString1    Constant
  HiLink remString2    Constant
  HiLink remSpecial    PreProc
  HiLink rem2dquote    PreProc

  delcommand HiLink
endif

" vim: sw=2 ts=2 sts=2 expandtab:
