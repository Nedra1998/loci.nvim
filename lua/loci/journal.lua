local Path = require('plenary.path')
local config = require("loci.config")
local workspace = require('loci.workspace')

local M = {}

--- Parse a journal configuration.
-- This function parsers the configuration and construct a table representing
-- the data in the config or default values.
-- @param key The string index for the journal configuration in the config.
-- @param cfg the table/string configuration value from the config.
-- @returns A table containing the key, path to the journal directory, and the
-- method/type of journal that has been configured.
local function journal_parse_config(key, cfg)
  local path, method = nil, nil
  if type(cfg) == 'table' then
    if cfg['path'] ~= nil then
      path = cfg['path']
    else
      path = key:lower()
    end
    method = cfg['type']
  else
    path = key:lower()
    method = cfg
  end
  return {key = key, path = path, method = method}
end

--- Opens a journal note file in a new buffer.
-- If `create_dirs` is set in the configuration, it will also create any
-- required directories.
-- @param ws A table containing the workspace name as `key`, and the workspace
-- path as `path`.
-- @param jnl A table containing the journal name as `key`, the journal path as
-- `path`, and the journal method as `method`.
-- @param time A UNIX timestamp representing a date/time to open the journal
-- entry for. The value of `jnl.method` will specify the formatting for the
-- filename.
local function journal_open_note(ws, jnl, time)
  local fname = nil
  if jnl.method == nil or jnl.method:lower() == 'daily' then
    fname = os.date("%Y-%m-%d", time)
  elseif jnl.method:lower() == 'weekly' then
    fname = os.date("%Y-W%V", time)
  elseif jnl.method:lower() == 'monthly' then
    fname = os.date("%Y-M%m", time)
  elseif jnl.method:lower() == 'quarterly' then
    local month = tonumber(os.date("%m", time))
    if month >= 1 and month <= 3 then
      fname = os.date("%Y-Q1", time)
    elseif month >= 4 and month <= 6 then
      fname = os.date("%Y-Q2", time)
    elseif month >= 7 and month <= 9 then
      fname = os.date("%Y-Q3", time)
    elseif month >= 10 and month <= 12 then
      fname = os.date("%Y-Q4", time)
    end
  elseif jnl.method:lower() == 'yearly' then
    fname = os.date("%Y", time)
  end

  if fname == nil then
    vim.notify("Loci journal \"" .. ws.key .. "." .. jnl.key ..
                   "\" has an unrecognized type, possible types include { \"daily\", \"weekly\", \"monthly\", \"quarterly\", \"yearly\" }",
               'warning')
    return
  end

  local fullpath =
      Path:new(Path:new(ws.path, jnl.path, fname .. '.md'):expand())

  if config.cfg.create_dirs then
    local dir = fullpath:parent()
    if not dir:exists() then dir:mkdir({parents = true}) end
  end

  vim.api.nvim_command('edit ' .. fullpath:absolute())
end

--- Loads a journal configuration
-- @param ws_key The name of a workspace to search for, if empty or nil then the
-- default workspace will be used.
-- @param journal The name of a journal in the workspace to load, if empty or
-- nil then the default journal will be used.
-- @return The workspace configuration returned by workspace.open, or nil of no
-- workspace found.
-- @return The journal key in the workspace configuration, or nil if no journal
-- was found.
-- @return The journal configuration, or nil if no journal was found.
-- @see workspace.open
function M.open(ws_key, journal)
  if ws_key ~= nil and journal == nil then
    journal = ws_key
    ws_key = nil
  end
  local ws_name, ws = workspace.open(ws_key)
  if ws_name == nil or ws == nil then
    return nil, nil, nil
  elseif ws.journals == nil then
    vim.notify("Loci workspace \"" .. ws_name ..
                   "\" does not have any journals configured.", 'warning')
    return nil, nil, nil
  end

  jkey = nil

  if journal ~= nil and journal:len() ~= 0 then
    local keyset = {}
    for key, _ in pairs(ws.journals) do
      table.insert(keyset, key)
      if key:lower() == journal:lower() then
        jkey = key
        break
      end
    end
    if jkey == nil then
      vim.notify("No Loci journals with the name \"" .. journal ..
                     "\" exist in the workspace \"" .. ws_name ..
                     "\", possible journals include " .. vim.inspect(keyset) ..
                     ".", 'warning')
    end
  else
    for key, val in pairs(ws.journals) do
      if jkey == nil or type(val) == "table" and val['default'] == true then
        jkey = key
      end
    end
  end

  if jkey ~= nil then
    return ws, jkey, ws.journals[jkey]
  else
    return nil, nil, nil
  end
end

