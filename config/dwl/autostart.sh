#!/bin/sh
# dwl autostart — dijalankan oleh dwl lewat: dwl -s ~/.config/dwl/autostart.sh
# Mirror config/labwc/autostart. Shared dgn labwc (xremap/waypaper/sfwbar sama).

lxpolkit &                             # polkit auth agent (udisks mount minta password)
xremap ~/.config/xremap/config.yml &   # Cmd->Ctrl remap (kalau via cargo: ~/.cargo/bin/xremap)
waypaper --restore &                   # restore wallpaper terakhir (backend swaybg)
sfwbar &                               # bar (launcher+taskbar+jam+status)
# CATATAN: sfwbar pager TAK melacak tags dwl (dwl pakai tags, bukan
# ext-workspace). Taskbar tetap jalan. Bar native tags dwl = dwlb (butuh fcft).
