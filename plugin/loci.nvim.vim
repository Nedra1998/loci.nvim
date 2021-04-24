if exists('g:loaded_loci')
  finish
endif

command! LociIndex lua require'loci.cmds'.open_index()
command! LociDiaryIndex lua require'loci.cmds'.open_diary_index()
command! LociMakeDiaryNote lua require'loci.cmds'.open_diary()
command! LociMakeYesterdayDiaryNote lua require'loci.cmds'.open_diary('yesterday')
command! LociMakeTomorrowDiaryNote lua require'loci.cmds'.open_diary('tomorrow')
command! LociGenerateDiaryIndex lua require'loci.cmds'.generate_diary_index()

let g:loaded_loci = 1
