if exists('g:loaded_loci') | finish | endif

command! -nargs=? LociWorkspace lua require'loci.workspace'.open(<f-args>)
" command! -nargs=* LociJournalIndex echoerr '<args>'
command! -nargs=* LociJournalPrevious lua require'loci.journal'.previous(<f-args>)
command! -nargs=* LociJournalCurrent lua require'loci.journal'.current(<f-args>)
command! -nargs=* LociJournalNext lua require'loci.journal'.next(<f-args>)
command! -nargs=* LociJournal lua require'loci.journal'.date(<f-args>)
command! LociLinkCreate lua require'loci.link'.create('n')
command! LociLinkCreateVisual lua require'loci.link'.create('v')
command! LociLinkFollow lua require'loci.link'.follow()
command! LociLinkFollowOrCreate lua require'loci.link'.follow_or_create('n')
command! LociLinkFollowOrCreateVisual lua require'loci.link'.follow_or_create('v')
command! LociLinkGoBack lua require'loci.link'.go_back()

let s:save_cpo = &cpo
set cpo&vim

let g:loaded_loci = 1

let &cpo = s:save_cpo
unlet s:save_cpo
