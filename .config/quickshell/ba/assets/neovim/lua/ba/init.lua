--- ba.nvim — BlueArchive Material You colorscheme for Neovim
--- Reads palette.json + terminal.json from the BlueArchive theming pipeline
--- and applies a fully dynamic, transparent colorscheme.
---@class ba
---@field config ba.Config
local M = {}

--- Load and apply the colorscheme
function M.load()
  local config = require("ba.config").resolve()
  local palette = require("ba.palette").load(config)
  require("ba.highlights").apply(palette, config)
  require("ba.terminal").apply(palette)

  vim.g.colors_name = "ba"

  -- Start the file watcher for live reloading (if not already started)
  if config.live_reload then
    require("ba.watcher").start(config)
  end
end

--- Configure the plugin.  Call this from your lazy plugin spec's opts.
---@param opts? ba.Config
function M.setup(opts)
  require("ba.config").setup(opts)
end

return M
