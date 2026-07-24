# Dotfiles — symlink manager (labwc / dwl / Hyprland)
# Symlink config/<app> -> ~/.config/<app>. Repo = sumber kebenaran.
# Edit file di repo, perubahan langsung kepakai (via symlink), tanpa salin ulang.

# Lokasi repo = folder tempat Makefile ini berada (bukan hardcode ~/.dotfiles),
# jadi tetap benar walau di-clone ke folder mana pun.
DOTFILES := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
CONFIG   := $(HOME)/.config

# Dir di config/ yang di-symlink utuh ke ~/.config/
DIRS := foot fuzzel hypr labwc sfwbar waypaper xremap

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
	@# Hyprland `source = ~/.config/hypr/local.conf` error kalau file tak ada.
	@# Bikin kosong (sekali) — isinya override per-mesin, tak di-track git.
	@[ -f "$(DOTFILES)/config/hypr/local.conf" ] || { \
	  printf '%s\n' \
	    '# Override per-mesin — TIDAK di-track git.' \
	    '# Tulis `monitor = ...` di sini untuk multi-monitor / skala khusus.' \
	    '# Contoh:' \
	    '#   monitor = eDP-1,   1920x1080@60, 0x0,    1' \
	    '#   monitor = HDMI-A-1,1920x1080@60, 1920x0, 1' \
	    > "$(DOTFILES)/config/hypr/local.conf"; \
	  echo "create  config/hypr/local.conf (override per-mesin)"; }
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
