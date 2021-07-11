local M = {
  workspaces = {
    loci = { path = "~/loci" }
  },
  filetypes = {
    images = {'.png', '.jpeg', '.jpg', '.bmp', '.tif'},
    doc = {'.pdf', '.docx'},
  },
  launcher = (function()
    if vim.fn.has("win32") == 1 then
      return "open"
    elseif vim.fn.has("mac") == 1 then
      return "open"
    elseif vim.fn.has("unix") == 1 then
      return "xdg-open"
    end
  end)(),
  current_workspace = nil
}

return M
