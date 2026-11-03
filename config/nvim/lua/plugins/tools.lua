return {
  -- Auto-install formatters / debug adapters that aren't LSP servers
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason.nvim" },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        -- formatters
        "stylua",
        "prettierd",
        "gofumpt",
        "goimports",
        "blade-formatter",
        "sql-formatter",
        -- php style (pint is usually project-local via composer; php-cs-fixer as fallback)
        "php-cs-fixer",
        -- debug adapters
        "js-debug-adapter",
        "delve",
        "php-debug-adapter",
      },
      run_on_start = true,
      auto_update = false,
    },
  },
}
