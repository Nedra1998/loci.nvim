local M = {}

M.cache = {}

local function set_autogroup(cfg)
    local cmd = vim.api.nvim_command
    cmd([[augroup LociSetupHook]])
    cmd([[autocmd! *]])
    for key, val in pairs(cfg['workspaces']) do
        cmd('autocmd BufEnter ' .. val['dir'] ..
                '*.md lua require("loci.functions").workspace_enter(\"' .. key ..
                '\")')
    end
    cmd([[augroup END]])
end

do
    local default_config = {
        default_workspace = 'loci',
        map = true,
        link_on_save = true,
        workspaces = {
            ['loci'] = {
                dir = '~/Loci.new',
                index = 'README.md',
                auto_indexed = {'diary', 'notes'}
            }
        }
    }
    function M.setup(user_config)
        M.config = vim.tbl_extend('force', default_config, user_config or {})

        set_autogroup(M.config)
    end
end
return M
