local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    error("This plugin requires nvim-telescope/telescope.nvim")
end

local utils = require('telescope.utils')
local path = require('telescope.path')
local Path = require('plenary.path')
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values

local loci = require("loci")
local loci_functions = require("loci.functions")
local inspect = require('loci.inspect')

do
    local lookup_keys = {value = 1, ordinal = 1}

    -- Gets called only once to parse everything out for the vimgrep, after that looks up directly.
    local parse = function(t)
        local _, _, filename, lnum = string.find(t.value, [[([^:]+):(%d+)]])

        local ok
        ok, lnum = pcall(tonumber, lnum)
        if not ok then lnum = nil end

        t.filename = filename
        t.lnum = lnum

        return {filename, lnum, col, text}
    end

    --- Special options:
    ---  - shorten_path: make the path appear short
    ---  - disable_coordinates: Don't show the line & row numbers
    ---  - only_sort_text: Only sort via the text. Ignore filename and other items
    function gen_from_zettel(opts)
        local mt_vimgrep_entry

        opts = opts or {}

        local disable_devicons = opts.disable_devicons
        local shorten_path = opts.shorten_path
        local disable_coordinates = opts.disable_coordinates

        local execute_keys = {
            path = function(t)
                if Path:new(t.filename):is_absolute() then
                    return t.filename, false
                else
                    return t.cwd .. path.separator .. t.filename, false
                end
            end,

            filename = function(t) return parse(t)[1], true end,

            lnum = function(t) return parse(t)[2], true end
        }

        local display_string = "%s:%s"

        mt_vimgrep_entry = {
            cwd = vim.fn.expand(opts.cwd or vim.fn.getcwd()),

            display = function(entry)
                local display_filename
                if shorten_path then
                    display_filename = utils.path_shorten(entry.filename)
                else
                    display_filename = entry.filename
                end

                local coordinates = ""
                if not disable_coordinates then
                    coordinates = string.format("%s", entry.lnum)
                end

                local display, hl_group =
                    utils.transform_devicons(entry.filename, string.format(
                                                 display_string,
                                                 display_filename, coordinates),
                                             disable_devicons)

                if hl_group then
                    return display, {{{1, 3}, hl_group}}
                else
                    return display
                end
            end,

            __index = function(t, k)
                local raw = rawget(mt_vimgrep_entry, k)
                if raw then return raw end

                local executor = rawget(execute_keys, k)
                if executor then
                    local val, save = executor(t)
                    if save then rawset(t, k, val) end
                    return val
                end

                return rawget(t, rawget(lookup_keys, k))
            end
        }

        return function(line)
            print(line)
            local tmp = setmetatable({line}, mt_vimgrep_entry)
            print(dump(tmp))
            return tmp
        end
    end
end

local function back_links(opts)
    loci_functions.get_workspace_metadata(loci.config.cw)
    local cfile = vim.fn.expand("%:p")
    local results = {}
    for fname, val in pairs(loci.cache) do
        if val['links'][cfile] ~= nil then
            results[#results + 1] = fname .. ':' .. val['links'][cfile] .. ':1:'
        end
    end
    print(inspect(results))
    pickers.new(opts, {
        prompt_title = 'Zettle Backlinks',
        finder = finders.new_table {
            results = results,
            entry_maker = make_entry.gen_from_vimgrep(opts)
            -- entry_maker = gen_from_zettel(opts)
        },
        previewers = conf.grep_previewer(opts),
        sorter = conf.generic_sorter(opts)
    }):find()
end

return telescope.register_extension {exports = {back_links = back_links}}
