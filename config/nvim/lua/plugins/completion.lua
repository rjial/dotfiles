return {
  {
    "saghen/blink.cmp",
    version = "1.*", -- release tag, ships prebuilt fuzzy matcher
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "giuxtaposition/blink-cmp-copilot", -- copilot as a completion source
    },
    opts = {
      keymap = {
        preset = "default", -- <C-y> confirm, <C-space> menu, <C-n>/<C-p> select
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true },
        menu = {
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
              { "source_name" },
            },
          },
        },
      },
      signature = { enabled = true },
      sources = {
        default = { "copilot", "lsp", "path", "snippets", "buffer" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 100,
            async = true,
          },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      cmdline = { enabled = true },
    },
  },
}
