local fn = vim.fn
local api = vim.api
local ts_utils = require('nvim-treesitter.ts_utils')
local parsers = require('nvim-treesitter.parsers')

local config = require('loci.config')

local M = {}

function M.create_link(mode)
  local mode = mode or fn.mode()
  local vbegin, vend = nil, nil
  local line, lineno = nil, nil

  if mode == 'n' then
    local pos = fn.getcurpos()
    line = fn.getline(pos[2])
    lineno = pos[2]
    local select = fn.expand('<cword>')
    vend = 0
    repeat vbegin, vend = line:find(select, vend) until vbegin == nil or vend ==
        nil or (pos[3] >= vbegin and pos[3] <= vend)
    if vbegin == nil or vend == nil then return nil end
  elseif mode == 'v' or mode == 'V' then
    vbegin, vend = fn.getpos("'<"), fn.getpos("'>")
    line = fn.getline(vbegin[2])
    lineno = vbegin[2]
    vbegin, vend = vbegin[3], vend[3]
  else
    return nil
  end

  dest = line:sub(vbegin, vend):gsub('[%p%c]', ''):gsub('%s', '_'):lower() ..
             '.md'

  line = line:sub(0, vbegin - 1) .. '[' .. line:sub(vbegin, vend) .. '](' ..
             dest .. ')' .. line:sub(vend + 1)

  fn.setline(lineno, line)
  if not parsers.has_parser() then
    return
  else
    parsers.get_parser():parse()
  end
end

local function get_link()
  local node_at_cursor = ts_utils.get_node_at_cursor()
  local parent_node = node_at_cursor:parent()
  if not node_at_cursor or not parent_node then
    return
  elseif parent_node:type() == 'link_destination' then
    return ts_utils.get_node_text(node_at_cursor, 0)[1]
  elseif parent_node:type() == 'link_text' then
    return ts_utils.get_node_text(ts_utils.get_next_node(parent_node), 0)[1]
  elseif node_at_cursor:type() == 'link' then
    local child_nodes = ts_utils.get_named_children(node_at_cursor)
    for k, v in pairs(child_nodes) do
      if v:type() == 'link_destination' then
        return ts_utils.get_node_text(v)[1]
      end
    end
  else
    return
  end
end

local function resolve_link(link)
  if string.sub(link, 1, 1) == [[/]] then
    if config.current_workspace ~= nil then
      return fn.fnamemodify(config.workspaces[config.current_workspace].path,
                            ":p") .. [[/]] .. link
    else
      return link
    end
  else
    return fn.expand("%:p:h") .. [[/]] .. link
  end
end

local function has_value(tab, val)
  for index, value in ipairs(tab) do if value == val then return true end end

  return false
end

local function get_link_catagory(link)
  local ext = fn.fnamemodify(link, ':e')
  if string.sub(link, 1, 4) == "http" then
    return 'url'
  else
    for cat, arr in pairs(config.filetypes) do
      if has_value(arr, ext) then return cat end
    end
  end
end

function M.follow_link()
  local link = get_link()
  if link then
    link = resolve_link(link)
    local cat = get_link_catagory(link)
    if cat ~= nil then
      fn.system(config.launcher .. ' ' .. link .. ' &')
    else
      local dir = fn.fnamemodify(link, ':h')
      if fn.isdirectory(dir) == 0 then fn.mkdir(dir, 'p') end
      api.nvim_command('edit ' .. link)
    end
  end
end

function M.follow_or_create()
  local link = get_link()
  if link then
    link = resolve_link(link)
    local cat = get_link_catagory(link)
    if cat ~= nil then
      fn.system(config.launcher .. ' ' .. link .. ' &')
    else
      local dir = fn.fnamemodify(link, ':h')
      if fn.isdirectory(dir) == 0 then fn.mkdir(dir, 'p') end
      api.nvim_command('edit ' .. link)
    end
  else
    M.create_link()
  end
end

return M
