local Path = require('plenary.path')
local config = require('loci.config')
local M = {}

local MARKDOWN_PATTERN = '%[[^]]+%]%(([^)]+)%)'
local DOCUMENTS = nil

local function case_insensitive_pattern(pattern)
    local p = pattern:gsub("(%%?)(.)", function(percent, letter)
        if percent ~= "" or not letter:match("%a") then
            return percent .. letter
        else
            return string.format("[%s%s]", letter:lower(), letter:upper())
        end
    end)
    return p
end

local function find_document_path(text, cwd)
    if DOCUMENTS == nil then
        DOCUMENTS = require('loci.list').list_documents()
    end

    local pattern = case_insensitive_pattern(text)
    for _, doc in ipairs(DOCUMENTS) do
        if doc.title:find(pattern) then
            return Path:new(doc.path):make_relative(cwd)
        end
    end
    return nil
end

local function get_link_path_markdown(col, line)
    local mbegin, mend = 0, 0
    repeat
        mbegin, mend = line:find(MARKDOWN_PATTERN, mend)
        if mbegin ~= nil and mend ~= nil and mbegin <= col and mend >= col then
            return line:sub(mbegin, mend):match(MARKDOWN_PATTERN)
        end
    until mbegin == nil or mend == nil
    return nil
end

local function create_link_markdown(line, vbegin, vend, dest)
    return line:sub(0, vbegin - 1) .. '[' .. line:sub(vbegin, vend) .. '](' ..
               dest .. ')' .. line:sub(vend + 1)
end

local function create_link(line, vbegin, vend, dest)
    if vim.bo.filetype == 'markdown' then
        return create_link_markdown(line, vbegin, vend, dest)
    else
        return line
    end
end

-- Follow the link in the current buffer located under the cursor.
-- @param pos Optional cursor position to follow, will fetch the current cursor
-- position if not provided.
function M.follow_link(pos)
    pos = pos or vim.fn.getcurpos()

    local line = vim.fn.getline(pos[2])
    local path = nil

    if vim.bo.filetype == "markdown" then
        path = get_link_path_markdown(pos[3], line)
    end
    if path == nil then return false end

    path = Path:new(vim.fn.expand("%:p:h")):joinpath(path):absolute()

    local dir = vim.fn.fnamemodify(path, ':p:h')
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end
    vim.api.nvim_command('edit ' .. path)
    return true
end

function M.insert_link(mode)
    mode = mode or 'n'
    local cwd = vim.fn.expand("%:p:h")
    local vbegin, vend = nil, nil
    local line, lineno = nil, nil

    -- Extract the bounds of the word, the line containing the word, the line
    -- number for that line, and the word itself. This is all language agnostic
    -- and so can be done in this common location.
    if mode == 'n' then
        local pos = vim.fn.getcurpos()
        line = vim.fn.getline(pos[2])
        lineno = pos[2]
        local select = vim.fn.expand('<cword>')
        vend = 0
        repeat vbegin, vend = line:find(select, vend) until vbegin == nil or
            vend == nil or (pos[3] >= vbegin and pos[3] <= vend)
        if vbegin == nil or vend == nil then return nil end
    elseif mode == 'v' then
        vbegin, vend = vim.fn.getpos("'<"), vim.fn.getpos("'>")
        line = vim.fn.getline(vbegin[2])
        lineno = vbegin[2]
        vbegin, vend = vbegin[3], vend[3]
    else
        return nil
    end

    -- Determine link destination, if a matching path or title is available
    -- prefer that, if not create a new file format friendly destination from the
    -- link text
    local dest = find_document_path(line:sub(vbegin, vend), cwd)
    if dest == nil then
        local default_extension = config.extensions[1]
        dest =
            line:sub(vbegin, vend):gsub('[%p%c]', ''):gsub('%s', '_'):lower() ..
                '.' .. default_extension
    end

    line = create_link(line, vbegin, vend, dest)

    -- Write the new line out to the buffer.
    vim.fn.setline(lineno, line)

end

function M.insert_link_visual() return M.insert_link('v') end

function M.follow_or_insert_link()
    if M.follow_link() ~= true then M.insert_link() end
end

function M.auto_insert_links()
    local list = require('loci.list')
    DOCUMENTS = list.list_documents()

    local path = vim.fn.expand('%:p')
    local cwd = Path:new(path):parent()
    local lines = vim.fn.getline(1, '$')
    local forward_links = list.get_links(path, lines, vim.bo.filetype)

    local patterns = {}
    for _, doc in ipairs(DOCUMENTS) do
        if doc.path ~= path then
            local exists = false
            for _, l in ipairs(forward_links) do
                if l.dest_file == doc.path then exists = true end
            end
            if exists == false then
                patterns[case_insensitive_pattern(doc.title)] = doc
            end
        end
    end

    for i, line in ipairs(lines) do
        local modified = false
        for patt, doc in pairs(patterns) do
            local mbegin, mend = line:find(patt)
            if mbegin ~= nil and mend ~= nil then
                line = create_link(line, mbegin, mend,
                                   Path:new(doc.path):make_relative(cwd))
                patterns[patt] = nil
                modified = true
            end
        end
        if modified then vim.fn.setline(i, line) end
    end
end

return M
