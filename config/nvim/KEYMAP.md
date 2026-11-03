# Neovim Keymap Reference

Config: `~/.config/nvim` · **Leader** = `Space` · **Localleader** = `\`

Press `<leader>?` inside Neovim to see the keymaps available in the current buffer (via which-key).

---

## General / Editing

| Key | Action |
|-----|--------|
| `<Esc>` | Clear search highlight |
| `j` / `k` | Move by visual line on wrapped text |
| `<C-d>` / `<C-u>` | Half-page down/up, cursor centered |
| `n` / `N` | Next/prev search match, centered |
| `<A-j>` / `<A-k>` | Move current line (or selection) down/up |
| `<` / `>` (visual) | Indent left/right, keep selection |
| `<leader>p` (visual) | Paste over selection without losing register |
| `<leader>w` | Save file |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `Ctrl+/` | Toggle comment (normal/visual/insert), VSCode-style |
| `gcc` / `gc{motion}` | Toggle comment line / over motion |

## Windows

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Move to left/down/up/right window |
| `<C-Up>` / `<C-Down>` | Resize height +/- |
| `<C-Left>` / `<C-Right>` | Resize width -/+ |

## Quit (`<leader>q`)

| Key | Action |
|-----|--------|
| `<leader>qq` | Quit current window (`:q`) |
| `<leader>qa` | Quit all (`:qa`) |
| `<leader>qw` | Close side panes (explorer/terminal/claude/dap), keep editing |
| `<leader>qz` | Close panes + quit editor |
| `<leader>Q` | Force quit all, discard changes (`:qa!`) |

> Plain `:q` is smart: quitting the last code window also closes explorer, Claude pane, terminals and dap-ui, so Neovim exits cleanly.
> Command `:CloseSidePanes` sweeps side panes without quitting.

---

## Find / Search — Telescope (`<leader>f`)

| Key | Action |
|-----|--------|
| `<leader><space>` | Find files |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (fzf-lua; `<C-g>` toggles ripgrep ⇄ fuzzy) |
| `<leader>fG` | Grep project, fuzzy over all lines (fzf-lua) |
| `<leader>fw` | Grep word under cursor / selection (fzf-lua) |
| `<leader>fR` | Resume last fzf-lua search |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>fk` | Keymaps |
| `<leader>fd` | Diagnostics |
| `<leader>fc` | Commands |
| `<leader>fs` | Document symbols |
| `<leader>fS` | Workspace symbols |
| `<leader>/` | Fuzzy find in current buffer |

Inside a Telescope prompt: `<C-j>`/`<C-k>` move, `<Esc>` close.

## Explorer

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer (neo-tree) |
| `<leader>o` | Focus file explorer |

---

## LSP (active in a code buffer)

| Key | Action |
|-----|--------|
| `grd` | Go to definition |
| `grD` | Go to declaration |
| `grr` | References |
| `gri` | Go to implementation |
| `grt` | Type definition |
| `grn` | Rename symbol |
| `gra` | Code action (normal/visual) |
| `K` | Hover documentation |
| `gK` | Signature help |
| `<leader>cl` | LSP info |
| `<leader>ch` | Toggle inlay hints |
| `<leader>cd` | Line diagnostics (float) |
| `[d` / `]d` | Previous / next diagnostic |

## Code / Format (`<leader>c`)

| Key | Action |
|-----|--------|
| `<leader>cf` | Format buffer (normal/visual) |
| `<leader>uf` | Toggle format-on-save |
| `<leader>cm` | Open Mason (manage LSP/tools) |

Format-on-save is on by default (conform.nvim): prettier, pint, gofumpt, ruff, stylua, etc.

---

## Treesitter

| Key | Action |
|-----|--------|
| `af` / `if` | Select around / inside function |
| `ac` / `ic` | Select around / inside class |
| `aa` / `ia` | Select around / inside parameter |
| `]f` / `[f` | Next / previous function start |
| `]F` / `[F` | Next / previous function end |
| `]c` / `[c` | Next / previous class start |

