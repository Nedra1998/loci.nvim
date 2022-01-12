local M = {
  cfg = {
    default_mappings = true,
    create_dirs = true,
    workspaces = {
      ["Loci"] = {
        path = "~/Loci",
        journals = {
          ['diary'] = {default = true, recurrence = 'daily'},
          ['notes'] = {recurrence = 'weekly'},
        }
      }
    }
  },
  ws = nil
}

return M
