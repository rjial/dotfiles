return {
  -- Better Lua LSP experience when editing this Neovim config
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        "lazy.nvim",
      },
    },
  },
}
