return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  event = "VeryLazy",
  opts = {
    options = {
      -- Luôn hiển thị bufferline
      always_show_bufferline = true,
      -- Hiển thị số thứ tự buffer
      numbers = "ordinal",
      -- Đóng buffer bằng chuột phải
      close_command = "bdelete! %d",
      right_mouse_command = "bdelete! %d",
      -- Hiển thị icon đóng
      show_close_icon = true,
      show_buffer_close_icons = true,
      -- Tùy chỉnh separator
      separator_style = "thin",
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)

    -- Keymaps chuyển buffer nhanh
    local map = vim.keymap.set
    map("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer", silent = true })
    map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer", silent = true })
    map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer", silent = true })
    map("n", "<leader>bD", "<cmd>bdelete!<cr>", { desc = "Force delete buffer", silent = true })
  end,
}
