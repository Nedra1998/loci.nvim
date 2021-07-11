local cmd = vim.api.nvim_command
local fn = vim.fn

local config = require('loci.config')

local M = {}

function M.setup(opts)
  config = require('plenary.tbl').apply_defaults(opts, config)

  cmd('augroup LociSetupHook')
  cmd('autocmd! *')
  for key, val in pairs(config.workspaces) do
    cmd('autocmd BufEnter ' .. fn.expand(val.path) ..
            '/* lua require("loci.workspace").on_enter("' .. key .. '")')
  end
  cmd('augroup END')
end

return M
