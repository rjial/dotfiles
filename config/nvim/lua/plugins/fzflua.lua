return {
  -- fzf-lua: used for grep because it supports true fuzzy over file contents.
  -- In live_grep, <C-g> toggles between ripgrep (regex) and fuzzy-over-all mode.
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = {
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep (live, <C-g> toggles fuzzy)" },
      { "<leader>fG", "<cmd>FzfLua grep_project<cr>", desc = "Grep project (fuzzy over all lines)" },
      { "<leader>fw", "<cmd>FzfLua grep_cword<cr>", desc = "Grep word under cursor" },
      { "<leader>fw", "<cmd>FzfLua grep_visual<cr>", mode = "v", desc = "Grep selection" },
      { "<leader>fR", "<cmd>FzfLua resume<cr>", desc = "Resume last fzf search" },
    },
    opts = {
      "default", -- base profile
      winopts = {
        height = 0.85,
        width = 0.88,
        border = "rounded",
        preview = { layout = "vertical", vertical = "down:45%" },
      },
      fzf_colors = true, -- inherit the catppuccin colorscheme
      grep = {
        rg_glob = true, -- support `foo -- --glob=*.ts` inline globbing
        rg_opts = "--hidden --column --line-number --no-heading --color=always --smart-case -g '!.git' -g '!node_modules' -g '!vendor'",
      },
      keymap = {
        fzf = {
          ["ctrl-q"] = "select-all+accept", -- send matches to quickfix
          ["ctrl-d"] = "preview-page-down",
          ["ctrl-u"] = "preview-page-up",
        },
      },
    },
  },
}
