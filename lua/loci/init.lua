local tbl = require('plenary.tbl')
local config = require('loci.config')
local workspace = require('loci.workspace')
local M = {}
local cmd = vim.api.nvim_command

function M.setup_hook() workspace.enter_workspace() end

function M.setup(opts)
    config = tbl.apply_defaults(opts, config)
    cmd('augroup LociSetupHook')
    cmd('autocmd! *')
    cmd('autocmd BufEnter ' .. config.directory .. '/**/*.(' ..
            table.concat(config.extensions, '|') ..
            ') lua require("loci").setup_hook()')
    cmd('augroup END')
end

return M
