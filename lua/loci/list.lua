local filetype = require('plenary.filetype')
local Path = require('plenary.path')
local M = {}

local BASENAME_PATTERN = '([^/]+)%.[^/%.]+$'
local MARKDOWN_PATTERN = '%[[^]]+%]%(([^)]+)%)'

local function get_markdown_header(file, max)
    max = max or 3
    local lines = vim.fn.readfile(file)
    for i, l in ipairs(lines) do
        if i > max then return nil end
        if l:find('^#%s+(.*)') then return l:match('^#%s+(.*)') end
    end
    return nil
end

-- Get document title from file path. If the file is a markdown file, it will
-- read the file for the top header as the title, otherwise it will return the
-- file name.
-- @param file The absolute path for the file to process.
local function get_title(file)
    if filetype.detect(file) == 'markdown' then
        local title = get_markdown_header(file)
        if title == nil then title = file:match(BASENAME_PATTERN) end
        return title
    else
        return file:match(BASENAME_PATTERN)
    end
end

local function get_markdown_links(lines)
    local links = {}
    for i, l in ipairs(lines) do
        local mstart, mend = 0, 0
        repeat
            mstart, mend = l:find(MARKDOWN_PATTERN, mend)
            if mend ~= nil then
                local match = l:sub(mstart, mend)
                links[match:match(MARKDOWN_PATTERN)] = i
            end
        until mstart == nil or mend == nil
    end
    return links
end

function M.get_links(file, buffer, ft)
    local links = {}
    ft = ft or filetype.detect(file)
    if ft == 'markdown' then
        links = get_markdown_links(buffer or vim.fn.readfile(file))
    end

    local current_path = Path:new(Path:new(file):parent())
    local processed_links = {}
    for key, value in pairs(links) do
        processed_links[#processed_links + 1] =
            {
                src_file = file,
                dest_file = current_path:joinpath(key):absolute(),
                src_line = value
            }
    end
    return processed_links
end

-- List all documents in a given directory.
-- @param root The rood directory to search for documents in
function M.list_documents(root)
    local documents = {}
    local md_files = vim.fn.globpath(Path:new(root):expand(), '**/*.md', false,
                                     true)
    for _, file in ipairs(md_files) do
        documents[#documents + 1] = {path = file, title = get_title(file)}
    end

    local pdf_files = vim.fn.globpath(Path:new(root):expand(), '**/*.pdf',
                                      false, true)
    for _, file in ipairs(pdf_files) do
        documents[#documents + 1] = {path = file, title = get_title(file)}
    end
    return documents
end

-- List all links from the current document to all other valid documents in the
-- given workspace.
-- @param file Current document file path
-- @param root Workspace root directory
-- @param documents Optional set of documents to search (defaults to all in
-- workspace)
function M.list_forward_links(file, root, documents)
    file = Path:new(file):expand()
    root = Path:new(root):expand()
    documents = documents or M.list_documents(root)
    local title = get_title(file)
    local valid_links = {}
    for _, link in ipairs(M.get_links(file)) do
        for _, doc in ipairs(documents) do
            if doc.path == file then
            elseif doc.path == link.dest_file then
                valid_links[#valid_links + 1] =
                    {
                        src_file = link.src_file,
                        src_title = title,
                        src_line = link.src_line,
                        dest_file = link.dest_file,
                        dest_title = doc.title
                    }
            end
        end
    end
    return valid_links
end

-- List all links to this current document, searching all documents in a given
-- workspace.
-- @param file File to search fo links to.
-- @param root The root directory of the workspace to search.
-- @param documents Optional set of documents to search, defaults to all of
-- workspace
function M.list_backward_links(file, root, documents)
    file = Path:new(file):expand()
    root = Path:new(root):expand()
    documents = documents or M.list_documents(root)
    local title = get_title(file)
    local valid_links = {}
    for _, doc in ipairs(documents) do
        local forelinks = M.list_forward_links(doc.path, root,
                                               {{path = file, title = title}})
        for _, link in ipairs(forelinks) do
            valid_links[#valid_links + 1] = link
        end
    end
    return valid_links
end
return M
