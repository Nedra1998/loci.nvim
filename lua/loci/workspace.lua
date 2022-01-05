local config = require("loci.config")

local M = {}

function M.open(workspace)

  if config.ws ~= nil then
    if workspace ~= nil then
      config.ws = nil
    else
      return config.ws, config.cfg.workspaces[config.ws]
    end
  end

  if workspace ~= nil and workspace:len() ~= 0 then
    local keyset = {}
    for key, _ in pairs(config.cfg.workspaces) do
      table.insert(keyset, key)
      if key:lower() == workspace:lower() then
        config.ws = key
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
      if config.ws == nil or type(val) == 'table' and val['default'] == true then
        config.ws = key
      end
    end
  end

  if config.ws ~= nil then
    return config.ws, config.cfg.workspaces[config.ws]
  else
    return nil, nil
  end
end

return M
