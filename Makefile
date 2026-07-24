# Dotfiles — symlink manager (labwc setup)
# Symlink config/<app> -> ~/.config/<app>. Repo = sumber kebenaran.
# Edit file di repo, perubahan langsung kepakai (via symlink), tanpa salin ulang.

# Lokasi repo = folder tempat Makefile ini berada (bukan hardcode ~/.dotfiles),
# jadi tetap benar walau di-clone ke folder mana pun.
DOTFILES := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
CONFIG   := $(HOME)/.config

# Dir di config/ yang di-symlink utuh ke ~/.config/
DIRS := foot fuzzel labwc sfwbar waypaper xremap

.PHONY: help link unlink relink status

help:
	@echo "make link     symlink config/* -> ~/.config/ (backup dir asli ke *.bak)"
	@echo "make unlink   hapus symlink, restore *.bak kalau ada"
	@echo "make relink   unlink lalu link ulang"
	@echo "make status   tampilkan status tiap symlink"

link:
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
