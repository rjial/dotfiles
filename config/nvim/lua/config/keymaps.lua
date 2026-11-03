-- General keymaps (plugin-specific maps live in their plugin spec)
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlight" })

-- Better up/down on wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize with arrows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Move lines up/down
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered on jumps
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Stay in indent mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Don't lose paste register on visual paste
map("x", "<leader>p", [["_dP]], { desc = "Paste without yank" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
-- Ctrl+Tab buffer switcher = cybu.nvim floating overlay (keys defined in its spec).
map("n", "<C-^>", "<C-^>", { desc = "Last-used buffer (alternate)" })

-- Save / quit
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>q<cr>", { desc = "Quit window" })
map("n", "<leader>qa", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>qw", "<cmd>CloseSidePanes<cr>", { desc = "Close side panes" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Force quit all" })
-- ZZ-style: close every side pane then quit the editor
map("n", "<leader>qz", function()
  vim.cmd("CloseSidePanes")
  vim.cmd("qa")
end, { desc = "Close panes + quit" })

-- Diagnostics
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })

-- Command palette like VSCode (Ctrl+Shift+P). foot supports the kitty keyboard
-- protocol so <C-S-p> is distinguishable; <leader>p is a guaranteed fallback.
map({ "n", "i" }, "<C-S-p>", "<cmd>Telescope commands<cr>", { desc = "Command palette" })
map("n", "<leader>p", "<cmd>Telescope commands<cr>", { desc = "Command palette" })

-- Toggle comment like VSCode (Ctrl+/). Some terminals send <C-_> instead, so map both.
map("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
map("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
map("x", "<C-/>", "gc", { remap = true, desc = "Toggle comment" })
map("x", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })
map("i", "<C-/>", "<Cmd>normal gcc<CR>", { desc = "Toggle comment" })
map("i", "<C-_>", "<Cmd>normal gcc<CR>", { desc = "Toggle comment" })

-- Terminal escape
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
