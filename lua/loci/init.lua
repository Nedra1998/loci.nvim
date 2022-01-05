local config = require("loci.config")

local M = {}

function M.setup(opts)
  config = require('plenary.tbl').apply_defaults(opts, config.cfg)
end

return M
