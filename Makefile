# Dotfiles — symlink manager (labwc / dwl / Hyprland)
# Symlink config/<app> -> ~/.config/<app>. Repo = sumber kebenaran.
# Edit file di repo, perubahan langsung kepakai (via symlink), tanpa salin ulang.

# Lokasi repo = folder tempat Makefile ini berada (bukan hardcode ~/.dotfiles),
# jadi tetap benar walau di-clone ke folder mana pun.
DOTFILES := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
CONFIG   := $(HOME)/.config

# Dir di config/ yang di-symlink utuh ke ~/.config/
#
# `scripts` = powermenu + osd + osd-dwl-tag. Dipanggil ketiga compositor lewat
# path absolut ~/.config/scripts/..., jadi symlink-nya WAJIB ada — tanpa itu
# keybind power menu dan OSD tag dwl gagal tanpa pesan error apa pun.
DIRS := dwl foot fuzzel hypr labwc mako scripts sfwbar snappy-switcher swaylock waypaper xremap

# Tema labwc (Openbox-style) — di-symlink ke ~/.local/share/themes/
THEMES_SRC := $(DOTFILES)/config/labwc/themes
THEMES_DST := $(HOME)/.local/share/themes

.PHONY: help link unlink relink theme status

help:
	@echo "make link     symlink config/* -> ~/.config/ (backup dir asli ke *.bak)"
	@echo "make theme    symlink tema labwc -> ~/.local/share/themes/"
	@echo "make unlink   hapus semua symlink, restore *.bak kalau ada"
	@echo "make relink   unlink lalu link + theme ulang"
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

theme:
	@mkdir -p "$(THEMES_DST)"
	@for t in $(THEMES_SRC)/*/; do \
	  [ -d "$$t" ] || continue; \
	  src="$${t%/}"; name="$$(basename "$$src")"; dst="$(THEMES_DST)/$$name"; \
	  if [ -e "$$dst" ] && [ ! -L "$$dst" ]; then \
	    echo "backup  $$dst -> $$dst.bak"; mv "$$dst" "$$dst.bak"; \
	  fi; \
	  ln -sfn "$$src" "$$dst"; \
	  echo "theme   $$dst -> $$src"; \
	done

unlink:
	@for d in $(DIRS); do \
	  dst="$(CONFIG)/$$d"; \
	  if [ -L "$$dst" ]; then \
	    rm "$$dst"; echo "remove  $$dst"; \
	    if [ -e "$$dst.bak" ]; then mv "$$dst.bak" "$$dst"; echo "restore $$dst"; fi; \
	  fi; \
	done
	@for t in $(THEMES_SRC)/*/; do \
	  [ -d "$$t" ] || continue; \
	  dst="$(THEMES_DST)/$$(basename "$${t%/}")"; \
	  if [ -L "$$dst" ]; then rm "$$dst"; echo "remove  $$dst"; fi; \
	done

relink: unlink link theme

status:
	@for d in $(DIRS); do \
	  dst="$(CONFIG)/$$d"; \
	  if [ -L "$$dst" ]; then printf "%-22s -> %s\n" "$$d" "$$(readlink $$dst)"; \
	  elif [ -e "$$dst" ]; then printf "%-22s (dir asli, belum di-link)\n" "$$d"; \
	  else printf "%-22s (kosong)\n" "$$d"; fi; \
	done
	@for t in $(THEMES_SRC)/*/; do \
	  [ -d "$$t" ] || continue; \
	  name="$$(basename "$${t%/}")"; dst="$(THEMES_DST)/$$name"; \
	  if [ -L "$$dst" ]; then printf "theme:%-16s -> %s\n" "$$name" "$$(readlink $$dst)"; \
	  else printf "theme:%-16s (belum di-link)\n" "$$name"; fi; \
	done
