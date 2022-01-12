local M = {
  cfg = {
    default_mappings = true,
    create_dirs = true,
    workspaces = {
      ["Loci"] = {
        path = "~/Loci",
        journals = {
          ['diary'] = {default = true, type = 'daily'},
          ['notes'] = {type = 'weekly'},
        }
      }
    }
  },
  ws = nil
}

return M
