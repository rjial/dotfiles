return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      current_line_blame = false,
      on_attach = function(buffer)
        local gs = require("gitsigns")
        local function m(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = "Git: " .. desc })
        end
        m("n", "]h", function()
          if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
        end, "Next hunk")
        m("n", "[h", function()
          if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
        end, "Prev hunk")
        m("n", "<leader>ghs", gs.stage_hunk, "Stage hunk")
        m("n", "<leader>ghr", gs.reset_hunk, "Reset hunk")
        m("v", "<leader>ghs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk")
        m("v", "<leader>ghr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset hunk")
        m("n", "<leader>ghp", gs.preview_hunk, "Preview hunk")
        m("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line")
        m("n", "<leader>ghd", gs.diffthis, "Diff this")
        m("n", "<leader>gtb", gs.toggle_current_line_blame, "Toggle line blame")
      end,
    },
  },
}
