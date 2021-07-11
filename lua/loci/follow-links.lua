local fn = vim.fn
local api = vim.api
local ts_utils = require('nvim-treesitter.ts_utils')

local configuration = require('loci.config')

local M = {}

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
    if configuration.current_workspace ~= nil then
      return fn.fnamemodify(
                 configuration.workspaces[configuration.current_workspace].path,
                 ":p") .. [[/]] .. link
    else
      return link
    end
  else
    return fn.expand("%:p:h") .. [[/]] .. link
  end
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function get_link_catagory(link)
  local ext = fn.fnamemodify(link, ':e')
  if string.sub(link, 1, 4) == "http" then
    return 'url'
  else
    for cat, arr in pairs(configuration.filetypes) do
      if has_value(arr, ext) then
        return cat
      end
    end
  end
end

function M.follow_link()
  local link = get_link()
  if link then
    link = resolve_link(link)
    local cat = get_link_catagory(link)
    if cat ~= nil then
      fn.system(configuration.launcher .. ' ' .. link .. ' &')
    else
      local dir = fn.fnamemodify(link, ':h')
      if fn.isdirectory(dir) == 0 then fn.mkdir(dir, 'p') end
      api.nvim_command('edit ' .. link)
    end
  end
end

return M
