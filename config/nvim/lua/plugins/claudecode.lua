return {
  -- Claude Code integration: connects nvim to the `claude` CLI over the
  -- same WebSocket/MCP protocol the official VS Code extension uses.
  -- Send selections/buffers as context, review diffs inline (accept :w / deny :q).
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      -- Local/native binary install lives here; falls back to "claude" on PATH.
      terminal_cmd = vim.fn.expand("~/.local/bin/claude"),
    },
    cmd = {
      "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSelectModel",
      "ClaudeCodeAdd", "ClaudeCodeSend", "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus", "ClaudeCodeStart", "ClaudeCodeStop",
      "ClaudeCodeOpen", "ClaudeCodeClose",
      "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny", "ClaudeCodeCloseAllDiffs",
    },
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "neo-tree", "oil", "netrw", "snacks_picker_list" },
      },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
}