--- Opens the previous entry in a selected journal
-- Opens the previous entry in the selected/default journal, this takes into
-- account the type of journal that is used, and will adjust the times
-- accordingly.
-- @param ws_key The name of a workspace to search for, if empty or nil then the
-- default workspace will be used.
-- @param journal The name of a journal in the workspace to load, if empty or
-- nil then the default journal will be used.
-- @see journal.open
-- @see journal_open_note
function M.previous(ws_name, journal)
  local ws, jnl, cfg = M.open(ws_name, journal)
  if ws == nil or jnl == nil or cfg == nil then return end

  local jnl_cfg = journal_parse_config(jnl, cfg)
  local time = os.time()

  if jnl_cfg.method:lower() == "daily" then
    time = time - (24 * 60 * 60)
  elseif jnl_cfg.method:lower() == "weekly" then
    time = time - (7 * 24 * 60 * 60)
  elseif jnl_cfg.method:lower() == "monthly" then
    time = time - (30 * 24 * 60 * 60)
  elseif jnl_cfg.method:lower() == "quarterly" then
    time = time - (3 * 30 * 24 * 60 * 60)
  elseif jnl_cfg.method:lower() == "yearly" then
    time = time - (365 * 24 * 60 * 60)
  end

  return journal_open_note({key = ws_name, path = ws.path}, jnl_cfg, time)
end

--- Opens the current entry in a selected journal
-- Opens the current entry in the selected/default journal.
-- @param ws_key The name of a workspace to search for, if empty or nil then the
-- default workspace will be used.
-- @param journal The name of a journal in the workspace to load, if empty or
-- nil then the default journal will be used.
-- @see journal.open
-- @see journal_open_note
function M.current(ws_name, journal)
  local ws, jnl, cfg = M.open(ws_name, journal)
  if ws == nil or jnl == nil or cfg == nil then return end

  local time = os.time()
  return journal_open_note({key = ws_name, path = ws.path},
                           journal_parse_config(jnl, cfg), time)
end

--- Opens the next entry in a selected journal
-- Opens the next entry in the selected/default journal, this takes into
-- account the type of journal that is used, and will adjust the times
-- accordingly.
-- @param ws_key The name of a workspace to search for, if empty or nil then the
-- default workspace will be used.
-- @param journal The name of a journal in the workspace to load, if empty or
-- nil then the default journal will be used.
-- @see journal.open
-- @see journal_open_note
function M.next(ws_name, journal)
  local ws, jnl, cfg = M.open(ws_name, journal)
  if ws == nil or jnl == nil or cfg == nil then return end

  local jnl_cfg = journal_parse_config(jnl, cfg)
  local time = os.time()

  if jnl_cfg.method:lower() == "daily" then
    time = time + (24 * 60 * 60)
  elseif jnl_cfg.method:lower() == "weekly" then
    time = time + (7 * 24 * 60 * 60)
  elseif jnl_cfg.method:lower() == "monthly" then
    time = time + (30 * 24 * 60 * 60)
  elseif jnl_cfg.method:lower() == "quarterly" then
    time = time + (3 * 30 * 24 * 60 * 60)
  elseif jnl_cfg.method:lower() == "yearly" then
    time = time + (365 * 24 * 60 * 60)
  end

  return journal_open_note({key = ws_name, path = ws.path}, jnl_cfg, time)
end

--- Opens the journal entry in a selected journal for a given date
-- Opens the journal entry for a specified date
-- @param ws_key The name of a workspace to search for, if empty or nil then the
-- default workspace will be used.
-- @param journal The name of a journal in the workspace to load, if empty or
-- nil then the default journal will be used.
-- @param date A date string of the format `YYYY-MM-DD` or nil to use the
-- current date.
-- @see journal.open
-- @see journal_open_note
function M.date(ws_name, journal, date)
  if ws_name ~= nil and journal == nil and date == nil then
    date = ws_name
    journal = nil
    ws_name = nil
  elseif ws_name ~= nil and journal ~= nil and date == nil then
    date = journal
    journal = ws_name
    ws_name = nil
  end
  local ws, jnl, cfg = M.open(ws_name, journal)
  if ws == nil or jnl == nil or cfg == nil then return end

  local jnl_cfg = journal_parse_config(jnl, cfg)

  local time = os.time()
  if date ~= nil then
    local y, m, d = date:match("(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)$")
    if y == nil or m == nil or d == nil then
      vim.notify(
          "loci.journal.date only accepts dates of the format YYYY-MM-DD currently.")
      return
    end
    time = os.time({year = y, month = m, day = d, hour = 12})
  end

  return journal_open_note({key = ws_name, path = ws.path}, jnl_cfg, time)
end

return M
