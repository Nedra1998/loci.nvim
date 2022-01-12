local config = require("loci.config")

local M = {}

function M.default_mappings()
  vim.api.nvim_buf_set_keymap(0, 'n', '<CR>',
                              [[:lua require'loci.link'.follow_or_create('n')<CR>]],
                              {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(0, 'v', '<CR>',
                              [[:lua require'loci.link'.create('v')<CR>]],
                              {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(0, 'n', '<BS>',
                              [[:lua require'loci.link'.go_back()<CR>]],
                              {noremap = true, silent = true})
end

function M.setup(opts)
  config.cfg = require('plenary.tbl').apply_defaults(opts, config.cfg)
  local default_workspace = false
  for _, ws in pairs(config.cfg['workspaces']) do
    ws['path'] = vim.fn.expand(ws['path'])

    if ws['journals'] ~= nil then
      local default_journal = false
      for j, v in pairs(ws['journals']) do
        local cfg = {}
        if type(v) == 'string' then
          cfg = {recurrence = v}
        else
          cfg = v
        end

        if cfg['path'] == nil then cfg['path'] = j end
        if cfg['recurrence'] == nil then cfg['recurrence'] = 'daily' end
        if cfg['default'] == nil then cfg['default'] = false end

        if cfg['default'] == true then default_journal = true end

        local path = vim.fn.expand(cfg['path'])
        if path:sub(1, 1) ~= '/' then
          cfg['path'] = ws['path'] .. '/' .. path
        else
          cfg['path'] = path
        end
      end

      if not default_journal then
        for _, v in pairs(ws['journals']) do
          v['default'] = true
          break
        end
      end
    else
      ws['journals'] = {}
    end

    if ws['default'] == nil then
      ws['default'] = false
    elseif ws['default'] == true then
      default_workspace = true
    end
  end

  if not default_workspace then

    for _, v in pairs(config.cfg.workspaces) do
      v['default'] = true
      break
    end
  end

  vim.api.nvim_command('augroup LociSetupHook')
  vim.api.nvim_command('autocmd!')
  if config.cfg.default_mappings then
    vim.api.nvim_command(
        "autocmd FileType markdown lua require'loci'.default_mappings()")
  end
  for k, v in pairs(config.cfg.workspaces) do
    vim.api.nvim_command("autocmd BufEnter " .. vim.fn.expand(v.path) ..
                             "/* lua require'loci.workspace'.open('" .. k ..
                             "')")
  end
  vim.api.nvim_command('augroup END')
end

return M
