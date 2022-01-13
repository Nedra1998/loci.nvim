local Path = require('plenary.path')
local config = require("loci.config")
local search = require('loci.search')
local is_url = require('loci.util').is_url

local LINK_PATTERN = '%[[^]]+%]%(([^)#]*)(#?[^)]*)%)'
local M = {}

local Stack = {}

Stack.__index = Stack

function Stack:new(...)
  local args = {...}
  local size = 0
  for _, _ in ipairs(args) do size = size + 1 end
  local obj = {_values = args, _len = size}
  setmetatable(obj, Stack)
  return obj
end
function Stack:push(val)
  self._len = self._len + 1
  self._values[self._len] = val
end
function Stack:pop()
  local val = self._values[self._len]
  self._values[self._len] = nil
  if self._len > 0 then self._len = self._len - 1 end
  return val
end
function Stack:peek() return self._values[self._len] end
function Stack:len() return self._len end

local buffer_stack = Stack:new()

--- Executes extern comman to open a provided path
-- Uses `open` on MacOS, and `xdg-open` on other Unix operating systems to open
-- a provided file/URL with the system default utility.
-- @treturn bool `true`
local function follow_external(path)
  if vim.fn.has("mac") == 1 then
    vim.api.nvim_command('silent !open ' .. path .. ' &')
  elseif vim.fn.has("unix") then
    vim.api.nvim_command('silent !xdg-open ' .. path .. ' &')
  else
    vim.notify("Cannot open paths (" .. path .. ") on your operating system.")
  end
  return true
end

local function jump_to_anchor(anchor)
  -- TODO: Implement jumping to anchors/sections
end

--- Opens the provided file in a new buffer
-- Opens the provided file path in a new vim buffer. If `create_dirs` has been
-- set in the configuration it will also create all of the required directories
-- for that file.
-- It then pushes the current buffer onto the internal buffer stack.
-- @treturn bool `true`
-- @see link.go_back
local function follow_file(path)
  buffer_stack:push(vim.api.nvim_win_get_buf(0))
  ext = vim.fn.fnamemodify(path, ':e')
  if ext == nil or ext:len() == 0 then path = path .. '.md' end

  if path[1] ~= '/' and path[1] ~= '~' then
    local dir = Path:new(vim.api.nvim_buf_get_name(0)):parent()
    path = dir:joinpath(path):expand()
  else
    path = Path:new(path):expand()
  end

  local fullpath = Path:new(path)
  if config.cfg.create_dirs then
    local dir = fullpath:parent()
    if not dir:exists() then dir:mkdir({parents = true}) end
  end

  vim.api.nvim_command("edit " .. fullpath:absolute())
  return true
end

--- Extracts the path and anchor component of a markdown link.
-- Scans the current line and the line above and below for a markdown link that
-- the cursor is currently over. If a markdown link exists, then it returns the
-- path component of that link, otherwise it returns nil.
-- @treturn[1] ?string The path compoenent of the markdown link.
-- @treturn[2] ?string The anchor compoenent of the markdown link.
local function get_path()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2] + 1

  local lines = vim.api.nvim_buf_get_lines(0, math.max(0, row - 1), row + 2,
                                           false)
  if row ~= 0 then
    pos = lines[1]:len() + 1 + col
  else
    pos = col
  end

  local text = table.concat(lines, ' ')
  local mbegin, mend = 0, 0

  repeat
    mbegin, mend = text:find(LINK_PATTERN, mend)
    if mbegin ~= nil and mend ~= nil and mbegin <= pos and mend >= pos then
      return text:sub(mbegin, mend):match(LINK_PATTERN)
    end
  until mbegin == nil or mend == nil
  return nil
end

--- Replaces the current selected text with a new markdown link.
-- In Normal mode, the selected text is the current word under the cursor,
-- otherwise in visual mode it is the visual selection. The selected text is
-- escaped and used as the link target destination, with an appended filetype
-- '.md'.
-- @tparam ?string The current vim mode, expects either `n` or `v`.
function M.create(mode)
  local mode = mode or vim.api.nvim_get_mode()['mode']
  local vbegin, vend = nil, nil

  if mode == 'n' then
    local pos = vim.api.nvim_win_get_cursor(0)
    local select = vim.fn.expand("<cword>")
    local line = table.concat(vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1],
                                                         false), ' ')
    repeat vbegin, vend = line:find(select, vend or 0) until vbegin == nil or
        vend == nil or (pos[2] + 1 >= vbegin and pos[2] + 1 <= vend)
    if vbegin == nil or vend == nil then return false end
    vbegin, vend = {pos[1], vbegin}, {pos[1], vend}
  elseif mode == 'v' then
    vbegin, vend = vim.fn.getpos("'<"), vim.fn.getpos("'>")
    vbegin, vend = {vbegin[2], vbegin[3]}, {vend[2], vend[3]}
  end

  local lines = vim.api.nvim_buf_get_lines(0, vbegin[1] - 1, vend[1], false)
  local text = table.concat(lines, ' ')

  local offset = 0
  for _, line in ipairs(lines) do offset = offset + line:len() + 1 end
  offset = offset - lines[#lines]:len() - 1

  local dest = search.title(nil, text:sub(vbegin[2], vend[2] + offset))
  if dest then
    dest = Path:new(dest):make_relative(vim.fn.expand("%:p:h"))
  else
    dest = text:sub(vbegin[2], vend[2] + offset):gsub('[%p%c]', ''):gsub('%s',
                                                                         '_')
               :lower() .. '.md'
  end

  lines[#lines] = lines[#lines]:sub(1, vend[2]) .. '](' .. dest .. ')'
  lines[1] = '[' .. lines[1]:sub(vbegin[2])

  vim.api.nvim_buf_set_text(0, vbegin[1] - 1, vbegin[2] - 1, vend[1] - 1,
                            vend[2], lines)
end

--- Attempts to follow a markdown link under the cursor.
-- If a markdown link exists under the current cursor position, then that link
-- is opened (in a new buffer or by the system default application).
-- @see get_path
-- @see jump_to_anchor
-- @see follow_external
-- @see follow_file
-- @treturn bool `true` if the link exists, and was able to be followed,
-- otherwise `false`.
function M.follow()
  local path, anchor = get_path()
  if path == nil then return false end

  if is_url(path) then
    if anchor ~= nil then path = path .. anchor end
    return
        follow_external(vim.fn.shellescape(path):gsub("[#]", {["#"] = "\\#"}))
  else
    if path:len() ~= 0 and not follow_file(path) then return false end
    if anchor ~= nil and anchor:len() ~= 0 and not jump_to_anchor(anchor) then
      return true
    end
  end

  return true
end

--- Attempts to follow a link if it exists, otherwise it creates a new link.
-- @see link.follow
-- @see link.create
function M.follow_or_create(mode)
  if not M.follow() then
    return M.create(mode)
  else
    return true
  end
end

--- Returns to previous buffer in the buffer stack.
-- Pops the top item from the internal buffer stack, and returns to the previous
-- buffer. Essentially reversing the @{follow_file} function.
-- @see follow_file
function M.go_back()
  local bufnr = vim.api.nvim_win_get_buf(0)
  if bufnr > 1 then
    local prev = buffer_stack:pop()
    if prev ~= nil then vim.api.nvim_command('buffer ' .. prev) end
  end
end

return M
