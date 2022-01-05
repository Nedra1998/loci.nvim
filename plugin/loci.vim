if exists('g:loaded_loci') | finish | endif

" expose vim commands and interface here
" nnoremap <Plug>PlugCommand :lua require(...).plug_command()<CR>

" command! LociFollowPath lua require'loci'.files.follow_path()
" command! LociGoBack lua require'loci'.files.go_back()
command! -nargs=? LociWorkspace lua require'loci.workspace'.open(<f-args>)
" command! -nargs=* LociJournalIndex echoerr '<args>'
command! -nargs=* LociJournalPrevious lua require'loci.journal'.previous(<f-args>)
command! -nargs=* LociJournalCurrent lua require'loci.journal'.current(<f-args>)
command! -nargs=* LociJournalNext lua require'loci.journal'.next(<f-args>)
command! -nargs=* LociJournal lua require'loci.journal'.date(<f-args>)
command! LociLinkCreate echoerr '<args>'
command! LociLinkFollow echoerr '<args>'
command! LociLinkFollowOrCreate echoerr '<args>'
command! LociLinkGoBack echoerr '<args>'

let s:save_cpo = &cpo
set cpo&vim

let g:loaded_loci = 1

let &cpo = s:save_cpo
unlet s:save_cpo
