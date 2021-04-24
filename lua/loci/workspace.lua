local config = require('loci.config')
local M = {}

function M.enter_workspace(workspace)
    if config.workspaces[workspace] ~= nil then
        config.current_workspace = workspace
    else
        config.current_workspace = nil
    end

    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>',
                                [[:lua require'loci.link'.follow_or_insert_link()<CR>]],
                                {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', '<CR>',
                                [[:lua require'loci.link'.insert_link_visual()<CR>]],
                                {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '<BS>', [[:bp<CR>]],
                                {noremap = true, silent = true})
end

function M.leave_workspace() end

return M
