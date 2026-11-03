-- nvim-treesitter MAIN branch (required for Neovim 0.12; the master branch's
-- injection queries crash on 0.12 with "attempt to call method 'range'").
local ensure = {
  "bash", "c", "diff", "lua", "luadoc", "vim", "vimdoc", "query", "regex",
  -- web
  "html", "css", "scss", "javascript", "typescript", "tsx", "json",
  "vue", "svelte", "angular", "graphql", "prisma", "http",
  -- php/laravel
  "php", "phpdoc", "blade",
  -- backend
  "go", "gomod", "gowork", "gosum", "python", "sql",
  -- misc
  "dockerfile", "yaml", "toml", "markdown", "markdown_inline", "gitignore", "gitcommit",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install(ensure)

      -- Template filetypes + parser aliases
      vim.filetype.add({
        pattern = {
          [".*%.blade%.php"] = "blade",
          [".*%.component%.html"] = "htmlangular",
        },
      })
      vim.treesitter.language.register("angular", "htmlangular")

      -- Enable highlighting + treesitter indentation whenever a parser exists
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("cfg_ts_start", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
          if not lang then
            return
          end
          local ok, added = pcall(vim.treesitter.language.add, lang)
          if not (ok and added) then
            return -- parser not installed yet; nothing to start
          end
          vim.treesitter.start(buf, lang)
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Textobjects (main branch API: setup + explicit keymaps)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select").select_textobject
      local move = require("nvim-treesitter-textobjects.move")

      local objs = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      }
      for lhs, obj in pairs(objs) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select(obj, "textobjects")
        end, { silent = true, desc = "TS select " .. obj })
      end

      local function m(lhs, fn, obj, desc)
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          fn(obj, "textobjects")
        end, { silent = true, desc = desc })
      end
      m("]f", move.goto_next_start, "@function.outer", "Next function start")
      m("[f", move.goto_previous_start, "@function.outer", "Prev function start")
      m("]F", move.goto_next_end, "@function.outer", "Next function end")
      m("[F", move.goto_previous_end, "@function.outer", "Prev function end")
      m("]c", move.goto_next_start, "@class.outer", "Next class start")
      m("[c", move.goto_previous_start, "@class.outer", "Prev class start")
    end,
  },

  -- Auto close/rename HTML/JSX/Vue/Blade/Angular tags (independent of branch)
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      per_filetype = {
        htmlangular = { enable_close = true },
        blade = { enable_close = true },
        php = { enable_close = true },
      },
    },
  },
}
