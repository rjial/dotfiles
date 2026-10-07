# .zshrc — zsh interaktif. Repo dotfiles = sumber kebenaran
# (~/.zshrc di-symlink ke file ini lewat `make link`).
# TANPA plugin manager: paket zsh di-source langsung dari /usr/share/.

# ls berwarna
alias ls='ls --color=auto'

# Prompt ala bash: [\u@\h \W]\$  ->  [%n@%m %1~]%#
PROMPT='[%n@%m %1~]%# '

export PATH=$PATH:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/.local/bin
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# pnpm
export PNPM_HOME='/home/rjial/.local/share/pnpm'
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# Sistem completion zsh — _git (branch, remote, subcommand, path) sudah
# dibundel di paket zsh Void (/usr/share/zsh/functions/Completion/Unix/_git),
# cukup diaktifkan lewat compinit, tanpa plugin tambahan.
autoload -Uz compinit
compinit

# --- Jump & seleksi ala macOS (di baris perintah zsh) --------------------
# Di macOS: Option+panah = lompat kata, Cmd+panah = awal/akhir baris. Karena
# Super+panah di Hyprland dipakai fokus window (lihat CLAUDE.md), peran
# Cmd+panah diemulasikan dengan Ctrl+panah; Option = Alt apa adanya.
#   Option+Left/Right      -> Alt+Left/Right          lompat kata
#   Cmd+Left/Right         -> Ctrl+Left/Right         awal/akhir baris
#   Cmd+Up/Down            -> Ctrl+Up/Down            awal/akhir buffer
#   Shift+Left/Right       -> (sama)                  seleksi per karakter
#   Shift+Option+Left/Right-> Shift+Alt+Left/Right    seleksi per kata
#   Shift+Cmd+Left/Right   -> Shift+Ctrl+Left/Right   seleksi ke awal/akhir baris
#   Shift+Cmd+Up/Down      -> Shift+Ctrl+Up/Down      seleksi ke awal/akhir buffer
# Mengetik mengganti seleksi; Backspace/Delete menghapusnya; widget lain
# (panah polos, Enter, dsb) membatalkan seleksi.
# Urutan tombol xterm-style modifier (2=Shift 3=Alt 4=Shift+Alt 5=Ctrl
# 6=Ctrl+Shift) — persis yang dikirim foot utk panah/Home/End.

# Mode editing vim penuh: i/a/o = insert, Esc = normal (vicmd), operator vim
# (d/c/y/p/x, 0/$/w/b, dd, cw, ...) berlaku di normal mode. Konsekuensinya
# binding emacs bawaan (Ctrl+A/E/U dsb) hilang — pakai padanan vim-nya.
bindkey -v

typeset -g ZLE_SEL=

function zle-sel-begin  { [[ -n $ZLE_SEL ]] || ZLE_SEL=$CURSOR }
function zle-sel-clear  { ZLE_SEL=; region_highlight=() }
function zle-sel-draw   {
  if [[ -n $ZLE_SEL ]]; then
    local a=$ZLE_SEL b=$CURSOR
    (( a > b )) && { local t=$a; a=$b; b=$t }
    region_highlight=("$a:$b:standout")
  fi
}
function zle-sel-remove {
  # hapus teks di region; return 1 kalau seleksi tak ada/kosong
  [[ -n $ZLE_SEL ]] || return 1
  local a=$ZLE_SEL b=$CURSOR
  (( a > b )) && { local t=$a; a=$b; b=$t }
  (( a == b )) && { zle-sel-clear; return 1 }
  BUFFER="$BUFFER[1,$((a-1))]$BUFFER[$((b+1)),-1]"
  CURSOR=$a
  zle-sel-clear
}

# alias ke widget bawaan — supaya widget pembungkus tak rekursif
zle -A backward-word        zle-builtin-backward-word
zle -A forward-word         zle-builtin-forward-word
zle -A self-insert          zle-builtin-self-insert
zle -A backward-delete-char zle-builtin-backward-delete-char
zle -A delete-char          zle-builtin-delete-char

