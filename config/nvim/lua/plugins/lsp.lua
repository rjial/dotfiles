return {
  -- Mason: installer for LSP servers, formatters, linters, DAP adapters
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded", icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
    },
  },

  -- LSP config (native vim.lsp.config + vim.lsp.enable, driven by mason-lspconfig v2)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason-lspconfig.nvim" },
      { "mason.nvim" },
      { "b0o/schemastore.nvim" }, -- json/yaml schemas
      { "saghen/blink.cmp" }, -- for capabilities
    },
    config = function()
      -- Silence VS Code-only client commands some servers request (vtsls/angularls)
      -- so they don't spam "Command setContext not found" into the LSP log.
      vim.lsp.commands = vim.lsp.commands or {}
      for _, c in ipairs({ "setContext", "_typescript.configurePlugin" }) do
        vim.lsp.commands[c] = vim.lsp.commands[c] or function() end
      end

      -- Diagnostics UI
      vim.diagnostic.config({
        severity_sort = true,
        float = { border = "rounded", source = true },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
        virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
      })

      -- Keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("cfg_lsp_attach", { clear = true }),
        callback = function(event)
          local function m(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          m("grd", vim.lsp.buf.definition, "Goto definition")
          m("grr", vim.lsp.buf.references, "References")
          m("gri", vim.lsp.buf.implementation, "Goto implementation")
          m("grt", vim.lsp.buf.type_definition, "Type definition")
          m("grn", vim.lsp.buf.rename, "Rename")
          m("gra", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          m("grD", vim.lsp.buf.declaration, "Goto declaration")
          m("K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover")
          m("gK", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "Signature help")
          m("<leader>cl", "<cmd>LspInfo<cr>", "Lsp info")

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          -- Inlay hints toggle (if server supports)
          if client and client:supports_method("textDocument/inlayHint") then
            m("<leader>ch", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
            end, "Toggle inlay hints")
          end
          -- Document highlight on cursor hold
          if client and client:supports_method("textDocument/documentHighlight") then
            local hl = vim.api.nvim_create_augroup("cfg_lsp_highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf, group = hl, callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf, group = hl, callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      -- Global capabilities (blink.cmp)
      local caps = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("*", { capabilities = caps })

      -- Per-server overrides. Base configs come from nvim-lspconfig's lsp/ dir.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            codeLens = { enable = true },
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim" } },
            hint = { enable = true },
          },
        },
      })

      vim.lsp.config("vtsls", {
        settings = {
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            inlayHints = {
              parameterNames = { enabled = "literals" },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
            },
          },
          javascript = { updateImportsOnFileMove = { enabled = "always" } },
          vtsls = { experimental = { completion = { enableServerSideFuzzyMatch = true } } },
        },
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
        },
      })

      vim.lsp.config("yamlls", {
        settings = {
          yaml = { schemaStore = { enable = false, url = "" }, schemas = require("schemastore").yaml.schemas() },
        },
      })

      vim.lsp.config("intelephense", {
        settings = {
          intelephense = {
            files = { maxSize = 5000000 },
          },
        },
      })

      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            gofumpt = true,
            usePlaceholders = true,
            analyses = { unusedparams = true, nilness = true, unusedwrite = true, useany = true },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            staticcheck = true,
          },
        },
      })

      vim.lsp.config("pyright", {
        settings = {
          pyright = { disableOrganizeImports = true }, -- ruff handles imports
          python = { analysis = { typeCheckingMode = "basic", autoImportCompletions = true } },
        },
      })

      -- ruff: use it only as linter/formatter, let pyright own hover
      vim.lsp.config("ruff", {
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      })

      -- eslint: format-on-save via its own command (set up in conform too; here enable code action)
      vim.lsp.config("eslint", {
        settings = { workingDirectories = { mode = "auto" } },
      })

      -- Angular Language Service, user-scoped: probe the @angular/language-service
      -- and typescript bundled inside Mason's install, so work projects stay clean
      -- (no need for @angular/language-service in the project's node_modules).
      local ng_root = vim.fn.stdpath("data")
        .. "/mason/packages/angular-language-server/node_modules/@angular/language-server"
      vim.lsp.config("angularls", {
        cmd = { "ngserver", "--stdio", "--tsProbeLocations", ng_root, "--ngProbeLocations", ng_root },
        filetypes = { "typescript", "html", "htmlangular" },
        root_markers = { "angular.json", "nx.json", "project.json" },
      })

      -- tailwind: enable in common web filetypes
      vim.lsp.config("tailwindcss", {
        filetypes = { "html", "htmlangular", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "blade", "php" },
      })

      -- mason-lspconfig: install + auto-enable the servers
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "vtsls",
          "eslint",
          "tailwindcss",
          "cssls",
          "html",
          "emmet_language_server",
          "angularls",
          "jsonls",
          "yamlls",
          "intelephense",
          "gopls",
          "pyright",
          "ruff",
        },
        automatic_enable = true,
      })
    end,
  },
}
