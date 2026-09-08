--- ba.nvim file watcher
--- Monitors BlueArchive generated JSON files and live-reloads the colorscheme.
local M = {}

---@param config ba.Config
function M.start(config)
  -- Only start once per session
  if vim.g.ba_watcher_started then
    return
  end

  local uv = vim.uv or vim.loop
  if not uv then
    return
  end

  local dir = config.generated_dir
  local watched = {
    ["palette.json"] = true,
    ["terminal.json"] = true,
    ["colors.json"] = true,
  }

  local handle = uv.new_fs_event()
  if not handle then
    return
  end

  local pending = false

  handle:start(dir, {}, vim.schedule_wrap(function(err, fname)
    if err or pending then
      return
    end
    if fname and not watched[fname] then
      return
    end

    pending = true
    vim.defer_fn(function()
      pending = false
      if vim.g.colors_name == "ba" then
        -- Re-load the colorscheme (re-reads JSON, re-applies highlights)
        require("ba").load()
      end
    end, 150)
  end))

  vim.g.ba_watcher_started = true
end

return M
