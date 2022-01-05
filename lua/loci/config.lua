local M = {
  cfg = {
    create_dirs = true,
    workspaces = {
      ["Loci"] = {
        path = "~/Loci.2",
        journals = {
          ['diary'] = {default = true, path = "journal/diary", type = 'daily'},
          ['notes'] = {path = "journal/notes", type = 'weekly'},
          ['review'] = {path = "journal/review", type = 'quarterly'}
        }
      }
    }
  },
  ws = nil
}

return M
