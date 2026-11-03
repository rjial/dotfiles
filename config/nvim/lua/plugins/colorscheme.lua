return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "frappe", -- matches foot terminal (Catppuccin Frappé)
      transparent_background = false,
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        neotree = true,
        telescope = true,
        treesitter = true,
        which_key = true,
        mason = true,
        dap = true,
        dap_ui = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
