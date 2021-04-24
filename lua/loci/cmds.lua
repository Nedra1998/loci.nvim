local config = require('loci.config')
local Path = require('plenary.path')
local M = {}

function M.open_index()
    local dir = Path:new(config.directory):expand()
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end
    vim.api.nvim_command('edit ' ..
                             Path:new(dir):joinpath(config.index):absolute())
end

function M.open_diary_index()
    local dir = Path:new(Path:new(config.directory):expand()):joinpath('diary/')
                    :absolute()
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end
    vim.api.nvim_command('edit ' ..
                             Path:new(dir):joinpath(
                                 'diary.' .. config.extensions[1]):absolute())
end

function M.open_diary(date)
    local dir = Path:new(Path:new(config.directory):expand()):joinpath('diary/')
    if date == nil or date == 'today' then
        vim.api.nvim_command('edit ' ..
                                 dir:joinpath(
                                     os.date("%Y-%m-%d") .. '.' ..
                                         config.extensions[1]):absolute())
    elseif date == 'yesterday' then
        vim.api.nvim_command('edit ' ..
                                 dir:joinpath(
                                     os.date("%Y-%m-%d", os.time() - 86400) ..
                                         '.' .. config.extensions[1]):absolute())
    elseif date == 'tomorrow' then
        vim.api.nvim_command('edit ' ..
                                 dir:joinpath(
                                     os.date("%Y-%m-%d", os.time() + 86400) ..
                                         '.' .. config.extensions[1]):absolute())
    elseif date:find("%d%d%d%d%-%d%d%-%d%d") then
        vim.api.nvim_command('edit ' ..
                                 dir:joinpath(
                                     date .. '.' .. config.extensions[1])
                                     :absolute())
    end
end

local MONTHS = {
    ['01'] = 'January',
    ['02'] = 'Feburary',
    ['03'] = 'March',
    ['04'] = 'April',
    ['05'] = 'May',
    ['06'] = 'June',
    ['07'] = 'July',
    ['08'] = 'August',
    ['09'] = 'September',
    ['10'] = 'October',
    ['11'] = 'November',
    ['12'] = 'December'
}

function M.generate_diary_index()
    local dir = Path:new(Path:new(config.directory):expand()):joinpath('diary/')
                    :absolute()
    local path = Path:new(dir):joinpath('diary.' .. config.extensions[1])
                     :absolute()
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end

    local files = vim.fn
                      .globpath(dir, '*.' .. config.extensions[1], false, true)
    table.sort(files, function(a, b) return a > b end)

    local lines = {"# Diary", "", ":private:"}
    local year, month = "0000", "00"

    for _, file in ipairs(files) do
        local fname = vim.fn.fnamemodify(file, ":t:r")
        if fname:find("%d%d%d%d%-%d%d%-%d%d") ~= nil then
            local fyear, fmonth = fname:sub(1, 4), fname:sub(6, 7)
            if year ~= fyear then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "## " .. fyear
                lines[#lines + 1] = ""
                lines[#lines + 1] = "### " .. MONTHS[fmonth]
                lines[#lines + 1] = ""
                year, month = fyear, fmonth
            elseif month ~= fmonth then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "### " .. MONTHS[fmonth]
                lines[#lines + 1] = ""
                month = fmonth
            end
            lines[#lines + 1] = "- [" .. fname .. "](" .. fname .. '.' ..
                                    config.extensions[1] .. ")"
        end
    end

    vim.fn.writefile(lines, path)
end

return M
