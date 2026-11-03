return {
  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer (toggle)" },
      { "<leader>o", "<cmd>Neotree focus<cr>", desc = "Explorer (focus)" },
    },
    opts = {
      close_if_last_window = true,
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = true },
      },
      window = { width = 32, mappings = { ["<space>"] = "none" } },
    },
  },

  -- Keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>a", group = "ai/claude" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>d", group = "debug" },
        { "<leader>q", group = "quit" },
        { "<leader>t", group = "terminal" },
        { "<leader>u", group = "ui/toggle" },
        { "<leader>b", group = "buffer" },
        { "gr", group = "lsp" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
    },
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin-frappe", -- catppuccin ships per-flavour theme files, not a bare "catppuccin"
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          {
            function()
              local ok, c = pcall(require, "copilot.client")
              if ok and not c.is_disabled() then return "" end
              return ""
            end,
          },
          "diagnostics", "encoding", "filetype",
        },
      },
    },
  },

  -- Pairs + tags + surround + comments
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
  { "kylechui/nvim-surround", event = "VeryLazy", version = "*", opts = {} },

  -- Quality-of-life: bufdelete, indent guides, notifier, big-file handling, dashboard
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      indent = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      scope = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Grep Text", action = ":Telescope live_grep" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
            { icon = " ", key = "c", desc = "Config", action = ":e ~/.config/nvim/init.lua" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
    keys = {
      { "<leader>bd", function() require("snacks").bufdelete() end, desc = "Delete buffer" },
      { "<leader>bD", function() require("snacks").bufdelete.all() end, desc = "Delete all buffers" },
      { "<leader>un", function() require("snacks").notifier.hide() end, desc = "Dismiss notifications" },
      { "<leader>gg", function() require("snacks").lazygit() end, desc = "Lazygit" },
      { "<leader>gb", function() require("snacks").git.blame_line() end, desc = "Git blame line" },
    },
  },
}
