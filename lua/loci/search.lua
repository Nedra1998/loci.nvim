local workspace = require('loci.workspace')
local journal = require('loci.journal')
local is_url = require('loci.util').is_url

local LINK_PATTERN = '%[[^]]+%]%(([^)#]*)(#?[^)]*)%)'

local M = {}

local cache = {}

local function build_file_link_cache(path)
  local stat = vim.loop.fs_stat(path)

  if cache[path] ~= nil and cache[path].time >= stat.mtime.sec then return end
  local file = io.open(path, 'r')
  local content = ""
  if file then
    content = file:read("*a")
    file:close()
  end

  local dir = vim.fn.fnamemodify(path, ":h")

  local entry = {
    time = os.time(),
    title = vim.fn.fnamemodify(path, ':t:r'),
    links = {}
  }

  local heading = nil
  local title = nil

  local header = false
  local count = 0
  for line in content:gmatch("([^\n]+)") do
    if line:find('^---$') then header = header and false or true end

    if header then
      local t = line:match('^title: (.*)$')
      if t and not title then title = t end
    else
      local h = line:match('^# (.*)$')
      if h and not heading then heading = h end
    end

    count = count + 1
    if count > 10 then break end
  end

  if title then
    entry.title = title
  elseif heading then
    entry.title = heading
  end

  local mbegin, mend = 0, 0
  repeat
    mbegin, mend = content:find(LINK_PATTERN, mend)
    if mbegin ~= nil and mend ~= nil then
      local l, _ = content:sub(mbegin, mend):match(LINK_PATTERN)

      if not is_url(l) then
        local dest = vim.fn.fnamemodify(dir .. '/' .. l, ':p')
        entry.links[dest] = true
      end
    end
  until mbegin == nil or mend == nil

  cache[path] = entry
end

local function build_link_cache(wkey)
  local files = M.notes(wkey)

  for _, f in ipairs(files) do build_file_link_cache(f) end
end

function M.notes(wkey)
  local ws = workspace.open(wkey)
  if ws == nil then return {} end
  local file_list = vim.fn.globpath(ws.path, "**/*.md", 0, 1)
  return file_list
end

function M.journal(wkey, jkey)
  if wkey ~= nil and jkey == nil then
    jkey = wkey
    wkey = nil
  end
  local jnl = journal.open(wkey, jkey)
  if jnl == nil then return {} end
  local file_list = vim.fn.globpath(jnl.path, "**/*.md", 0, 1)
  return file_list
end

function M.links(path)
  if path == nil then path = vim.fn.expand("%:p") end
  build_file_link_cache(path)

  local links = {}
  if not cache[path] then return {} end
  for k, _ in pairs(cache[path].links) do table.insert(links, k) end

  return links
end

function M.backlinks(wkey, path)
  if path == nil then path = vim.fn.expand("%:p") end
  build_link_cache(wkey)

  local links = {}
  for s, v in pairs(cache) do if v.links[path] then table.insert(links, s) end end

  return links
end

function M.title(wkey, title)
  build_link_cache(wkey)
  title = title:lower():gsub('[%p%c%s]', '')

  for f, v in pairs(cache) do
    if v.title:lower():gsub('[%p%c%s]', '') == title then return f end
  end

  return nil
end

return M
