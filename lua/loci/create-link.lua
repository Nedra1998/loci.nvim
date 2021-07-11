local fn = vim.fn

local M = {}

function M.create_link(mode)
  mode = mode or 'n'
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
  elseif mode == 'v' then
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
end