function zle-sel-backward-char { zle-sel-begin; (( CURSOR > 0 )) && (( CURSOR-- )); zle-sel-draw }
function zle-sel-forward-char  { zle-sel-begin; (( CURSOR < ${#BUFFER} )) && (( CURSOR++ )); zle-sel-draw }
function zle-sel-backward-word { zle-sel-begin; zle zle-builtin-backward-word; zle-sel-draw }
function zle-sel-forward-word  { zle-sel-begin; zle zle-builtin-forward-word;  zle-sel-draw }
function zle-sel-bol           { zle-sel-begin; zle zle-builtin-beginning-of-line; zle-sel-draw }
function zle-sel-eol           { zle-sel-begin; zle zle-builtin-end-of-line;       zle-sel-draw }
function zle-sel-buf-bol       { zle-sel-begin; CURSOR=0; zle-sel-draw }
function zle-sel-buf-eol       { zle-sel-begin; CURSOR=${#BUFFER}; zle-sel-draw }

# daftarkan sbg widget ZLE (fungsi polos BUKAN widget — tanpa ini muncul
# "No such widget" saat tombol ditekan)
zle -N zle-sel-backward-char
zle -N zle-sel-forward-char
zle -N zle-sel-backward-word
zle -N zle-sel-forward-word
zle -N zle-sel-bol
zle -N zle-sel-eol
zle -N zle-sel-buf-bol
zle -N zle-sel-buf-eol

# ketik & hapus bertindak atas seleksi (ganti/hapus region), ala editor
function zle-edit-self-insert {
  zle-sel-remove || zle-sel-clear
  zle zle-builtin-self-insert
}
function zle-edit-backward-delete-char {
  zle-sel-remove || { zle-sel-clear; zle zle-builtin-backward-delete-char }
}
function zle-edit-delete-char {
  zle-sel-remove || { zle-sel-clear; zle zle-builtin-delete-char }
}
zle -N self-insert          zle-edit-self-insert
zle -N backward-delete-char zle-edit-backward-delete-char
zle -N delete-char          zle-edit-delete-char

# widget lain cukup membatalkan seleksi lalu lanjut ke widget asli
for zle_w in quoted-insert backward-char forward-char backward-word forward-word \
             beginning-of-line end-of-line beginning-of-buffer-or-history \
             end-of-buffer-or-history accept-line kill-line backward-kill-line \
             up-line-or-history down-line-or-history yank yank-pop undo \
             kill-region copy-region-as-kill \
             vi-cmd-mode vi-insert vi-insert-bol vi-delete vi-delete-char \
             vi-change vi-change-eol vi-yank vi-put-after vi-put-before \
             vi-replace; do
  zle -A "$zle_w" "zle-builtin-$zle_w" 2>/dev/null || continue
  eval "function zle-edit-$zle_w() { zle-sel-clear; zle zle-builtin-$zle_w }"
  zle -N "$zle_w" "zle-edit-$zle_w"
done
unset zle_w

# keymap macOS-like — dipasang di insert mode (viins) DAN normal mode (vicmd);
# bare `bindkey` setelah `bindkey -v` hanya mengikat ke viins.
for zle_km in viins vicmd; do
  bindkey -M "$zle_km" '^[[1;3D' backward-word                  # Alt+Left   lompat kata (Option+←)
  bindkey -M "$zle_km" '^[[1;3C' forward-word                   # Alt+Right  (Option+→)
  bindkey -M "$zle_km" '^[[1;5D' beginning-of-line              # Ctrl+Left  awal baris (pengganti Cmd+←)
  bindkey -M "$zle_km" '^[[1;5C' end-of-line                    # Ctrl+Right akhir baris
  bindkey -M "$zle_km" '^[[1;5A' beginning-of-buffer-or-history # Ctrl+Up    awal buffer (pengganti Cmd+↑)
  bindkey -M "$zle_km" '^[[1;5B' end-of-buffer-or-history       # Ctrl+Down  akhir buffer
  bindkey -M "$zle_km" '^[[1;2D' zle-sel-backward-char          # Shift+Left  seleksi per karakter
  bindkey -M "$zle_km" '^[[1;2C' zle-sel-forward-char           # Shift+Right
  bindkey -M "$zle_km" '^[[1;4D' zle-sel-backward-word          # Shift+Alt+Left  seleksi per kata
  bindkey -M "$zle_km" '^[[1;4C' zle-sel-forward-word           # Shift+Alt+Right
  bindkey -M "$zle_km" '^[[1;6D' zle-sel-bol                    # Shift+Ctrl+Left  seleksi ke awal baris
  bindkey -M "$zle_km" '^[[1;6C' zle-sel-eol                    # Shift+Ctrl+Right seleksi ke akhir baris
  bindkey -M "$zle_km" '^[[1;6A' zle-sel-buf-bol                # Shift+Ctrl+Up    seleksi ke awal buffer
  bindkey -M "$zle_km" '^[[1;6B' zle-sel-buf-eol                # Shift+Ctrl+Down  seleksi ke akhir buffer
  bindkey -M "$zle_km" '^[[1;2H' zle-sel-bol                    # Shift+Home
  bindkey -M "$zle_km" '^[[1;2F' zle-sel-eol                    # Shift+End
done
unset zle_km

# --- Prompt kanan (RPROMPT): info project + indikator mode vi ----------------
# Bagian dinamis (dihitung tiap prompt lewat precmd):
#   - branch git + tanda `*` kalau ada perubahan belum ter-commit (kotor)
#   - versi node.js (vX.Y.Z) hanya di dalam project Node.js, yaitu ada
#     package.json di direktori ini atau salah satu direktori induknya
# Bagian statis: indikator mode INSERT/NORMAL/VISUAL, diperbarui oleh
# zle-keymap-select (widget itu dipanggil zsh otomatis tiap keymap berganti:
# Esc, i, v, ...). zle reset-prompt = prompt tergambar ulang seketika.
typeset -g ZLE_MODE_IND='%F{blue}-- INSERT --%f'  # default saat shell mulai = insert
typeset -g ZLE_RPROMPT_INFO=
typeset -g ZLE_NODE_VER=                         # cache — node jarang berganti
typeset -g RPROMPT=$ZLE_MODE_IND

function zsh-rprompt-info {
  local info= dir=$PWD
  # git: branch (detached HEAD -> short SHA) + tanda * kalau kotor
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
      || branch=$(git rev-parse --short HEAD 2>/dev/null)
    [[ -n $(git status --porcelain 2>/dev/null) ]] && branch+='*'
    info="%F{cyan}${branch}%f"
  fi
  # node: cari package.json dari PWD ke atas (subdir monorepo ikut terdeteksi)
  while [[ $dir != / ]]; do
    if [[ -f $dir/package.json ]]; then
      [[ -n $ZLE_NODE_VER ]] || ZLE_NODE_VER=$(node -v 2>/dev/null)
      info+="${info:+ }%F{green}${ZLE_NODE_VER}%f"
      break
    fi
    dir=${dir:h}
  done
  ZLE_RPROMPT_INFO=$info
  RPROMPT="$ZLE_RPROMPT_INFO${ZLE_RPROMPT_INFO:+ }$ZLE_MODE_IND"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd zsh-rprompt-info

function zle-keymap-select {
  case $KEYMAP in
    vicmd)       ZLE_MODE_IND='%F{yellow}-- NORMAL --%f' ;;
    vivis|vivli) ZLE_MODE_IND='%F{magenta}-- VISUAL --%f' ;;
    *)           ZLE_MODE_IND='%F{blue}-- INSERT --%f' ;;
  esac
  RPROMPT="$ZLE_RPROMPT_INFO${ZLE_RPROMPT_INFO:+ }$ZLE_MODE_IND"
  zle reset-prompt
}
zle -N zle-keymap-select

# zsh-autosuggestions + zsh-syntax-highlighting (paket Void) — keduanya sekadar
# skrip yang di-source, bukan plugin manager. Void memasangnya di
# /usr/share/zsh/plugins/<nama>/ (bukan /usr/share/<nama>/ seperti distro lain).
# zsh-syntax-highlighting WAJIB paling akhir: dia mendaftarkan widget zle dan
# harus di-source setelah kustomisasi zle lain (termasuk autosuggestions).
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
