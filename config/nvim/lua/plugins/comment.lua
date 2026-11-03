return {
  -- Context-aware commentstring: picks the right comment syntax inside embedded
  -- languages (e.g. {/* */} in JSX markup vs // in JS, <!-- --> in Blade/HTML).
  -- Feeds Neovim's built-in `gc`/`gcc` commenting via the commentstring hook.
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    init = function()
      vim.g.skip_ts_context_commentstring_module = true
    end,
    config = function()
      require("ts_context_commentstring").setup({ enable_autocmd = false })
      -- Hook the built-in commenting: resolve commentstring from treesitter context
      local get_option = vim.filetype.get_option
      vim.filetype.get_option = function(filetype, option)
        if option == "commentstring" then
          local ok, cs = pcall(require("ts_context_commentstring.internal").calculate_commentstring)
          if ok and cs then
            return cs
          end
        end
        return get_option(filetype, option)
      end
    end,
  },
}
