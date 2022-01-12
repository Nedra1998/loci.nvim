local config = require("loci.config")

local M = {}

function M.default_mappings()
      vim.api.nvim_buf_set_keymap(0, 'n', '<CR>',
                                [[:lua require'loci.link'.follow_or_create('n')<CR>]],
                                {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', '<CR>',
                                [[:lua require'loci.link'.create('v')<CR>]],
                                {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '<BS>', [[:lua require'loci.link'.go_back()<CR>]],
                                {noremap = true, silent = true})
end

function M.setup(opts)
  config.cfg = require('plenary.tbl').apply_defaults(opts, config.cfg)
  vim.api.nvim_command('augroup LociSetupHook')
  vim.api.nvim_command('autocmd!')
  if config.cfg.default_mappings then
    vim.api.nvim_command("autocmd FileType markdown lua require'loci'.default_mappings()")
  end
  for k, v in pairs(config.cfg.workspaces) do
    vim.api.nvim_command("autocmd BufEnter " .. vim.fn.expand(v.path) .. "/* lua require'loci.workspace'.open('" .. k .. "')")
  end
  vim.api.nvim_command('augroup END')
end

return M
