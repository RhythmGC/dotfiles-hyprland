return {
  {
    "vyfor/cord.nvim",
    build = ":Cord update",

    opts = {
      text = {
        editing = function()
          local ft = vim.bo.filetype

          if ft == "" then
            ft = "TEXT"
          else
            ft = string.upper(ft)
          end

          return "Working at " .. ft .. " file"
        end,

        workspace = function()
          return "RhythmGC"
        end,
      },

      hooks = {
        post_activity = function(_, activity)
          activity.state = "RhythmGC"
        end,
      },
    },
  },
}
