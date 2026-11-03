return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
    keys = {
      { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
      { "<leader>bc", "<cmd>BufferLinePickClose<cr>", desc = "Pick buffer to close" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
      { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Close buffers to the left" },
      { "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Close buffers to the right" },
      { "<leader>bP", "<cmd>BufferLineTogglePin<cr>", desc = "Toggle pin" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      { "<leader>b1", "<cmd>BufferLineGoToBuffer 1<cr>", desc = "Buffer 1" },
      { "<leader>b2", "<cmd>BufferLineGoToBuffer 2<cr>", desc = "Buffer 2" },
      { "<leader>b3", "<cmd>BufferLineGoToBuffer 3<cr>", desc = "Buffer 3" },
      { "<leader>b4", "<cmd>BufferLineGoToBuffer 4<cr>", desc = "Buffer 4" },
      { "<leader>b5", "<cmd>BufferLineGoToBuffer 5<cr>", desc = "Buffer 5" },
      { "<leader>b$", "<cmd>BufferLineGoToBuffer -1<cr>", desc = "Last buffer" },
    },
    opts = function()
      return {
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(_, _, diag)
            local icons = { error = " ", warning = " ", info = " " }
            local s = {}
            for k, v in pairs(icons) do
              if diag[k] then
                s[#s + 1] = v .. diag[k]
              end
            end
            return table.concat(s, " ")
          end,
          separator_style = "slant",
          show_buffer_close_icons = true,
          show_close_icon = false,
          always_show_bufferline = false,
          offsets = {
            {
              filetype = "neo-tree",
              text = "Explorer",
              text_align = "left",
              highlight = "Directory",
              separator = true,
            },
          },
          hover = { enabled = true, delay = 150, reveal = { "close" } },
        },
        highlights = require("catppuccin.special.bufferline").get_theme(),
      }
    end,
  },
}
