if exists('g:loaded_loci')
  finish
endif

command! -nargs=* LociIndex lua require'loci.workspace'.open_index(<f-args>)
command! -nargs=* LociDiaryIndex lua require'loci.diary'.open_diary_index(<f-args>)
command! -nargs=* LociMakeDiaryNote lua require'loci.diary'.open_diary(<f-args>)
command! -nargs=* LociMakeYesterdayDiaryNote lua require'loci.diary'.open_diary('yesterday', <f-args>)
command! -nargs=* LociMakeTomorrowDiaryNote lua require'loci.diary'.open_diary('tomorrow', <f-args>)
command! -nargs=* LociGenerateDiaryIndex lua require'loci.diary'.generate_diary_index(<f-args>)

let g:loaded_loci = 1
