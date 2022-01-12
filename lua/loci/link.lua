local Path = require('plenary.path')
local config = require("loci.config")

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

--- Check if string is a URL
-- @tparam string string The string to check.
-- @treturn bool `true` if the string does represent a URL else `false`.
local function is_url(string)
  -- Table of top-level domains
  local tlds = {
    ac = true,
    ad = true,
    ae = true,
    aero = true,
    af = true,
    ag = true,
    ai = true,
    al = true,
    am = true,
    an = true,
    ao = true,
    aq = true,
    ar = true,
    arpa = true,
    as = true,
    asia = true,
    at = true,
    au = true,
    aw = true,
    ax = true,
    az = true,
    ba = true,
    bb = true,
    bd = true,
    be = true,
    bf = true,
    bg = true,
    bh = true,
    bi = true,
    biz = true,
    bj = true,
    bm = true,
    bn = true,
    bo = true,
    br = true,
    bs = true,
    bt = true,
    bv = true,
    bw = true,
    by = true,
    bz = true,
    ca = true,
    cat = true,
    cc = true,
    cd = true,
    cf = true,
    cg = true,
    ch = true,
    ci = true,
    ck = true,
    cl = true,
    cm = true,
    cn = true,
    co = true,
    com = true,
    coop = true,
    cr = true,
    cs = true,
    cu = true,
    cv = true,
    cx = true,
    cy = true,
    cz = true,
    dd = true,
    de = true,
    dj = true,
    dk = true,
    dm = true,
    ['do'] = true,
    dz = true,
    ec = true,
    edu = true,
    ee = true,
    eg = true,
    eh = true,
    er = true,
    es = true,
    et = true,
    eu = true,
    fi = true,
    firm = true,
    fj = true,
    fk = true,
    fm = true,
    fo = true,
    fr = true,
    fx = true,
    ga = true,
    gb = true,
    gd = true,
    ge = true,
    gf = true,
    gh = true,
    gi = true,
    gl = true,
    gm = true,
    gn = true,
    gov = true,
    gp = true,
    gq = true,
    gr = true,
    gs = true,
    gt = true,
    gu = true,
    gw = true,
    gy = true,
    hk = true,
    hm = true,
    hn = true,
    hr = true,
    ht = true,
    hu = true,
    id = true,
    ie = true,
    il = true,
    im = true,
    ['in'] = true,
    info = true,
    int = true,
    io = true,
    iq = true,
    ir = true,
    is = true,
    it = true,
    je = true,
    jm = true,
    jo = true,
    jobs = true,
    jp = true,
    ke = true,
    kg = true,
    kh = true,
    ki = true,
    km = true,
    kn = true,
    kp = true,
    kr = true,
    kw = true,
    ky = true,
    kz = true,
    la = true,
    lb = true,
    lc = true,
    li = true,
    lk = true,
    lr = true,
    ls = true,
    lt = true,
    lu = true,
    lv = true,
    ly = true,
    ma = true,
    mc = true,
    md = false,
    me = true,
    mg = true,
    mh = true,
    mil = true,
    mk = true,
    ml = true,
    mm = true,
    mn = true,
    mo = true,
    mobi = true,
    mp = true,
    mq = true,
    mr = true,
    ms = true,
    mt = true,
    mu = true,
    museum = true,
    mv = true,
    mw = true,
    mx = true,
    my = true,
    mz = true,
    na = true,
    name = true,
    nato = true,
    nc = true,
    ne = true,
    net = true,
    nf = true,
    ng = true,
    ni = true,
    nl = true,
    no = true,
    nom = true,
    np = true,
    nr = true,
    nt = true,
    nu = true,
    nz = true,
    om = true,
    org = true,
    pa = true,
    pe = true,
    pf = true,
    pg = true,
    ph = true,
    pk = true,
    pl = true,
    pm = true,
    pn = true,
    post = true,
    pr = true,
    pro = true,
    ps = true,
    pt = true,
    pw = true,
    py = true,
    qa = true,
    re = true,
    ro = true,
    ru = true,
    rw = true,
    sa = true,
    sb = true,
    sc = true,
    sd = true,
    se = true,
    sg = true,
    sh = true,
    si = true,
    sj = true,
    sk = true,
    sl = true,
    sm = true,
    sn = true,
    so = true,
    sr = true,
    ss = true,
    st = true,
    store = true,
    su = true,
    sv = true,
    sy = true,
    sz = true,
    tc = true,
    td = true,
    tel = true,
    tf = true,
    tg = true,
    th = true,
    tj = true,
    tk = true,
    tl = true,
    tm = true,
    tn = true,
    to = true,
    tp = true,
    tr = true,
    travel = true,
    tt = true,
    tv = true,
    tw = true,
    tz = true,
    ua = true,
    ug = true,
    uk = true,
    um = true,
    us = true,
    uy = true,
    va = true,
    vc = true,
    ve = true,
    vg = true,
    vi = true,
    vn = true,
    vu = true,
    web = true,
    wf = true,
    ws = true,
    xxx = true,
    ye = true,
    yt = true,
    yu = true,
    za = true,
    zm = true,
    zr = true,
    zw = true
  }

  -- Table of protocols
  local protocols = {
    [''] = 0,
    ['http://'] = 0,
    ['https://'] = 0,
    ['ftp://'] = 0
  }

  -- Table for status of url search
  local finished = {}

  -- URL identified
  local found_url = nil

  -- Function to return the max value of the four inputs
  local function max_of_four(a, b, c, d)
    return math.max(a + 0, b + 0, c + 0, d + 0)
  end

  -- For each group in the match, do some stuff
  for pos_start, _, prot, subd, tld, colon, port, slash, path in
      string:gmatch '()(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))' do
    if protocols[prot:lower()] == (1 - #slash) * #path and not subd:find '%W%W' and
        (colon == '' or port ~= '' and port + 0 < 65536) and
        (tlds[tld:lower()] or tld:find '^%d+$' and subd:find '^%d+%.%d+%.%d+%.$' and
            max_of_four(tld, subd:match '^(%d+)%.(%d+)%.(%d+)%.$') < 256) then
      finished[pos_start] = true
      found_url = true
    end
  end

  for pos_start, _, prot, dom, colon, port, slash, path in
      string:gmatch '()((%f[%w]%a+://)(%w[-.%w]*)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))' do
    if not finished[pos_start] and not (dom .. '.'):find '%W%W' and
        protocols[prot:lower()] == (1 - #slash) * #path and
        (colon == '' or port ~= '' and port + 0 < 65536) then
      found_url = true
    end
  end

  if found_url ~= true then found_url = false end
  return found_url
end

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

  local dest = text:sub(vbegin[2], vend[2] + offset):gsub('[%p%c]', ''):gsub(
                   '%s', '_'):lower() .. '.md'

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
