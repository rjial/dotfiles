return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "ToggleTermToggleAll", "TermExec", "ToggleTermSendVisualSelection", "ToggleTermSendCurrentLine" },
    keys = {
      -- Ctrl-\ toggles the last-used terminal from anywhere
      { [[<C-\>]], "<cmd>ToggleTerm<cr>", mode = { "n", "t" }, desc = "Toggle terminal" },
      { "<leader>tt", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal (float)" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (horizontal)" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal (vertical)" },
      { "<leader>t1", "<cmd>1ToggleTerm<cr>", desc = "Terminal 1" },
      { "<leader>t2", "<cmd>2ToggleTerm<cr>", desc = "Terminal 2" },
      { "<leader>t3", "<cmd>3ToggleTerm<cr>", desc = "Terminal 3" },
      { "<leader>ta", "<cmd>ToggleTermToggleAll<cr>", desc = "Toggle all terminals" },
      -- Send code to the terminal
      { "<leader>ts", "<cmd>ToggleTermSendVisualSelection<cr>", mode = "v", desc = "Send selection" },
      { "<leader>tl", "<cmd>ToggleTermSendCurrentLine<cr>", desc = "Send current line" },
    },
    opts = {
      open_mapping = [[<C-\>]],
      direction = "float",
      shade_terminals = true,
      start_in_insert = true,
      persist_mode = true,
      persist_size = true,
      close_on_exit = true,
      autochdir = false,
      float_opts = { border = "rounded", title_pos = "center" },
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      -- Terminal-mode keymaps: easier escape + window nav from inside a term
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*toggleterm#*",
        callback = function()
          local o = { buffer = 0 }
          vim.keymap.set("t", "<esc><esc>", [[<C-\><C-n>]], o)
          vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], o)
          vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], o)
          vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], o)
          vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], o)
        end,
      })

      -- Named REPL terminals, opened on demand
      local Terminal = require("toggleterm.terminal").Terminal

      local node = Terminal:new({ cmd = "node", hidden = true, direction = "float" })
      local python = Terminal:new({ cmd = "python3", hidden = true, direction = "float" })

      vim.keymap.set("n", "<leader>tn", function() node:toggle() end, { desc = "REPL: node" })
      vim.keymap.set("n", "<leader>tp", function() python:toggle() end, { desc = "REPL: python" })
    end,
  },
}
