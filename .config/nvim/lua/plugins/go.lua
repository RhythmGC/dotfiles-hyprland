local function set_go_highlight(group, source, extra)
  local highlight = vim.api.nvim_get_hl(0, { name = source, link = false })

  if not highlight.fg then
    highlight = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  end

  vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", highlight, extra or {}))
end

local function highlight_go_symbols()
  -- Tree-sitter highlights. Declarations are bold; calls keep the same clear
  -- function color without making every line visually heavy.
  set_go_highlight("@function.go", "Function", { bold = true })
  set_go_highlight("@function.method.go", "Function", { bold = true })
  set_go_highlight("@function.call.go", "Function")
  set_go_highlight("@function.method.call.go", "Function")
  set_go_highlight("@function.builtin.go", "Special", { italic = true })
  set_go_highlight("@constructor.go", "Type", { bold = true })

  -- gopls semantic tokens take priority over Tree-sitter when available.
  set_go_highlight("@lsp.type.function.go", "Function")
  set_go_highlight("@lsp.type.method.go", "Function")
  set_go_highlight("@lsp.typemod.function.definition.go", "Function", { bold = true })
  set_go_highlight("@lsp.typemod.method.definition.go", "Function", { bold = true })
end

return {
  {
    "LazyVim/LazyVim",
    init = function()
      local group = vim.api.nvim_create_augroup("go-symbol-highlights", { clear = true })

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = highlight_go_symbols,
      })

      vim.schedule(highlight_go_symbols)
    end,
  },
}
