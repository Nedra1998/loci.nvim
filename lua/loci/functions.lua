local loci = require('loci')
local cache = loci.cache
local config = loci.config
local path = require('loci.path')
local detect_filetype = require('plenary.filetype').detect

local M = {}

-- Parses markdown source to find the note title, tags, and links to other
-- notes. Expects src to be a list of strings, where each string is a line.
function M.get_metadata(src, fpath)
    local metadata = {title = nil, tags = {}, links = {}}
    local in_block = false
    for idx, line in ipairs(src) do
        if metadata.title == nil and not in_block and line:find('^#%s.+') then
            metadata.title = line:sub(3)
        elseif line:find('^```') then
            in_block = not in_block
        elseif not in_block and line:find('%[[^%]]+%]%([^%)]+%.md%)') then
            local front, back = line:find('%[[^%]]+%]%([^%)]+%.md%)')
            while back ~= nil do
                local full_match = line:sub(front, back)
                local file_match =
                    full_match:match('%[[^%]]+%]%(([^%)]+%.md)%)')
                metadata.links[path.abs(path.dir(fpath), file_match)] = idx
                line = line:sub(back)
                front, back = line:find('%[[^%]]+%]%([^%)]+%.md%)')
            end
        end
    end
    return metadata
end

-- Collect metadata from the current vim buffer, uses the markdown filetype to
-- identify the metadata format.
function M.get_buffer_metadata()
    local source = vim.fn.getline(1, '$')
    return M.get_metadata(source, vim.fn.expand("%:p"))
end

-- Collect metadata from a file path, uses the extension of the filename to
-- identify the metadata format.
function M.get_path_metadata(fname)
    local ft = detect_filetype(fname)
    if ft == 'markdown' then
        return M.get_metadata(vim.fn.readfile(fname), fname)
    else
        return {title = '', tags = {}, links = {}}
    end
end

-- Collect all of the metadata for a specified workspace.
function M.get_workspace_metadata(workspace)
    local files = vim.fn.globpath(config.workspaces[workspace].dir, '**/*.md',
                                  false, true)
    for _, fname in ipairs(files) do
        if cache[fname] == nil then
            cache[fname] = M.get_path_metadata(fname)
        end
    end
end

-- Generates case insensitive regex pattern
local function insensitive(pattern)
    local p = pattern:gsub("(%%?)(.)", function(percent, letter)
        if percent ~= "" or not letter:match("%a") then
            return percent .. letter
        else
            return string.format("[%s%s]", letter:lower(), letter:upper())
        end
    end)
    return p
end

local function create_link(line, col, text, dest)
    local mstart, mend = nil, nil
    local pos = 1
    repeat
        mstart, mend = line:find(text, pos)
        pos = mend
    until mstart == nil or mend == nil or (col >= mstart and col <= mend)
    if mstart == nil or mend == nil then return line end
    return line:sub(1, mstart - 1) .. '[' .. text .. '](' .. dest .. ')' ..
               line:sub(mend + 1)
end

-- Looks through current buffer to find any potential links for other notes,
-- and converts those into links.
function M.auto_link()
    local cname = vim.fn.expand('%:p')
    local files = {}
    for fname, _ in pairs(cache) do
        if fname ~= cname then
            local name, _ = path.nameext(path.file(fname))
            files[insensitive(name)] = {path.rel(fname, path.dir(cname)), fname}
        end
    end
    local src = vim.fn.getline(1, '$')
    cache[cname] = M.get_metadata(src, cname)
    local in_block = false
    for idx, line in ipairs(src) do
        local modified = false
        if line:find('^```') then
            in_block = not in_block
        elseif line[1] == '>' then
        elseif not in_block then
            for key, fpath in pairs(files) do
                local front, back = line:find(key)
                if back ~= nil then
                    local lfront, lback =
                        line:find('%[' .. key .. '%]%([^%)]+%.md%)')
                    if not (lback ~= nil and front > lfront and back < lback) and
                        not (cache[cname] ~= nil and
                            cache[cname].links[fpath[2]] ~= nil) then
                        modified = true
                        line = line:sub(1, front - 1) .. '[' ..
                                   line:sub(front, back) .. '](' .. fpath[1] ..
                                   ')' .. line:sub(back + 1)

                        cache[cname].links[fpath[2]] = idx
                    end
                end
            end
        end
        if modified then vim.fn.setline(idx, line) end
    end
