-- neovim.lua — BlueArchiveOS config. Use 99-ba-user.lua for overrides.
return {
  {
    -- Local ba.nvim (renamed from yukazakiri/inir.nvim)
    dir = vim.fn.expand("~/.local/share/nvim/lazy/ba.nvim"),
    name = "ba.nvim",
    priority = 1000,
    opts = {},
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ba",
    },
  },
}
