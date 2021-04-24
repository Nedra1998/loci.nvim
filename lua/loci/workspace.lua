local config = require('loci.config')
local cmd = vim.api.nvim_command
local M = {}

function M.enter_workspace()
    if vim.bo.filetype ~= 'markdown' then return nil end
    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>',
                                [[:lua require'loci.link'.follow_or_insert_link()<CR>]],
                                {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', '<CR>',
                                [[:lua require'loci.link'.insert_link_visual()<CR>]],
                                {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '<BS>', [[:bp<CR>]],
                                {noremap = true, silent = true})

    cmd('augroup LociWorkspace')
    cmd('autocmd! *')
    if config.auto_link then
        cmd('autocmd BufWriteCmd ' .. config.directory .. '*.(' ..
                table.concat(config.extensions, '|') ..
                ') lua require("loci.link").auto_insert_link()')
    end
    if config.auto_index then
        cmd('autocmd BufWritePost ' .. config.directory ..
                '/diary/*.md lua require("loci.cmds").generate_diary_index()')
    end
    cmd('augroup END')

end

function M.leave_workspace() end

return M
