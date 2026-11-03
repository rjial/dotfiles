return {
  -- GitHub Copilot (suggestions via blink-cmp-copilot source; panel kept off)
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      -- inline ghost text disabled: copilot flows through blink.cmp completion menu
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        gitcommit = true,
        yaml = true,
        ["."] = false,
      },
    },
  },
}
