return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
      {
        "<leader>uf",
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Autoformat " .. (vim.g.disable_autoformat and "OFF" or "ON"))
        end,
        desc = "Toggle autoformat",
      },
    },
    opts = function()
      return {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        vue = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        scss = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        htmlangular = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        graphql = { "prettierd", "prettier", stop_after_first = true },
        php = { "pint", "php_cs_fixer", stop_after_first = true },
        blade = { "blade-formatter" },
        go = { "goimports", "gofumpt" },
        python = { "ruff_format", "ruff_organize_imports" },
        sql = { "sql_formatter" },
        ["_"] = { "trim_whitespace" }, -- fallback for unlisted filetypes
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        -- eslint fixes handled by the LSP; conform does the style pass
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
      formatters = {
        -- prefer project-local pint if present
        pint = { command = require("conform.util").find_executable({ "vendor/bin/pint" }, "pint") },
      },
      }
    end,
  },
}
