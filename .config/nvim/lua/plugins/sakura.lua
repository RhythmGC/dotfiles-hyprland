return {
  "anAcc22/sakura.nvim",
  dependencies = "rktjmp/lush.nvim",
  priority = 1000,
  config = function()
    vim.opt.background = "dark"
    vim.cmd.colorscheme("sakura")

    local function vibrant_pink()
      -- Palette phân biệt rõ ràng, tránh loạn màu
      local c = {
        keyword = "#ff79c6",   -- hot pink (if, return, end...)
        cond = "#ff9ece",      -- hồng sáng (then, else...)
        bool = "#7ee9ff",      -- cyan (true, false) ← khác biệt rõ
        func = "#c3a6ff",      -- tím nhạt (function names)
        str = "#a5ffd4",       -- mint (strings)
        num = "#ffe66d",       -- vàng nhạt (numbers)
        var = "#ffd1dc",       -- hồng phấn (variables)
        delim = "#b0b0b0",     -- xám bạc ({ } ( ) [ ])
        op = "#ff85a1",        -- salmon (+ - =)
        type = "#ff69b4",      -- hot pink đậm (types)
        comment = "#6c5b6b",   -- xám tím (comments)
        preproc = "#ffb6d5",   -- hồng phấn (#include...)
        deep = "#ff1493",      -- deep pink (labels, exceptions)
      }

      local groups = {
        -- Keywords
        Keyword = { fg = c.keyword },
        Statement = { fg = c.keyword },
        Repeat = { fg = c.keyword },
        Conditional = { fg = c.cond },
        Label = { fg = c.deep, bold = true },
        Exception = { fg = c.deep, bold = true },

        -- Literals (tách biệt rõ)
        Boolean = { fg = c.bool, bold = true },
        Number = { fg = c.num },
        Float = { fg = c.num },
        String = { fg = c.str, italic = true },
        Character = { fg = c.str },

        -- Functions & Types
        Function = { fg = c.func },
        Type = { fg = c.type, italic = true, bold = true },
        StorageClass = { fg = c.type },
        Typedef = { fg = c.type },

        -- PreProc
        PreProc = { fg = c.preproc, bold = true },
        Define = { fg = c.preproc },
        Macro = { fg = c.preproc, bold = true },
        Include = { fg = c.preproc, bold = true },

        -- Delimiters / Punctuation ← xám bạc để không gây nhiễu
        Delimiter = { fg = c.delim },
        Operator = { fg = c.op },

        -- Identifiers
        Identifier = { fg = c.var },
        Constant = { fg = c.var },

        -- Tree-sitter overrides
        ["@keyword"] = { fg = c.keyword },
        ["@keyword.repeat"] = { fg = c.keyword },
        ["@keyword.conditional"] = { fg = c.cond },
        ["@keyword.function"] = { fg = c.keyword },
        ["@keyword.return"] = { fg = c.keyword },
        ["@keyword.import"] = { fg = c.preproc },
        ["@keyword.export"] = { fg = c.preproc },
        ["@conditional"] = { fg = c.cond },
        ["@repeat"] = { fg = c.keyword },
        ["@label"] = { fg = c.deep, bold = true },
        ["@operator"] = { fg = c.op },
        ["@type"] = { fg = c.type, italic = true, bold = true },
        ["@type.builtin"] = { fg = c.type, italic = true, bold = true },
        ["@type.definition"] = { fg = c.type },
        ["@storageclass"] = { fg = c.type },
        ["@function"] = { fg = c.func },
        ["@function.builtin"] = { fg = c.func },
        ["@function.call"] = { fg = c.func },
        ["@method"] = { fg = c.func },
        ["@method.call"] = { fg = c.func },
        ["@variable"] = { fg = c.var },
        ["@property"] = { fg = c.var },
        ["@field"] = { fg = c.var },
        ["@parameter"] = { fg = c.var },
        ["@constant"] = { fg = c.var },
        ["@number"] = { fg = c.num },
        ["@float"] = { fg = c.num },
        ["@boolean"] = { fg = c.bool, bold = true },
        ["@string"] = { fg = c.str, italic = true },
        ["@string.escape"] = { fg = c.op },
        ["@character"] = { fg = c.str },
        ["@punctuation.delimiter"] = { fg = c.delim },
        ["@punctuation.bracket"] = { fg = c.delim },
        ["@punctuation.special"] = { fg = c.delim },
        ["@comment"] = { fg = c.comment, italic = true },

        -- UI
        ModeMsg = { fg = c.cond },
        MsgArea = { fg = c.cond },
        MsgSeparator = { fg = c.cond },
        MoreMsg = { fg = c.cond },
        DiagnosticHint = { fg = c.cond },
        DiagnosticUnderlineHint = { sp = c.cond, undercurl = true },
        NvimTreeFolderIcon = { fg = c.cond },
        TodoBgNOTE = { bg = c.cond, bold = true },
        TodoFgNOTE = { fg = c.cond, bold = true },
        IblIndent = { fg = c.op },
        RainbowDelimiterGreen = { fg = c.cond },
      }

      for group, opts in pairs(groups) do
        vim.api.nvim_set_hl(0, group, opts)
      end
    end

    vibrant_pink()

    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "sakura",
      callback = vibrant_pink,
    })
  end,
}
