local api = vim.api
local fn = vim.fn
local config = require('loci.config')

local M = {}

function M.open_diary_index(workspace, diary)
  workspace = workspace or config.current_workspace
  if workspace == nil then
    for k, v in pairs(config.workspaces) do workspace = k end
  elseif config.workspaces[workspace] == nil then
    return nil
  end
  diary = diary or config.workspaces[workspace].diaries[1]
  if diary == nil then return nil end

  local dir = fn.expand(config.workspaces[workspace].path) .. '/' .. diary

  if fn.isdirectory(dir) == 0 then fn.mkdir(dir, 'p') end
  api.nvim_command('edit ' .. dir .. '/' .. diary .. '.md')
end

function M.open_diary(workspace, diary, date)
  workspace = workspace or config.current_workspace
  if workspace == nil then
    for k, v in pairs(config.workspaces) do workspace = k end
  elseif config.workspaces[workspace] == nil then
    return nil
  end
  diary = diary or config.workspaces[workspace].diaries[1]
  if diary == nil then return nil end

  local dir = fn.expand(config.workspaces[workspace].path) .. '/' .. diary
  if fn.isdirectory(dir) == 0 then fn.mkdir(dir, 'p') end

  if date == nil or date == 'today' then
    api.nvim_command('edit ' .. dir .. '/' .. os.date("%Y-%m-%d") .. '.md')
  elseif date == 'yesterday' then
    api.nvim_command('edit ' .. dir .. '/' ..
                         os.date("%Y-%m-%d", os.time() - 86400) .. '.md')
  elseif date == 'tomorrow' then
    api.nvim_command('edit ' .. dir .. '/' ..
                         os.date("%Y-%m-%d", os.time() + 86400) .. '.md')
  elseif date:find("%d%d%d%d-%d%d-%d%d") then
    api.nvim_command('edit ' .. dir .. '/' .. date .. '.md')
  end
end

local MONTHS = {
  ['01'] = 'January',
  ['02'] = 'Feburary',
  ['03'] = 'March',
  ['04'] = 'April',
  ['05'] = 'May',
  ['06'] = 'June',
  ['07'] = 'July',
  ['08'] = 'August',
  ['09'] = 'September',
  ['10'] = 'October',
  ['11'] = 'November',
  ['12'] = 'December'
}

function M.generate_diary_index(workspace, diary)
  workspace = workspace or config.current_workspace
  if workspace == nil then
    for k, v in pairs(config.workspaces) do workspace = k end
  elseif config.workspaces[workspace] == nil then
    return nil
  end
  diary = diary or config.workspaces[workspace].diaries[1]
  if diary == nil then return nil end

  local dir = fn.expand(config.workspaces[workspace].path) .. '/' .. diary
  if fn.isdirectory(dir) == 0 then fn.mkdir(dir, 'p') end
  local path = dir .. '/' .. diary .. '.md'

  local files = fn.globpath(dir, '*.md', false, true)
  table.sort(files, function(a, b) return a > b end)

  local lines = {"# " .. diary:gsub("^%l", string.upper), "", ":private:"}
  local year, month = "0000", "00"

  for _, file in ipairs(files) do
    local fname = fn.fnamemodify(file, ":t:r")
    if fname:find("%d%d%d%d%-%d%d%-%d%d") ~= nil then
      local fyear, fmonth = fname:sub(1, 4), fname:sub(6, 7)
      if year ~= fyear then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "## " .. fyear
        lines[#lines + 1] = ""
        lines[#lines + 1] = "### " .. MONTHS[fmonth]
        lines[#lines + 1] = ""
        year, month = fyear, fmonth
      elseif month ~= fmonth then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "### " .. MONTHS[fmonth]
        lines[#lines + 1] = ""
        month = fmonth
      end
      lines[#lines + 1] = "- [" .. fname .. "](" .. fname .. ".md)"
    end
  end

  fn.writefile(lines, path)
  if fn.expand("%:p") == path then
    api.nvim_command('edit reload')
  end
end

return M
