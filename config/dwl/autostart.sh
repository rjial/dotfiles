#!/bin/sh
# dwl autostart — dijalankan oleh dwl lewat: dwl -s ~/.config/dwl/autostart.sh
# Mirror config/labwc/autostart. Shared dgn labwc (xremap/waypaper/sfwbar sama).

# Java/JetBrains di WM non-reparenting (dwl/dwm) — cegah window blank/abu-abu
# saat pakai XToolkit (XWayland). Kena ke semua app yg dilaunch dari sesi ini
# (fuzzel/sfwbar = child dwl). Launch dari luar sesi: taruh juga di ~/.profile.
export _JAVA_AWT_WM_NONREPARENTING=1

lxpolkit &                             # polkit auth agent (udisks mount minta password)
xremap ~/.config/xremap/config.yml &   # Cmd->Ctrl remap (kalau via cargo: ~/.cargo/bin/xremap)
waypaper --restore &                   # restore wallpaper terakhir (backend swaybg)
sfwbar &                               # bar (launcher+taskbar+jam+status)
mako &                                 # notification daemon (toast kanan-atas + OSD tag)
# CATATAN: sfwbar pager TAK melacak tags dwl (dwl pakai tags, bukan
# ext-workspace). Taskbar tetap jalan. Bar native tags dwl = dwlb (butuh fcft).
# Sebagai ganti pager, tag aktif ditampilkan lewat OSD di loop paling bawah.

# --- OSD tag ----------------------------------------------------------------
# dwl mem-pipe stdout-nya ke STDIN script ini (dwl.c:2254-2271), jadi status
# tag sudah mengalir ke sini tanpa perlu bar atau patch dwl.c apa pun. Sebelum
# ada loop ini tak ada yang membacanya, dan baris-baris itu dibuang begitu saja
# (dwl menandai stdout non-blocking di dwl.c:2277 supaya tak freeze).
#
# printstatus() (dwl.c:2089-2125) mengirim per-monitor, urut:
#   <out> title|appid|fullscreen|floating <nilai>
#   <out> selmon <0|1>
#   <out> tags <occupied> <selected> <clienttags> <urgent>
#   <out> layout <simbol>
# `selmon` selalu mendahului `tags` untuk monitor yang sama, jadi aman memakai
# baris selmon sebagai penanda monitor mana yang sedang dipakai.
#
# Dua guard yang WAJIB ada:
#   1. filter selmon — multi-monitor mengirim satu blok per output; tanpa filter
#      OSD ikut menampilkan tag monitor yang tidak aktif.
#   2. dedupe $last — printstatus() juga dipanggil dari focusclient, setlayout
#      (dwl.c:2703) dan urgent (dwl.c:2965), jadi tanpa dedupe OSD muncul tiap
#      ganti fokus window walau tag tak berubah.
#
# Loop ini BLOCKING, jadi harus paling bawah. Saat dwl keluar, pipe tertutup,
# `read` gagal, dan script ikut selesai.
#
# Efek samping yang disengaja: perubahan tag dari sumber non-keybind (klik
# taskbar sfwbar, window rule) juga memicu OSD — hal yang tak bisa dilakukan
# kalau OSD dipanggil lewat `spawn` dari config.h.
last=''
active=''
while read -r out key a b _rest; do
	case $key in
	selmon)
		[ "$a" = 1 ] && active=$out
		;;
	tags)
		[ "$out" = "$active" ] || continue
		[ "$b" = "$last" ] && continue
		last=$b
		~/.config/scripts/osd-dwl-tag "$b"
		;;
	esac
done