end

local function pushf(fpath)
    local dir = vim.fn.fnamemodify(fpath, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end
    vim.api.nvim_command('edit ' .. fpath)
end
local function popf() vim.api.nvim_command(':bp') end

function M.follow_link()
    local pos = vim.fn.getcurpos()
    local line = vim.fn.getline(pos[2])
    local pattern = '%[[^%]]+%]%(([^%)]+)%)'
    local mstart, mend = nil, 1
    repeat mstart, mend = line:find(pattern, mend) until mstart == nil or mend ==
        nil or (pos[3] >= mstart and pos[3] <= mend)
    if mstart ~= nil and mend ~= nil then
        local match = line:sub(mstart, mend):match(pattern)
        if match[0] == '/' then
            pushf(config.workspaces[config.cw]['dir'] .. match:sub(2))
        else
            pushf(vim.fn.expand("%:p:h") .. '/' .. match)
        end
        return true
    end
    return false
end
function M.create_link(mode)
    local text = vim.fn.expand('<cword>')
    local pos = vim.fn.getcurpos()
    if mode == 'v' then
        local vbegin = vim.fn.getpos("'<")
        local vend = vim.fn.getpos("'>")
        local lines = vim.fn.getline(vbegin[2], vend[2])
        if lines[1] == nil then return end
        lines[#lines] = string.sub(lines[#lines], 0, vend[3])
        lines[1] = string.sub(lines[1], vbegin[3])
        text = table.concat(lines, '\n')
    end
    local existing = false
    local line = vim.fn.getline('.')
    for fname, _ in pairs(cache) do
        local name, _ = path.nameext(path.file(fname))
        if text:find('^' .. insensitive(name) .. '$') then
            local relpath = path.rel(fname, path.dir(vim.fn.expand('%:p')))
            line = create_link(line, pos[3], text, relpath)
            existing = true
        end
    end
    if not existing then
        line = create_link(line, pos[3], text,
                           text:gsub(' ', '_'):lower() .. '.md')
    end
    vim.fn.setline('.', line)
end
function M.go_back_link() popf() end
function M.follow_or_create_link()
    if M.follow_link() == false then M.create_link() end
end

function M.workspace_enter(workspace)
    config.cw = workspace
    M.get_workspace_metadata(workspace)
    if config.workspaces[workspace].callback ~= nil then
        config.workspaces[workspace].callback()
    end

    if config.map then
        vim.api.nvim_buf_set_keymap(0, 'n', '<CR>',
                                    [[:lua require'loci.functions'.follow_or_create_link()<CR>]],
                                    {noremap = true, silent = true})
        vim.api.nvim_buf_set_keymap(0, 'v', '<CR>',
                                    [[:lua require'loci.functions'.create_link('v')<CR>]],
                                    {noremap = true, silent = true})
        vim.api.nvim_buf_set_keymap(0, 'n', '<BS>',
                                    [[:lua require'loci.functions'.go_back_link()<CR>]],
                                    {noremap = true, silent = true})
    end

    if config.link_on_save then
        local cmd = vim.api.nvim_command
        cmd([[augroup LociAutoGroup]])
        cmd([[autocmd! *]])
        cmd('autocmd BufWriteCmd ' .. config.workspaces[workspace]['dir'] ..
                '*.md lua require("loci.functions").auto_link()')
        cmd([[augroup END]])
    end
end

return M
