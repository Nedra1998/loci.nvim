local config = require("loci.config")
local workspace = require('loci.workspace')

local M = {}

--- Opens a journal note file in a new buffer.
-- If `create_dirs` is set in the configuration, it will also create any
-- required directories.
-- @param ws A table containing the workspace name as `key`, and the workspace
-- path as `path`.
-- @param jnl A table containing the journal name as `key`, the journal path as
-- `path`, and the journal recurrence as `recurrence`.
-- @param time A UNIX timestamp representing a date/time to open the journal
-- entry for. The value of `jnl.recurrence` will specify the formatting for the
-- filename.
local function journal_open_note(cfg, time)
  local fname = nil
  if cfg.recurrence == nil or cfg.recurrence:lower() == 'daily' then
    fname = os.date("%Y-%m-%d", time)
  elseif cfg.recurrence:lower() == 'weekly' then
    fname = os.date("%Y-W%V", time)
  elseif cfg.recurrence:lower() == 'monthly' then
    fname = os.date("%Y-M%m", time)
  elseif cfg.recurrence:lower() == 'quarterly' then
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
  elseif cfg.recurrence:lower() == 'yearly' then
    fname = os.date("%Y", time)
  end

  if fname == nil then
    vim.notify("Loci journal " .. cfg.key .. " has an unrecognized type \"" ..
                   cfg.recurrence ..
                   "\", possible types include { \"daily\", \"weekly\", \"monthly\", \"quarterly\", \"yearly\" }",
               'warning')
    return
  end

  local fullpath = cfg.path .. '/' .. fname .. '.md'

  if config.cfg.create_dirs then
    vim.fn.mkdir(vim.fn.fnamemodify(fullpath, ":h"), "p")
  end

  vim.api.nvim_command('edit ' .. fullpath)
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
function M.open(wkey, jkey)
  if wkey ~= nil and jkey == nil then
    jkey = wkey
    wkey = nil
  end
  local ws = workspace.open(wkey)
  if ws == nil then
    return nil
  elseif ws.journals == nil then
    vim.notify("Loci workspace \"" .. ws.key ..
                   "\" does not have any journals configured.", 'warning')
    return nil
  end

  local journal = nil

  if jkey ~= nil and jkey:len() ~= 0 then
    local keyset = {}
    for key, value in pairs(ws.journals) do
      table.insert(keyset, key)
      if key:lower() == jkey:lower() then
        journal = vim.tbl_extend('force', value, {key = key})
        break
      end
    end
    if journal == nil then
      vim.notify("No Loci journals with the name \"" .. jkey ..
                     "\" exist in the workspace \"" .. ws.key ..
                     "\", possible journals include " .. vim.inspect(keyset) ..
                     ".", 'warning')
    end
  else
    for key, val in pairs(ws.journals) do
      if journal == nil and val['default'] == true then
        journal = vim.tbl_extend('force', val, {key = key})
        break
      end
    end
  end

  return journal
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
function M.previous(wkey, jkey)
  local cfg = M.open(wkey, jkey)
  if cfg == nil then return end

  local time = os.time()

  if cfg.recurrence:lower() == "daily" then
    time = time - (24 * 60 * 60)
  elseif cfg.recurrence:lower() == "weekly" then
    time = time - (7 * 24 * 60 * 60)
  elseif cfg.recurrence:lower() == "monthly" then
    time = time - (30 * 24 * 60 * 60)
  elseif cfg.recurrence:lower() == "quarterly" then
    time = time - (3 * 30 * 24 * 60 * 60)
  elseif cfg.recurrence:lower() == "yearly" then
    time = time - (365 * 24 * 60 * 60)
  end

  return journal_open_note(cfg, time)
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
  local cfg = M.open(ws_name, journal)
  if cfg == nil then return end

  local time = os.time()
  return journal_open_note(cfg, time)
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
  local cfg = M.open(ws_name, journal)
  if cfg == nil then return end

  local time = os.time()

  if cfg.recurrence:lower() == "daily" then
    time = time + (24 * 60 * 60)
  elseif cfg.recurrence:lower() == "weekly" then
    time = time + (7 * 24 * 60 * 60)
  elseif cfg.recurrence:lower() == "monthly" then
    time = time + (30 * 24 * 60 * 60)
  elseif cfg.recurrence:lower() == "quarterly" then
    time = time + (3 * 30 * 24 * 60 * 60)
  elseif cfg.recurrence:lower() == "yearly" then
    time = time + (365 * 24 * 60 * 60)
  end

  return journal_open_note(cfg, time)
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
function M.date(wkey, jkey, date)
  if wkey ~= nil and jkey == nil and date == nil then
    date = wkey
    jkey = nil
    wkey = nil
  elseif wkey ~= nil and jkey ~= nil and date == nil then
    date = jkey
    jkey = wkey
    wkey = nil
  end
  local cfg = M.open(wkey, jkey)
  if cfg == nil then return end

  local time = os.time()
  if date ~= nil then
    local y, m, d = date:match("^(%d%d%d%d)[-/ ](%d?%d)[-/ ](%d?%d)$")
    if y ~= nil and m ~= nil and d ~= nil then
      time = os.time({year = y, month = m, day = d, hour = 12})
    else
      vim.notify(
          "loci.journal.date only accepts dates of the format YYYY-MM-DD currently.")
      return
    end
  end

  return journal_open_note(cfg, time)
end

return M
