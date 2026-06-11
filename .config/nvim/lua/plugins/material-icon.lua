-- ~/.config/nvim/lua/plugins/icons.lua
return {
  {
    "nvim-mini/mini.icons",
    opts = {
      style = "glyph",

      default = {
        directory = { glyph = "󰉋", hl = "MiniIconsYellow" },
        file = { glyph = "󰈔", hl = "MiniIconsGrey" },
      },

      directory = {
        src = { glyph = "󰉋", hl = "MiniIconsBlue" },
        app = { glyph = "󰉋", hl = "MiniIconsBlue" },
        core = { glyph = "󰉋", hl = "MiniIconsCyan" },
        agent = { glyph = "󰚩", hl = "MiniIconsPurple" },
        agents = { glyph = "󰚩", hl = "MiniIconsPurple" },
        config = { glyph = "󱁿", hl = "MiniIconsGrey" },
        configs = { glyph = "󱁿", hl = "MiniIconsGrey" },
        api = { glyph = "󰒋", hl = "MiniIconsOrange" },
        components = { glyph = "󰅴", hl = "MiniIconsBlue" },
        utils = { glyph = "󱧼", hl = "MiniIconsYellow" },
      },

      extension = {
        py = { glyph = "", hl = "MiniIconsBlue" },
        js = { glyph = "󰌞", hl = "MiniIconsYellow" },
        ts = { glyph = "󰛦", hl = "MiniIconsBlue" },
        lua = { glyph = "󰢱", hl = "MiniIconsBlue" },
        rs = { glyph = "󱘗", hl = "MiniIconsOrange" },
        go = { glyph = "󰟓", hl = "MiniIconsCyan" },
      },
    },
    config = function(_, opts)
      require("mini.icons").setup(opts)
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
}
