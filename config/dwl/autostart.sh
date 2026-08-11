#!/bin/sh
# dwl autostart — dijalankan oleh dwl lewat: dwl -s ~/.config/dwl/autostart.sh
# Mirror config/labwc/autostart. Shared dgn labwc (xremap/waypaper/sfwbar sama).

# Java/JetBrains di WM non-reparenting (dwl/dwm) — cegah window blank/abu-abu
# saat pakai XToolkit (XWayland). Kena ke semua app yg dilaunch dari sesi ini
# (fuzzel/sfwbar = child dwl). Launch dari luar sesi: taruh juga di ~/.profile.
export _JAVA_AWT_WM_NONREPARENTING=1

# --- Bunuh helper sisa sesi sebelumnya ---------------------------------------
# Helper yang pernah dilaunch detached (setsid/nohup, mis. dari sesi Claude)
# TIDAK mati saat logout. Yang paling merusak: **dua xremap**. Keduanya
# EVIOCGRAB keyboard yang sama dan masing-masing bikin virtual keyboard, jadi
# key event kembar/hilang dan modifier nyangkut. Super yang dianggap masih
# ditekan membuat BTN_LEFT kena bind `moveresize` (config.h buttons[]), dan
# buttonpress() `return` sebelum wlr_seat_pointer_notify_button() — **klik
# ditelan compositor tanpa gejala lain**. Sembuh sendiri saat key state resync
# (buka app baru / ganti tag), itu sebabnya gejalanya intermiten.
# Tradeoff: kalau ada sesi WM kedua hidup di TTY lain, helper-nya ikut mati.
# Diterima — satu sesi per waktu lewat SDDM.
for p in xremap sfwbar mako swaybg lxpolkit; do pkill -x "$p"; done
pkill -f 'wsctl watch'
sleep 0.3

lxpolkit &                           # polkit auth agent (udisks mount minta password)
xremap ~/.config/xremap/config.yml &   # Cmd->Ctrl remap (kalau via cargo: ~/.cargo/bin/xremap)
waypaper --restore &                   # restore wallpaper terakhir (backend swaybg)
sfwbar &                               # bar (launcher+taskbar+jam+status)
mako &                                 # notification daemon (toast kanan-atas + OSD tag)

# Entri XDG autostart (.desktop) — nm-applet, blueman, spice-vdagent, slack, dst.
# Daftar yang dibuang ada di ~/.config/scripts/xdg-autostart.skip.
# XDG_CURRENT_DESKTOP di-set INLINE, bukan export: dwl tak menyetelnya sama
# sekali, dan membiarkannya kosong untuk sisa sesi disengaja — pemilihan backend
# xdg-desktop-portal dan fallback `pgrep` di sfwbar/wsctl bergantung pada itu.
# Filter OnlyShowIn/NotShowIn butuh nilai, jadi cuma script ini yang menerimanya.
XDG_CURRENT_DESKTOP=wlroots:dwl ~/.config/scripts/xdg-autostart &
# CATATAN: pager sfwbar melacak tag dwl lewat `wsctl mark` yang dipanggil dari
# loop paling bawah — dwl tak punya IPC, jadi stdout-nya satu-satunya sumber.
# Klik pager butuh `wtype` (sintesis Super+N); tanpa wtype highlight tetap benar,
# cuma kliknya yang mati. Bar native tags dwl = dwlb (butuh fcft).
# Tag aktif juga ditampilkan lewat OSD di loop yang sama.

# --- OSD tag + pager sfwbar --------------------------------------------------
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
		# Pager sfwbar: bitmask -> nomor tag terendah yang menyala.
		# `wsctl mark` cuma menulis state file, tak memicu perpindahan —
		# jadi tak ada loop umpan-balik dgn keybind dwl. Toggleview
		# (Ctrl+Super+N) bisa menyalakan >1 tag; pager cuma bisa menandai
		# satu, dan yang terendah = pilihan yang stabil.
		n=1
		while [ "$n" -le 9 ]; do
			if [ "$(((b >> (n - 1)) & 1))" = 1 ]; then
				~/.config/sfwbar/wsctl mark "$n"
				break
			fi
			n=$((n + 1))
		done
		;;
	esac
done
