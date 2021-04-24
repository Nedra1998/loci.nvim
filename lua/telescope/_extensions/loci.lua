local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    error("This plugin requires nvim-telescope/telescope.nvim")
end

local conf = require('telescope.config').values
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local make_entry = require('telescope.make_entry')
local path = require('telescope.path')

local loci = {}
local list = require('loci.list')

loci.find_zettels = function(opts)
    local results = {}
    for _, zettel in ipairs(list.list_documents()) do
        results[#results + 1] = zettel.path
    end

    if opts.cwd then opts.cwd = vim.fn.expand(opts.cwd) end

    pickers.new(opts, {
        prompt_title = 'Zettels',
        finder = finders.new_table({
            results = results,
            entry_maker = make_entry.gen_from_file(opts)
        }),
        previewer = conf.file_previewer(opts),
        sorter = conf.file_sorter(opts)
    }):find()
end

loci.find_forward_links = function(opts)
    if opts.cwd then
        opts.cwd = vim.fn.expand(opts.cwd)
    else
        opts.cwd = vim.fn.getcwd()
    end

    local results = {}
    for _, link in ipairs(list.list_forward_links(vim.fn.expand("%:p"))) do
        results[#results + 1] = link.dest_file
    end

    pickers.new(opts, {
        prompt_title = 'Forward Links',
        finder = finders.new_table({
            results = results,
            entry_maker = make_entry.gen_from_file(opts)
        }),
        previewer = conf.file_previewer(opts),
        sorter = conf.file_sorter(opts)
    }):find()
end

loci.find_backward_links = function(opts)
    if opts.cwd then
        opts.cwd = vim.fn.expand(opts.cwd)
    else
        opts.cwd = vim.fn.getcwd()
    end

    local results = {}
    for _, link in ipairs(list.list_backward_links(vim.fn.expand("%:p"))) do
        results[#results + 1] = path.make_relative(link.src_file, opts.cwd) ..
                                    ':' .. link.src_line .. ':0:'
    end

    pickers.new(opts, {
        prompt_title = 'Forward Links',
        finder = finders.new_table({
            results = results,
            entry_maker = make_entry.gen_from_vimgrep(opts)
        }),
        previewer = conf.grep_previewer(opts),
        sorter = conf.generic_sorter(opts)
    }):find()
end

return telescope.register_extension {exports = loci}
