# Dotfiles — symlink manager (Hyprland, Void Linux)
# Symlink config/<app> -> ~/.config/<app>. Repo = sumber kebenaran.
# Edit file di repo, perubahan langsung kepakai (via symlink), tanpa salin ulang.

# Lokasi repo = folder tempat Makefile ini berada (bukan hardcode ~/.dotfiles),
# jadi tetap benar walau di-clone ke folder mana pun.
DOTFILES := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
CONFIG   := $(HOME)/.config

# Dir di config/ yang di-symlink utuh ke ~/.config/
#
# `scripts` = powermenu + osd + fastfetch-panel. Dipanggil lewat path absolut
# ~/.config/scripts/..., jadi symlink-nya WAJIB ada — tanpa itu keybind power
# menu dan autostart panel fastfetch gagal tanpa pesan error apa pun.
DIRS := fastfetch foot fuzzel hypr mako scripts sfwbar snappy-switcher swaylock waypaper xremap

.PHONY: help link unlink relink status

help:
	@echo "make link     symlink config/* -> ~/.config/ (backup dir asli ke *.bak)"
	@echo "make unlink   hapus semua symlink, restore *.bak kalau ada"
	@echo "make relink   unlink lalu link ulang"
	@echo "make status   tampilkan status tiap symlink"

link:
	@# Override per-mesin untuk config Lua Hyprland. hyprland.lua memeriksa
	@# keberadaan file ini sebelum dofile(), jadi absennya tak fatal — tetap
	@# dibuat supaya jelas di mana tempat menulis override. Tak di-track git.
	@[ -f "$(DOTFILES)/config/hypr/local.lua" ] || { \
	  printf '%s\n' \
	    '-- Override per-mesin — TIDAK di-track git.' \
	    '-- Contoh monitor ganda:' \
	    '--   hl.monitor({ output = "eDP-1",    mode = "1920x1080@60", position = "0x0",    scale = 1 })' \
	    '--   hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = 1 })' \
	    '-- Contoh posisi PiP untuk resolusi selain 1920x1080 (rule belakangan menang):' \
	    '--   hl.window_rule({ name = "pip-local",' \
	    '--       match = { title = "^([Pp]icture[- ][Ii]n[- ][Pp]icture)$$" },' \
	    '--       move  = "1000 500" })' \
	    '-- Contoh posisi panel fastfetch untuk resolusi selain 1920x1080:' \
	    '--   hl.window_rule({ name = "fastfetch-panel-local",' \
	    '--       match = { class = "^(fastfetch-panel)$$" },' \
	    '--       move  = "40 500" })' \
	    > "$(DOTFILES)/config/hypr/local.lua"; \
	  echo "create  config/hypr/local.lua (override per-mesin)"; }
	@for d in $(DIRS); do \
	  src="$(DOTFILES)/config/$$d"; dst="$(CONFIG)/$$d"; \
	  if [ -e "$$dst" ] && [ ! -L "$$dst" ]; then \
	    echo "backup  $$dst -> $$dst.bak"; mv "$$dst" "$$dst.bak"; \
	  fi; \
	  ln -sfn "$$src" "$$dst"; \
	  echo "link    $$dst -> $$src"; \
	done

unlink:
	@for d in $(DIRS); do \
	  dst="$(CONFIG)/$$d"; \
	  if [ -L "$$dst" ]; then \
	    rm "$$dst"; echo "remove  $$dst"; \
	    if [ -e "$$dst.bak" ]; then mv "$$dst.bak" "$$dst"; echo "restore $$dst"; fi; \
	  fi; \
	done

relink: unlink link

status:
	@for d in $(DIRS); do \
	  dst="$(CONFIG)/$$d"; \
	  if [ -L "$$dst" ]; then printf "%-22s -> %s\n" "$$d" "$$(readlink $$dst)"; \
	  elif [ -e "$$dst" ]; then printf "%-22s (dir asli, belum di-link)\n" "$$d"; \
	  else printf "%-22s (kosong)\n" "$$d"; fi; \
	done
