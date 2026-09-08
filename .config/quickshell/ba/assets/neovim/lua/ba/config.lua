--- ba.nvim configuration
---@class ba.Config
---@field transparent? boolean  Make all backgrounds NONE (default: true)
---@field terminal_colors? boolean  Set terminal colour variables (default: true)
---@field live_reload? boolean  Watch JSON files and reload on change (default: true)
---@field generated_dir? string  Path to BlueArchive generated dir
---@field styles? ba.Styles  Syntax styling options
---@field on_colors? fun(colors: ba.Palette)  Callback to modify palette
---@field on_highlights? fun(hl: table, colors: ba.Palette)  Callback to modify highlights
---@field lualine_bold? boolean  Bold lualine section headers (default: false)

---@class ba.Styles
---@field comments? vim.api.keyset.highlight
---@field keywords? vim.api.keyset.highlight
---@field functions? vim.api.keyset.highlight
---@field variables? vim.api.keyset.highlight

local M = {}

---@type ba.Config
M.defaults = {
  transparent = true,
  terminal_colors = true,
  live_reload = true,
  generated_dir = vim.fn.expand("~/.local/state/quickshell/user/generated"),
  styles = {
    comments = { italic = true },
    keywords = { italic = true },
    functions = {},
    variables = {},
  },
  on_colors = function() end,
  on_highlights = function() end,
  lualine_bold = false,
}

---@type ba.Config
M.options = nil

---@param opts? ba.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

--- Resolve current config (setup if needed)
---@return ba.Config
function M.resolve()
  if not M.options then
    M.setup()
  end
  return M.options
end

return M
