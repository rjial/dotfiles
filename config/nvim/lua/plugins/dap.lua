return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
      { "jay-babu/mason-nvim-dap.nvim", dependencies = "mason.nvim" },
    },
    keys = {
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue/Start" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Eval expression" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("mason-nvim-dap").setup({
        ensure_installed = { "js", "delve", "php" },
        automatic_installation = true,
        handlers = {}, -- use default adapter setup
      })

      dapui.setup()
      require("nvim-dap-virtual-text").setup({})

      -- auto open/close UI
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      -- breakpoint signs
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticWarn", linehl = "Visual" })

      -- ---- JavaScript / TypeScript / Node (pwa-node via js-debug-adapter) ----
      for _, lang in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap.configurations[lang] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch current file (Node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome against localhost:3000",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
          },
        }
      end

      -- ---- PHP (Xdebug via php-debug-adapter) ----
      dap.configurations.php = {
        {
          type = "php",
          request = "launch",
          name = "Listen for Xdebug (:9003)",
          port = 9003,
        },
      }

      -- Go adapter/configs are provided by nvim-dap-go if added; delve works via mason-nvim-dap default handler.
    end,
  },

  -- Go gets richer config (test/debug nearest) from dap-go
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = "mfussenegger/nvim-dap",
    opts = {},
    keys = {
      { "<leader>dgt", function() require("dap-go").debug_test() end, desc = "Debug Go test", ft = "go" },
      { "<leader>dgl", function() require("dap-go").debug_last_test() end, desc = "Debug last Go test", ft = "go" },
    },
  },
}