**Auto-tag:** typing `<div>` auto-inserts `</div>` with the cursor between them; renaming an open tag renames its close tag. Works in HTML, JSX/TSX, Vue, Angular templates, Blade, PHP.

---

## Git

| Key | Action |
|-----|--------|
| `<leader>gg` | Lazygit |
| `<leader>gb` | Git blame line |
| `<leader>gc` | Git commits (Telescope) |
| `<leader>gs` | Git status (Telescope) |
| `]h` / `[h` | Next / previous hunk |
| `<leader>ghs` | Stage hunk (normal/visual) |
| `<leader>ghr` | Reset hunk (normal/visual) |
| `<leader>ghp` | Preview hunk |
| `<leader>ghb` | Blame line (full) |
| `<leader>ghd` | Diff this file |
| `<leader>gtb` | Toggle line blame |

---

## Terminal (`<leader>t`)

| Key | Action |
|-----|--------|
| `<C-\>` | Toggle last terminal (works from inside a terminal too) |
| `<leader>tt` | Terminal (float) |
| `<leader>th` | Terminal (horizontal split) |
| `<leader>tv` | Terminal (vertical split) |
| `<leader>t1` / `t2` / `t3` | Numbered terminals |
| `<leader>ta` | Toggle all terminals |
| `<leader>ts` (visual) | Send selection to terminal |
| `<leader>tl` | Send current line to terminal |
| `<leader>tn` | Node REPL |
| `<leader>tp` | Python REPL |

Inside a terminal: `<Esc><Esc>` to normal mode · `<C-h/j/k/l>` move between windows.

---

## Debug — DAP (`<leader>d`)

| Key | Action |
|-----|--------|
| `<leader>dc` | Continue / start debugging |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Toggle REPL |
| `<leader>dl` | Run last |
| `<leader>dt` | Terminate |
| `<leader>du` | Toggle DAP UI |
| `<leader>de` | Eval expression (normal/visual) |
| `<leader>dgt` | Debug Go test (Go files) |
| `<leader>dgl` | Debug last Go test (Go files) |

Adapters: Node/Chrome (web), Go (delve), PHP (Xdebug on port 9003).

---

## AI — Claude Code (`<leader>a`)

| Key | Action |
|-----|--------|
| `<leader>ac` | Toggle Claude pane |
| `<leader>af` | Focus Claude pane |
| `<leader>ar` | Resume previous Claude session |
| `<leader>aC` | Continue Claude session |
| `<leader>am` | Select Claude model |
| `<leader>ab` | Add current buffer as context |
| `<leader>as` (visual) | Send selection to Claude |
| `<leader>as` (in explorer) | Add file to context |
| `<leader>aa` | Accept proposed diff |
| `<leader>ad` | Deny proposed diff |

Diffs from Claude can also be accepted with `:w` or rejected with `:q`.

**Completion (Copilot flows through the blink.cmp menu):** `<C-space>` open menu · `<CR>` accept · `<Tab>`/`<S-Tab>` next/prev · `<C-j>`/`<C-k>` navigate.

---

## Buffers & UI

| Key | Action |
|-----|--------|
| `<leader>bd` | Delete buffer |
| `<leader>bD` | Delete all buffers |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Buffer switcher overlay, MRU order (cybu, VSCode-like) |
| `[b` / `]b` | Cycle buffers with overlay (positional) |
| `<leader>bp` / `<leader>bc` | Pick buffer / pick buffer to close |
| `<leader>bo` / `<leader>bl` / `<leader>br` | Close others / left / right |
| `<leader>bP` | Toggle pin tab |
| `<leader>b1`..`b5`, `<leader>b$` | Jump to tab N / last tab |
| `<leader>un` | Dismiss notifications |
| `<leader>l` | Open Lazy (plugin manager) |
| `<leader>?` | Show current buffer's keymaps |

---

## Surround (nvim-surround)

| Key | Action |
|-----|--------|
| `ys{motion}{char}` | Add surround (e.g. `ysiw"` → wrap word in quotes) |
| `ds{char}` | Delete surround |
| `cs{old}{new}` | Change surround |
| `S{char}` (visual) | Surround selection |
