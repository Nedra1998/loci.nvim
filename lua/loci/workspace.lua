local api = vim.api
local fn = vim.fn
local config = require('loci.config')

local M = {}

function M.on_exit(workspace)
  if config.workspaces[workspace] ~= nil and
      config.workspaces[workspace].on_exit ~= nil then
    config.workspace[workspace].on_exit()
  end
end

function M.on_enter(workspace)
  if vim.bo.filetype ~= 'markdown' then return nil end

  if config.current_workspace ~= nil and config.current_workspace ~= workspace then
    M.on_exit(config.current_workspace)
  end

  if config.keymaps.links then
    api.nvim_buf_set_keymap(0, 'n', '<CR>',
                            [[:lua require'loci.link'.follow_or_create()<CR>]],
                            {noremap = true, silent = true})
    api.nvim_buf_set_keymap(0, 'v', '<CR>',
                            [[:lua require'loci.link'.create_link('v')<CR>]],
                            {noremap = true, silent = true})
    api.nvim_buf_set_keymap(0, 'n', '<BS>',
                            [[(&modified == 0 ? ':bdelete<CR>' : ':bprevious<CR>')]],
                            {noremap = true, silent = true, expr = true})
  end

  if config.workspaces[workspace].index_on_save ~= nil then
    local basepath = fn.expand(config.workspaces[workspace].path)
    vim.cmd('augroup Loci' .. workspace .. 'WorkspaceHook')
    vim.cmd('autocmd! *')
    for _, dir in pairs(config.workspaces[workspace].diaries) do
      vim.cmd('autocmd BufWritePost ' .. basepath .. '/' .. dir ..
              '/*.md lua require("loci.diary").generate_diary_index("' ..
              workspace .. '", "' .. dir .. '")')
    end
    vim.cmd('augroup END')
  end

  if config.workspaces[workspace] ~= nil and config.current_workspace ~=
      workspace and config.workspaces[workspace].on_enter ~= nil then
    config.workspace[workspace].on_enter()
  end

  config.current_workspace = workspace
end

function M.open_index(workspace)
  workspace = workspace or config.current_workspace
  if workspace == nil then
    for k, v in pairs(config.workspaces) do workspace = k end
  elseif config.workspaces[workspace] == nil then
    return nil
  end

  if fn.isdirectory(fn.expand(config.workspaces[workspace].path)) == 0 then
    fn.mkdir(fn.expand(config.workspaces[workspace].path), 'p')
  end
  api.nvim_command('edit ' .. fn.expand(config.workspaces[workspace].path) ..
                       '/README.md')
end

return M
