local configuration = require('loci.confi')

local function setup(config)
  configuration.settings = config or {}
end
