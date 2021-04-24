local tbl = require('plenary.tbl')
local config = require('loci.config')
local workspace = require('loci.workspace')
local M = {}
local cmd = vim.api.nvim_command

function M.setup_hook(ws) workspace.enter_workspace(ws) end

function M.setup(opts)
    config = tbl.apply_defaults(opts, config)
    cmd('augroup LociSetupHook')
    cmd('autocmd! *')
    for key, value in pairs(config.workspaces) do
        cmd('autocmd BufEnter ' .. value.directory ..
                '* lua require("loci").setup_hook("' .. key .. '")')
    end
    cmd('augroup END')
end

return M
