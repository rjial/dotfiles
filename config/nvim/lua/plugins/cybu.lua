return {
  -- VSCode-like Ctrl+Tab: a floating overlay listing buffers while you cycle.
  -- last-used mode = MRU order, matching VSCode's editor switcher.
  {
    "ghillb/cybu.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-Tab>", "<cmd>CybuLastusedNext<cr>", mode = { "n", "i" }, desc = "Switch buffer (MRU, overlay)" },
      { "<C-S-Tab>", "<cmd>CybuLastusedPrev<cr>", mode = { "n", "i" }, desc = "Switch buffer back (MRU, overlay)" },
      { "[b", "<cmd>CybuPrev<cr>", desc = "Prev buffer (overlay)" },
      { "]b", "<cmd>CybuNext<cr>", desc = "Next buffer (overlay)" },
    },
    opts = {
      position = {
        relative_to = "win",
        anchor = "topcenter",
        vertical_offset = 8,
        max_win_height = 12,
        max_win_width = 0.5,
      },
      style = {
        path = "relative",
        border = "rounded",
        separator = " ",
        prefix = "…",
        padding = 1,
        hide_buffer_id = true,
        devicons = { enabled = true, colored = true },
        highlights = {
          current_buffer = "CursorLine",
          adjacent_buffers = "Comment",
          background = "Normal",
          border = "FloatBorder",
        },
      },
      behavior = {
        mode = {
          default = { switch = "immediate", view = "paging" },
          last_used = { switch = "immediate", view = "paging" },
        },
        show_on_autocmd = false,
      },
      display_time = 1600, -- overlay fades after this many ms
      exclude = { "neo-tree", "qf", "toggleterm", "snacks_terminal", "lazy", "mason", "dapui_scopes" },
    },
  },
}
