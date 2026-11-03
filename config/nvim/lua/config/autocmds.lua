-- Autocommands
local function augroup(name)
  return vim.api.nvim_create_augroup("cfg_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})

-- Return to last cursor position when opening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close some filetypes with just <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "dap-float" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Trim trailing whitespace on save (skip special / non-modifiable buffers)
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("trim_ws"),
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" or not vim.bo[ev.buf].modifiable then
      return
    end
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Per-language indentation (4 spaces where idiomatic)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_4"),
  pattern = { "python", "php", "blade" },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
  end,
})

-- Go uses real tabs
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_go"),
  pattern = "go",
  callback = function()
    vim.bo.expandtab = false
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
  end,
})

-- Utility/side windows that shouldn't keep Neovim alive on :q
local util_ft = {
  "neo-tree", "neo-tree-popup", "toggleterm", "snacks_terminal",
  "dap-repl", "dapui_scopes", "dapui_breakpoints", "dapui_stacks",
  "dapui_watches", "dapui_console", "dapui_hover",
  "qf", "help", "trouble", "snacks_dashboard",
}

local function is_util_win(win)
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    return true -- floating window (e.g. claude float, lazygit)
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].filetype
  local bt = vim.bo[buf].buftype
  return vim.tbl_contains(util_ft, ft) or bt == "terminal"
end

-- Close all side/utility panes in the current tab (manual sweep)
vim.api.nvim_create_user_command("CloseSidePanes", function()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_util_win(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end, { desc = "Close explorer/terminal/claude/dap side panes" })

-- When quitting the last real (code) window, drop the side panes too so :q exits
vim.api.nvim_create_autocmd("QuitPre", {
  group = augroup("smart_quit"),
  callback = function()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local code_wins = {}
    for _, win in ipairs(wins) do
      if not is_util_win(win) then
        code_wins[#code_wins + 1] = win
      end
    end
    -- exactly one normal window left => this :q is quitting it; sweep the rest
    if #code_wins <= 1 then
      for _, win in ipairs(wins) do
        if is_util_win(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end
  end,
})

-- Auto-create missing parent dirs on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_mkdir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
