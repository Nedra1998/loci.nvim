local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end

local conf = require('telescope.config').values
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local make_entry = require('telescope.make_entry')

local search = require('loci.search')
local config = require('loci.config')
local journal = require('loci.journal')

local M = {}

function M.notes(opts)
  local results = search.notes(opts.wkey)

  opts.cwd = config.ws.path

  pickers.new(opts, {
    prompt_title = 'Notes',
    finder = finders.new_table({
      results = results,
      entry_maker = make_entry.gen_from_file(opts)
    }),
    previewer = conf.file_previewer(opts),
    sorter = conf.file_sorter(opts)
  }):find()
end

function M.journal(opts)
  local jnl = journal.open(opts.wkey, opts.jkey)
  local results = search.journal(opts.wkey, opts.jkey)

  opts.cwd = jnl.path

  pickers.new(opts, {
    prompt_title = 'Journal Entries',
    finder = finders.new_table({
      results = results,
      entry_maker = make_entry.gen_from_file(opts)
    }),
    previewer = conf.file_previewer(opts),
    sorter = conf.file_sorter(opts)
  }):find()
end

function M.links(opts)
  local results = search.links(opts.path)
  opts.cwd = config.ws.path

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

function M.backlinks(opts)
  local results = search.backlinks(opts.wkey, opts.path)
  opts.cwd = config.ws.path

  pickers.new(opts, {
    prompt_title = 'Backlinks',
    finder = finders.new_table({
      results = results,
      entry_maker = make_entry.gen_from_file(opts)
    }),
    previewer = conf.file_previewer(opts),
    sorter = conf.file_sorter(opts)
  }):find()
end

return telescope.register_extension({exports = M})
