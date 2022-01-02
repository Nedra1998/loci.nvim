function! Reload() abort
	lua for k in pairs(package.loaded) do if k:match("^loci") then package.loaded[k] = nil end end
	lua require("loci")
endfunction

nnoremap rr :call Reload()<CR>
