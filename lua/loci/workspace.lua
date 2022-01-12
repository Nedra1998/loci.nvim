local config = require("loci.config")

local M = {}

--- Loads a workspace configuration
-- @param workspace The name of a workspace to search for, if empty or nil then the
-- default workspace will be used.
-- @return The workspace key in the configuration, or nil if no workspace
-- was found.
-- @return The workspace configuration, or nil if no workspace was found.
function M.open(workspace)

  if config.ws ~= nil then
    if workspace ~= nil and workspace ~= config.ws.key then
      config.ws = nil
    else
      return config.ws
    end
  end

  if workspace ~= nil and workspace:len() ~= 0 then
    local keyset = {}
    for key, value in pairs(config.cfg.workspaces) do
      table.insert(keyset, key)
      if key:lower() == workspace:lower() then
        config.ws = vim.tbl_extend('force', value, {key = key})
        break
      end
    end
    if config.ws == nil then
      vim.notify("No Loci workspace with the name \"" .. workspace ..
                     "\", possible workspaces include " .. vim.inspect(keyset) ..
                     ".", 'warning')
    end
  else
    for key, val in pairs(config.cfg.workspaces) do
      if config.ws == nil and val['default'] == true then
        config.ws = vim.tbl_extend('force', val, {key = key})
        break
      end
    end
  end

  if config.ws ~= nil then
    vim.notify("Loaded workspace " .. config.ws.key, 'info')
  end

  return config.ws
end

return M
