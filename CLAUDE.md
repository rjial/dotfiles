# CLAUDE.md — macOS-style Config Deployment (labwc / dwl / Hyprland)

> **Untuk sesi Claude Code yang berjalan di mesin Fedora 42 milik user (rjial).**
> Sesi ini punya akses langsung ke `~/.config/`, `dnf`, dan compositor-nya. Repo
> ini berisi config siap-pakai untuk tiga compositor; tugasmu adalah men-deploy-nya
> ke mesin ini dan memandu setup sampai shortcut ala macOS berfungsi.
>
> Bagian utama di bawah = **labwc** (sesi default). Migrasi **dwl** dan sesi
> **Hyprland** ada di dua section terakhir file ini.

## Apa isi repo ini

Config labwc (Wayland WM) dengan shortcut ala macOS. `Super` = tombol **Cmd**.
`xremap` me-remap huruf shortcut aplikasi (`Super+c/v/x/s/z/…`) menjadi `Ctrl+`
supaya aplikasi GUI terasa mac-like; tombol window-management
(`Super+q/m/h/space/tab/grave/arrows/digits`) diteruskan ke labwc. Launcher =
**fuzzel** (Spotlight), terminal = **foot** (dengan smart copy: Cmd+C = copy,
Ctrl+C asli = SIGINT).

```
config/
  xremap/config.yml    # engine remap Cmd->Ctrl (blok foot HARUS pertama)
  labwc/rc.xml         # keybind window-management + sistem
  labwc/autostart      # jalankan xremap + swaybg
  labwc/environment    # env var sesi
  labwc/menu.xml       # menu klik-kanan (+ submenu Power)
  hypr/hyprland.lua    # sesi Hyprland (keybind+env+autostart+efek, satu file)
  hypr/hyprland.conf.bak # bekas config .conf — INERT, jalur mundur saja
  dwl/config.h         # keybind dwl (compiled in — recompile tiap ubah)
  dwl/config.mk        # flag build dwl (XWayland ON) — recompile tiap ubah
  dwl/autostart.sh     # startup dwl + loop stdin OSD tag
  snappy-switcher/     # overlay Alt+Tab (HANYA Hyprland, butuh IPC-nya)
  mako/config          # notification daemon + blok [category=osd] (ketiga WM)
  scripts/powermenu    # power menu fuzzel (ketiga WM)
  scripts/osd          # renderer OSD generik lewat mako (ketiga WM)
  scripts/osd-dwl-tag  # bitmask tag dwl -> teks OSD (dwl saja)
  swaylock/config      # tema lock screen (ketiga WM)
  foot/foot.ini        # terminal
  fuzzel/fuzzel.ini    # launcher
README.md              # dokumentasi lengkap (rujukan)
```

`make link` mem-symlink dir di `DIRS` (`Makefile:11`) utuh ke `~/.config/`.
Menambah **dir baru** di `config/` WAJIB ditambah ke `DIRS` juga — file baru di
dalam dir yang sudah ter-symlink langsung hidup tanpa ubah Makefile.

## Tugas deploy (jalankan berurutan, konfirmasi ke user di tiap langkah sudo)

### 1. Install paket
```bash
sudo dnf install labwc fuzzel foot grim slurp swaybg wl-clipboard mako swaylock
```
xremap TIDAK ada di repo Fedora. Coba COPR dulu:
```bash
dnf copr search xremap                 # verifikasi slug tersedia
sudo dnf copr enable emd/xremap
sudo dnf install xremap-wlroots        # WAJIB varian wlroots (labwc = wlroots)
```
Kalau COPR tidak ada, pakai cargo (lalu edit `config/labwc/autostart` agar
memanggil `~/.cargo/bin/xremap`):
```bash
sudo dnf install cargo
cargo install xremap --features wlroots
```

### 2. Izin uinput (xremap inject event tanpa root)
```bash
sudo usermod -aG input $USER
echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' \
  | sudo tee /etc/udev/rules.d/99-uinput.rules
echo uinput | sudo tee /etc/modules-load.d/uinput.conf
sudo modprobe uinput
```
> Keanggotaan grup `input` baru aktif setelah **logout/reboot**. Ingatkan user.

### 3. Salin config ke ~/.config/
```bash
mkdir -p ~/Pictures
cp -r config/* ~/.config/
```
Jangan timpa config existing tanpa konfirmasi — cek `ls ~/.config/labwc` dulu;
kalau sudah ada isinya, tanyakan ke user apakah mau di-backup atau di-merge.

### 4. Jalankan & verifikasi
- Start dari TTY: `dbus-run-session labwc` — atau pilih sesi **labwc** di SDDM.
- Saat iterasi: `labwc --reconfigure` reload `rc.xml` tanpa restart.

Checklist verifikasi:
1. `pgrep xremap` → jalan.
2. GUI copy: fokus field teks di browser → **Super+C / Super+V**.
3. Smart terminal: di foot, seleksi teks → **Super+C** copy; jalankan `sleep 100`
   → **Ctrl+C** interrupt (SIGINT). Membuktikan rule per-app aktif.
4. Window: **Super+Space** buka fuzzel; **Super+Q** close; **Super+Left/Right**
   snap; **Super+1/2** ganti workspace; **Super+Shift+4** screenshot region ke
   `~/Pictures`.

## Tradeoff yang disengaja (bukan bug)
- **Cmd+panah (navigasi teks) dihilangkan** — panah dipakai snap window labwc.
  Home/End native tetap jalan; bisa ditambah lewat xremap nanti bila diminta.
- **Cmd+1..9 (tab browser) dihilangkan** — digit untuk ganti workspace. Pakai Ctrl+Tab.
- **Tidak ada Mission Control/Exposé** — labwc tidak punya window-overview native.
- **Cmd+W** = close-tab aplikasi (`Ctrl+W`); tutup window = **Cmd+Q**.

## Catatan
- Jangan commit/push kecuali user memintanya.
- Kalau user memodifikasi keybind, edit file di `config/` (sumber kebenaran),
  lalu salin ulang ke `~/.config/` dan `labwc --reconfigure`.

---

# Migrasi ke dwl (tiling) — opsional

User ingin opsi tiling. labwc = stacking/floating (cuma snap manual, tak ada
auto-tile). Alternatif tiling wlroots = **dwl** (dwm-for-wayland). Konsekuensi:

- **Tak ada config runtime** — semua di `config.h`, harus **compile dari source**.
  Tiap ubah keybind = **recompile** (`make && sudo make install`). Tak ada
  `--reconfigure`.
- dwl pakai **tags** (dwm-style), BUKAN workspace/ext-workspace. Konsekuensi:
  **sfwbar pager tak melacak tags dwl**. Taskbar (foreign-toplevel) tetap jalan.
  Bar native dwl = **dwlb** (baca stdout dwl: tags + layout + title).
- xremap tetap dipakai apa adanya — dwl support foreign-toplevel jadi deteksi
  app (blok `foot`) tetap jalan.

## Toolchain: clang/LLVM

`cc` di Fedora = symlink gcc. Paksa clang via `CC=clang`. Compiler kerja berat
ada di **wlroots** (shared lib, TAK di-recompile) — optimasi flag ke dwl.c
efeknya nyaris nol untuk runtime. Tetap dicatat karena user memintanya.

### 1. Install build deps (manual, sudo)
```bash
sudo dnf install clang make pkgconf-pkg-config lld \
  wlroots-devel wayland-devel wayland-protocols-devel \
  libinput-devel libxkbcommon-devel pixman-devel libdrm-devel
# bar native dwl (opsional):
sudo dnf install fcft-devel
```
> wlroots runtime terpasang = **0.19.2** → pakai dwl branch **main** (target 0.19).
> dwl rilis 0.7 target wlroots 0.18 (JANGAN, versi beda).

### 2. Clone
Clone yang SUDAH ADA di mesin ini: **`~/Dokumen/dwl`** (bukan `~/src/dwl`).
Pakai itu, jangan clone ulang.
```bash
# kalau belum ada:
git clone https://codeberg.org/dwl/dwl ~/Dokumen/dwl
git clone https://github.com/kolunmi/dwlb ~/Dokumen/dwlb   # kalau pakai dwlb
```

### 2b. XWayland WAJIB aktif — `config.mk`
Default dwl upstream mematikan XWayland (`XWAYLAND =` kosong). Di mesin ini itu
membuat **`DISPLAY` tak diset**, sehingga `lxpolkit` (GTK X11-only) mati dgn
`cannot open display` dan autostart kehilangan agent polkit — plus semua app X11
(JetBrains, Electron lama) tak bisa jalan. `config/dwl/config.mk` di repo sudah
mengaktifkannya:
```make
XWAYLAND = -DXWAYLAND
XLIBS = xcb xcb-icccm
```
Dep: `libxcb-devel xcb-util-wm-devel xorg-x11-server-Xwayland` (sudah terpasang);
wlroots Fedora punya `WLR_HAS_XWAYLAND 1`, cek:
`grep XWAYLAND /usr/include/wlroots-0.19/wlr/config.h`.
Verifikasi setelah relog: `pgrep -a Xwayland` dan `echo $DISPLAY` (Xwayland lazy —
baru spawn saat ada klien X pertama, tapi `DISPLAY` sudah diset sejak setup).

### 3. Compile dgn optimasi LLVM
dwl Makefile taruh include (`pkg-config`) di `DWLCFLAGS` terpisah → override
`CFLAGS` di command line aman, tak buang include.
```bash
make CC=clang \
  CFLAGS="-O3 -march=native -mtune=native -pipe -flto=thin -fuse-ld=lld -DNDEBUG" \
  LDFLAGS="-flto=thin -fuse-ld=lld"
sudo make install
```
Arti: `-O3` agresif; `-march/-mtune=native` instruksi CPU mesin ini (tak
portable); `-flto=thin` ThinLTO khas LLVM; `-fuse-ld=lld` linker LLVM (wajib
buat LTO clang); `-DNDEBUG` buang assert; `-pipe` kompilasi lebih cepat.
Opsional kecilkan biner: `strip $(which dwl)`.

## Yg harus ditulis (setelah paket + clone beres)
1. `~/Dokumen/dwl/config.h` — mirror keybind labwc `rc.xml`:
   - MODKEY = Super (Cmd). Snap → tag/layout dwl. Screenshot (grim/slurp),
     media key (wpctl), launcher fuzzel, terminal foot.
   - Digit 1-9 = tags (bukan workspace). Tetap SISAKAN huruf shortcut app
     (c/v/x/s/z/…) untuk xremap — jangan bind di dwl.
2. `config/dwl/` di repo — salinan `config.h`, autostart, config dwlb (sumber
   kebenaran, sama pola seperti `config/labwc/`).
3. autostart dwl: `lxpolkit`, `xremap`, `waypaper --restore`, bar (`dwlb` atau
   `sfwbar`), `mako` — dwl jalankan lewat flag `-s` (startup command) atau script.

## OSD tag dwl — loop stdin di `autostart.sh`

dwl mem-`pipe()` stdout-nya ke **stdin** script `-s` (`dwl.c:2254-2271`), dan
`printstatus()` (`dwl.c:2089-2125`) menulis ke stdout **tanpa syarat** — ini
bagian dwl inti, TIDAK butuh dwlb. dwlb hanya salah satu konsumen stdout itu.
Format per-monitor, urut: `title`, `appid`, `fullscreen`, `floating`, `selmon`,
`tags <occ> <selected> <clienttags> <urg>`, `layout`.

Loop di ujung `config/dwl/autostart.sh` membaca itu dan memanggil
`config/scripts/osd-dwl-tag`. Aturan yang mudah dilanggar:

- **Loop WAJIB paling bawah** — ia blocking. Semua daemon harus `&` di atasnya.
- **Filter `selmon`** — multi-monitor mengirim satu blok per output; tanpa filter
  OSD menampilkan tag monitor yang tidak aktif. `selmon` selalu mendahului `tags`
  untuk monitor yang sama, jadi aman dipakai sebagai penanda.
- **Dedupe nilai `tags` sebelumnya** — `printstatus()` juga dipanggil dari
  `focusclient`, `setlayout` (`dwl.c:2703`), `urgent` (`dwl.c:2965`). Tanpa
  dedupe, OSD muncul tiap ganti fokus window.
- **stdout dwl cuma boleh SATU konsumen.** Kalau dwlb dipasang nanti,
  `autostart.sh` harus `tee` ke dwlb — bukan dua proses baca stdin bersamaan.
- Kalau loop berhenti membaca, dwl tetap aman (stdout non-blocking,
  `dwl.c:2277`) tapi OSD mati diam-diam. Itu gejalanya, bukan freeze.
- OSD butuh **mako jalan**. Kalau `mako &` hilang dari autostart, OSD diam tanpa
  pesan error apa pun.
- `wsctl` **tidak** disentuh — pager sfwbar tetap tak melacak tag dwl. OSD ini
  penggantinya, bukan pelengkapnya.

## Sumber kebenaran & sinkronisasi
Sama seperti labwc: edit di `config/dwl/` (repo) DULU. `autostart.sh` dan
`dwl.desktop` sudah di-symlink lewat `make link` (`dwl` ada di `DIRS`), jadi
tak ada langkah salin untuk keduanya. Beda: `config.h` **dan `config.mk`** harus
disalin ke `~/Dokumen/dwl/` lalu **recompile** tiap ubah — symlink tak dipakai
untuk dua file ini sebab `~/Dokumen/dwl` adalah clone git upstream.

**`autostart.sh` WAJIB executable (`100755`).** dwl menjalankannya lewat
`/bin/sh -c '~/.config/dwl/autostart.sh'`, jadi bit exec hilang = sh gagal exec
(`Permission denied`) dan script mati **sebelum baris pertama** — swaybg, sfwbar,
xremap, mako, dan loop OSD semuanya tak start, tanpa pesan error di mana pun.
Gejalanya persis "wallpaper dan bar tak muncul, tapi fuzzel bisa". Kalau bit-nya
lepas: `git add --chmod=+x config/dwl/autostart.sh` (git menyimpan mode, `chmod`
saja tak cukup untuk clone berikutnya).

---

# Sesi Hyprland (tiling + efek) — `config/hypr/hyprland.lua`

Compositor ketiga, jalan berdampingan dgn labwc/dwl. Stack pendukung **dibagi**:
xremap, sfwbar, waypaper, foot, fuzzel — semua config sama, tak ada duplikasi.

## Kenapa ada
labwc = stacking (snap manual). dwl = tiling tapi tak ada config runtime (recompile
tiap ubah). Hyprland = tiling **plus** reload-on-save **plus** efek (animasi, blur,
gesture). Trade-off: paket lebih besar, bukan wlroots murni (Hyprland fork
`aquamarine`/hyprland-sendiri sejak 0.40).

## Install
```bash
sudo dnf install hyprland xdg-desktop-portal-hyprland brightnessctl
make link          # symlink config/hypr -> ~/.config/hypr
```
Session entry `.desktop` **ikut paket**
(`/usr/share/wayland-sessions/hyprland.desktop`) — jangan bikin sendiri (beda
dgn labwc/dwl yang perlu `sudo cp ... /usr/share/wayland-sessions/`).

**Hyprland TIDAK ada di repo Fedora 43** (dulu ada di F42 = 0.45.2). `dnf install
hyprland` polos gagal; paket di mesin ini dari COPR **ashbuk/Hyprland-Fedora**
(cek: `rpm -q --qf '%{vendor}' hyprland`). COPR **sdegler/hyprland** juga dipasang
untuk `hyprland-guiutils`, dan ia MENYEDIAKAN `hyprland` dgn evr identik
(0.56.2-1.fc43) — dua repo, versi sama persis, jadi pemenang upgrade bisa
berpindah owner diam-diam. Kalau nanti config pecah lagi tanpa sebab jelas,
`rpm -q --qf '%{vendor}'` dulu sebelum menyalahkan config.

`hyprland-guiutils` (nama lama: `hyprland-qtutils`) menyuplai `hyprland-dialog`
(dialog ANR "aplikasi tak merespons"), `hyprland-update-screen`,
`hyprland-donate-screen`. Tanpa paket ini Hyprland 0.56 memperingatkan tiap start
dan ANRManager mati. Konsekuensi setelah dipasang: dua nag yang tadinya diam jadi
hidup — itu sebabnya `hyprland.lua` menyetel `ecosystem { no_update_news,
no_donation_nag }`. Alternatif kalau paketnya tak mau dipasang:
`misc:disable_hyprland_guiutils_check = true` (warning hilang, ANR dialog tetap tak ada).

**Batas waktu `.conf`: dihapus di 0.57.** Hyprland 0.56 menampilkan dialog
`You are using the .conf config format, support for which will be removed in
Hyprland 0.57.` tiap start sesi. Dialog itu **baru muncul setelah
`hyprland-guiutils` dipasang** — sebelumnya Hyprland cuma menulis
`CAsyncDialogBox: cannot create, no hyprland-dialog` lalu diam. Jadi memasang
guiutils membuka nag ketiga, di luar dua yang dimatikan blok `ecosystem`, dan
`ecosystem` TIDAK punya opsi untuk membungkamnya (cek `hyprctl getoption`:
hanya `no_update_news`, `no_donation_nag`, `enforce_permissions`).

Teks peringatan ini hidup di blok string **dialog**, bukan log, jadi
`grep` di `/run/user/1000/hypr/*/hyprland.log` TIDAK akan menemukannya — log
hanya memuat baris DEBUG `[cfg] Lua config not found, using legacy config at …`.
Mencarinya: `strings /usr/bin/Hyprland | grep -n 'will be removed'`.
Yang mudah tertukar dengannya: banner merah `windowrulev2 is deprecated.`
Menangkap banner yang keburu hilang: `hyprctl rollinglog | tail -40`.

**Migrasi ke Lua SUDAH DILAKUKAN** (Agustus 2026) — lihat section "Config Lua"
di bawah. Semua di atas soal syntax rule `.conf` tetap dicatat karena
`hyprland.conf.bak` masih dipakai sebagai jalur mundur.

`debug:suppress_errors` **jangan dihidupkan** — banner error itu satu-satunya
gejala yang muncul saat config pecah; rule yang tak kena tak bergejala sama sekali.

## Aturan menulis keybind (SAMA seperti dwl — batasan xremap)
xremap makan `Super+<huruf>` ini: `a b c d e f g i j k l n o p r s t u v w x y z
, - = backspace` + `Shift-z/t/g`. Yang tersisa untuk Hyprland:
`q m h space Return Tab grave panah 0-9 period slash [ ] Print XF86*`
plus semua `Ctrl+Super+*` dan `Alt+Super+*` (xremap exact-match modifier, jadi
modifier tambahan lolos). **Jangan** bind huruf yang sudah dimakan xremap.

## Peta dari labwc (yang berubah, dan sebabnya)
| labwc | Hyprland | sebab |
|---|---|---|
| `Super+Left/Right` = SnapToEdge | `movefocus l/r` | tiling, snap tak relevan |
| `Super+M`/`H` = Iconify | `movetoworkspacesilent special:minimized` | Hyprland tak punya iconify; `Super+Shift+M` = tampilkan lagi |
| `Super+Down` = Iconify | `togglefloating` | keputusan user |
| `Super+Up` = ToggleMaximize | `fullscreen, 1` | mode 1 hormati bar; mode 0 (fullscreen sejati) di `Super+Shift+Up` |

Sisanya identik: launcher, terminal, close, cycle, workspace 1–4, 8 kombinasi
screenshot, media key.

## Fitur Hyprland yg dipakai (jangan dibuang saat refactor)
dwindle · animasi bezier `macEase`/`macOut` · blur+shadow+`rounding 8` (sinkron
`cornerRadius` labwc) · gradient border surface2→teal · swipe workspace 3 jari
· `special:minimized` · `layerrule blur` untuk sfwbar & fuzzel · `resize_on_border`
· `follow_mouse = 0` (click-to-focus, mac-like, sama labwc) · VFR.

## Hyprland 0.56 (Fedora 43) — syntax yang berubah dari 0.45

Upgrade F42→F43 melompat 0.45.2 → 0.56.2 dan memutus 17 baris config. Yang benar
sekarang (semua diverifikasi lewat `hyprctl keyword <kw> '<isi>'`: balasan `ok` =
sah, `invalid field type <x>` = nama field salah):

| Lama (0.45) | Sekarang (0.56) |
|---|---|
| `windowrulev2 = float, class:^(x)$` | `windowrule = match:class ^(x)$, float on` |
| `windowrulev2 = noshadow/noblur, …` | field jadi `no_shadow on` / `no_blur on` |
| `layerrule = blur, sfwbar` | `layerrule = match:namespace ^(y)$, blur on` |
| `layerrule = ignorezero, …` | `ignore_alpha 0` |
| `gestures { workspace_swipe = true; workspace_swipe_fingers = 3 }` | `gesture = 3, horizontal, workspace` |
| `misc:vfr = true` | `debug:vfr`, default 1 — tak usah ditulis |
| `dwindle:pseudotile = true` | dihapus; pseudotile = state per-window (dispatcher `pseudo`) |
| `bind = …, togglesplit` | `bind = …, layoutmsg, togglesplit` |

Aturan umum bentuk baru: **tiap field WAJIB bernilai** (`float on`, bukan `float`)
dan matcher dipisah dgn prefix `match:`. Bentuk lama `windowrule = float, class:…`
(tanpa v2) juga TIDAK sah lagi — bukan cuma `windowrulev2` yang mati.
Sisa opsi `gestures { workspace_swipe_distance/invert/forever/create_new }` tetap
ada dan tetap dipakai; yang pindah cuma "hidup/mati" + jumlah jari.

**Namespace layer sfwbar = `gtk-layer-shell`, BUKAN `sfwbar`** (default library
gtk-layer-shell). Rule blur bar lama karena itu tak pernah kena sejak awal —
catatan lama yang bilang bar diblur: SALAH, sudah diralat. fuzzel = `launcher`
(benar). Selalu cek dgn `hyprctl layers` sebelum menulis layerrule.

**Persen dan prefiks posisi MATI di rule 0.56.** `size 25% 25%`,
`move 100%-500 100%-320`, `move 100%-w-20 …`, `move onscreen …`, `move cursor …`
semuanya lolos parse (`hyprctl keyword` menjawab `ok`) lalu **tak berefek sama
sekali** — window mendarat di posisi/ukuran default, tanpa satu pun pesan error.
Hanya piksel absolut (`size 480 270`, `move 1420 760`) yang benar-benar dipakai.
Konsekuensi: `hyprctl keyword … => ok` **bukan** bukti rule bekerja; uji efeknya
dgn window umpan: `foot -T '<judul>' -- sh -c 'sleep 4'` lalu baca
`hyprctl clients -j`. Angka piksel yang bergantung resolusi taruh di `local.lua`.

**Picture-in-Picture** (rule bernama `pip` di `hyprland.lua`): window PiP Chromium
(Helium/Thorium) **tak punya app-id** — `class` di `hyprctl clients` betul-betul
string kosong, jadi match wajib lewat `title`. Judulnya beda kapital antar
browser: Chromium `Picture-in-picture`, Firefox/Zen `Picture-in-Picture`;
regex `^([Pp]icture[- ][Ii]n[- ][Pp]icture)$` menampung keduanya. Anchor `^…$`
WAJIB — tanpa itu judul halaman biasa ("Picture-in-Picture Sample - Helium")
ikut kena dan tab browser penuh berubah jadi jendela mungil terpin. `pin on`
(tampil di semua workspace) hanya berlaku untuk window floating, jadi `float on`
harus menyertainya.

Validasi setelah edit: `hyprctl reload && hyprctl configerrors` (kosong = bersih).
Hyprlang sendiri sudah "deprecated in favor of lua" sejak 0.55 — masih jalan penuh
di 0.56, tapi kalau upstream membuangnya, port berikutnya = `hl.window_rule{…}`
(stub API: `/usr/share/hypr/stubs/hl.meta.lua`, contoh `/usr/share/hypr/hyprland.lua`).

## snappy-switcher — overlay Alt+Tab (Hyprland saja)

Switcher overlay (ikon app + judul window, ala Cmd+Tab macOS). Sumber:
<https://github.com/OpalAayan/snappy-switcher>, clone di `~/Dokumen/snappy-switcher`,
dipasang `sudo make install` ke `/usr/local/bin/`. Tak ada paket Fedora.

- **Hyprland-only** — baca daftar window + urutan MRU lewat Hyprland IPC. Di
  labwc/dwl wrapper langsung exit (socket tak ada), keybind cycle lama tetap jalan.
- **JANGAN jalankan `snappy-install-config`.** Script itu menulis
  `~/.config/snappy-switcher/config.ini` sebagai file asli; `make link` lalu
  menggesernya ke `.bak`. Repo ini yang pegang config — cukup `make link`.
- **Tema tidak di-vendor.** Binary cari urut: `~/.config/snappy-switcher/themes/`,
  `/usr/share/…`, `/usr/local/share/snappy-switcher/themes/`. `sudo make install`
  upstream taruh di path ketiga, jadi `name = catppuccin-frappe.ini` ketemu sendiri.
  Kalau mau tema custom: bikin `config/snappy-switcher/themes/` di repo.
- **Flag `--mod` WAJIB sama dgn modifier bind-nya** (`bind = ALT, TAB` →
  `--mod alt`). snappy menahan panel selama modifier ditekan; salah nama =
  banner CONFIG ERROR, bukan switcher.
- Bind: `Alt+Tab`/`Alt+Shift+Tab` (semua window), `Super+Tab`/`Super+Shift+Tab`
  (`--workspace`). `Super+grave` sengaja disisakan `cyclenext` sebagai fallback
  kalau daemon mati. Daemon: `exec-once = snappy-wrapper` (wrapper tunggu socket
  Hyprland siap dulu, anti-race saat login SDDM).
- Verifikasi: `pgrep -x snappy-switcher`, `hyprctl binds | grep -A2 snappy`.

## Notifikasi — mako (dipakai ketiga compositor)

`config/mako/config`, paket Fedora `mako`. Dipilih ketimbang SwayNotificationCenter
sebab ringan dan config-nya sekelas foot/fuzzel (ini, bukan CSS GTK). Konsekuensi:
**tak ada panel riwayat/Notification Center** — cuma toast + `makoctl restore`.

- Jalan lewat `wlr-layer-shell`, jadi tak butuh IPC compositor apa pun (beda dgn
  snappy-switcher). Autostart di ketiga file: `labwc/autostart`, `dwl/autostart.sh`,
  `hypr/hyprland.lua`.
- `layer=overlay` supaya toast tetap muncul di atas window fullscreen.
- `margin=34,14` — 34 = tinggi sfwbar (`min-height: 24px` + padding) + jarak, jadi
  toast tak menutupi menu-bar. **Kalau tinggi sfwbar diubah, ubah angka ini juga.**
- Keybind pakai `Ctrl+Super+n/d` (+Shift) — `Super+n`/`Super+d` polos dimakan xremap.
- Reload setelah edit: `makoctl reload` (tak perlu restart sesi; config = symlink).
- dwl: keybind ada di `config.h` → **wajib recompile**, tak seperti dua lainnya.

## Catatan integrasi
- **xremap**: paket terpasang = `xremap-wlroots`. Tetap jalan di Hyprland karena
  Hyprland implement `wlr-foreign-toplevel-management` → deteksi app (blok `foot`)
  aktif. Tak perlu varian `xremap-hyprland`.
- **sfwbar**: taskbar/switcher/jam jalan. Widget `pager` bawaan **TIDAK DIPAKAI** —
  lihat section "Pager sfwbar" di bawah.
- **waypaper** ada di `~/.local/bin` → `exec-once` pakai path absolut, sebab
  PATH sesi SDDM belum tentu memuatnya.
- **Chromium (Thorium/Helium)**: `env = ELECTRON_OZONE_PLATFORM_HINT,auto`
  memaksa native Wayland. Ini yang memperbaiki bug address bar tak bisa diklik
  saat jalan lewat XWayland di WM wlroots.
- **brightnessctl** belum tentu terpasang → bind brightness dikomentari di config.
- **Mission Control** = plugin `hyprexpo`, butuh `hyprpm` + header build. Belum
  dipasang; tawarkan hanya kalau user minta.

## Pager sfwbar — widget bawaan tak dipakai, diganti `wsctl`

Widget `pager` sfwbar cuma punya backend **sway IPC** dan **Hyprland**, dan yg
Hyprland baca state sekali saat start lalu berhenti menyimak event fokus. Diuji
di sfwbar 1.0~beta16.1: window di workspace 3, workspace aktif 3, highlight
tetap di 2. Man sfwbar juga menyatakan *"Placer and pager require sway"*. labwc
tak punya sway IPC sama sekali, jadi pager di labwc belum pernah jalan — glyph
`pins`-nya cuma hiasan, klik tak melakukan apa-apa. (Catatan lama di repo ini
yang bilang pager melacak workspace Hyprland: SALAH, sudah diralat.)

Gantinya `config/sfwbar/wsctl` (python3, tanpa dependensi) + 4 `label` manual di
`sfwbar.config`:
- `wsctl watch` — emit `{"ws": N}` tiap workspace aktif berubah. Dipanggil dari
  `scanner { ExecClient(...) }`, memicu trigger `"ws"`.
- `wsctl set N` — pindah workspace (dipanggil dari `action = Exec` tiap label).
- `wsctl mark N` — catat state tanpa pindah (jalur labwc).

Aturan yang mudah dilanggar:
- **`button` tak bisa menampilkan teks** — `value` pada button = nama ikon/file
  gambar, jadi glyph nerd-font muncul sebagai ikon fallback "sfw". Pakai `label`
  (label tetap dukung `action`).
- **TAK ADA yang lewat shell — `ExecClient` MAUPUN action `Exec`.** sfwbar
  1.0~beta16.1 fork+`execvp` argv hasil parse sendiri (biner tak memuat string
  `/bin/sh`; diverifikasi lewat TriggerAction: `Exec "$HOME/x.sh"` tak jalan,
  `Exec "/home/rjial/x.sh"` dan `Exec "sh -c '$HOME/x.sh'"` jalan). `$HOME`
  ditelan mentah dan spawn **gagal diam-diam** — klik nol reaksi, nol pesan
  error. Wajib dibungkus di keduanya: `Exec "sh -c 'exec $HOME/…'"`.
  (Catatan lama yang bilang `Exec` lewat shell: SALAH, sudah diralat.)
- **Nama style dari expression, bukan class** — `style = If(WsActive=1,"ws_on","ws_off")`
  plus `trigger = "ws"` di tiap label. CSS pakai `#ws_on` / `#ws_off`.
- Nama style tombol taskbar = `#taskbar_item` dgn class `.active`. Bukan
  pseudo-class `:active` (itu "sedang ditekan").
- Glyph workspace harus sama di tiga file: `labwc/rc.xml` `<desktops><names>`,
  `hypr/hyprland.lua` `default_name`, `sfwbar/sfwbar.config` label `value`.
- labwc: tiap `GoToDesktop` di `rc.xml` WAJIB dipasangkan `Execute wsctl mark N`
  nomor sama, kalau tidak highlight melenceng. `wsctl set` di labwc butuh
  **wtype** (`sudo dnf install wtype`) sebab labwc tak punya IPC perintah —
  script mensintesis Super+N supaya keybind rc.xml yang bekerja.
- dwl **sudah didukung** `wsctl` (sejak perbaikan pager): jalurnya sama dgn labwc
  (state file + wtype), tapi sumber `mark`-nya loop stdin `dwl/autostart.sh` —
  loop yang sama yang memberi makan OSD tag. Keduanya hidup berdampingan, OSD
  bukan pengganti pager lagi. `WS_COUNT` jadi dict per-WM (dwl 9, sisanya 8);
  pager punya 8 label, jadi tag 9 dwl dicatat tapi tak ada label menyala.
  Toggleview (>1 tag menyala) ditandai sebagai tag terendah.
- **`XDG_CURRENT_DESKTOP` tak bisa dipercaya** — dwl tak menyetelnya sama sekali,
  sesi dari TTY juga tidak. `compositor()` punya fallback `pgrep -x` untuk
  Hyprland/labwc/dwl; tanpa itu semua jalur balik "unknown" dan pager mati diam.
- Tombol power `󰐥` = `label` dgn `action = Exec "sh -c 'exec $HOME/…/powermenu'"`,
  style `#power_btn`. Kena aturan `button`-vs-`label` DAN aturan tanpa-shell di atas.

## Power menu — `config/scripts/powermenu` (ketiga compositor)

`Ctrl+Super+Q` di ketiga WM. Frontend `fuzzel --dmenu`, jadi tema ikut
`config/fuzzel/fuzzel.ini` — nol CSS/paket UI tambahan. Jalur lain ke menu yang
sama: tombol sfwbar, dan submenu Power di `labwc/menu.xml`.

Keputusan desain yang jangan dibalik saat refactor:
- **Log Out = `loginctl terminate-session`, BUKAN aksi exit per-WM.** labwc tak
  punya CLI exit dan dwl tak punya IPC sama sekali, jadi logind satu-satunya
  jalur seragam. Ia juga menutup sesi logind dengan benar — `Exit` labwc dan
  `$mod SHIFT Q` Hyprland cuma membunuh compositor. Keduanya sengaja tetap ada.
- **`Ctrl+Super+Q`, bukan `Super+Q`** — `Super+Q` polos sudah close window di
  ketiganya. `q` sendiri tidak dimakan xremap, dan `Ctrl+Super+*` selalu lolos
  (xremap exact-match modifier).
- **Konfirmasi kedua** untuk Log Out/Reboot/Shut Down, `Cancel` ditaruh PERTAMA
  supaya itu yang ter-highlight. Submenu labwc/menu.xml TAK punya konfirmasi —
  menu Openbox tak bisa berantai prompt; itu diketahui, bukan kelalaian.
- `poweroff`/`reboot`/`suspend` **tak butuh sudo** (logind + polkit, `lxpolkit`
  sudah autostart). Jangan tambahkan `pkexec`/`sudo`.
- **swaylock Fedora = upstream, BUKAN swaylock-effects.** `screenshots`,
  `effect-blur`, `effect-pixelate` TIDAK ADA — memasukkannya ke
  `config/swaylock/config` membuat swaylock gagal start dan layar TAK terkunci.
- Glyph di menu sudah diverifikasi ada di `Symbols Nerd Font` yang terpasang.
  Sebelum menukar glyph, cek dgn **`fc-list ":charset=<codepoint>" family`**,
  BUKAN `fc-match`. `fc-match` cuma memberi font peringkat teratas: untuk F0CA8
  ia menjawab `Jomolhari` walau Symbols Nerd Font juga punya glyph itu.
  (Catatan lama yang bilang F0CA8/F0CAC "tak terpasang": SALAH, sudah diralat —
  seri `md-numeric_N_circle` lengkap 1-9 di F0CA0 + 2*(N-1), dipakai pager 1-8.)

## OSD — `config/scripts/osd` + blok `[category=osd]` mako

Renderer generik. Slot terpakai: `tag` (dwl saja, dari `osd-dwl-tag`), `volume`
dan `brightness` (ketiga WM, dari `volumectl`/`brightctl`).

- `osd <slot> <text> [percent]` — argumen ketiga opsional dikirim sebagai hint
  `int:value:N` dan membuat mako mengecat **progress bar** (mako(5): hint `value`
  0-100). Bar itu = latar toast yang terisi sebagian (`progress-color=over` di
  blok `[category=osd]`), BUKAN widget terpisah — jadi warnanya harus tipis, teal
  penuh membuat teks tak terbaca. `source` (ganti `over`) akan mengganti
  background dan merusak transparansi.
- Nilai di luar 0-100 **diabaikan mako** (bar hilang diam-diam, bukan error) —
  itu sebabnya `osd` meng-clamp sendiri.
- **`notify-send -r <id>` TIDAK bekerja di mako** untuk anti-tumpuk. mako
  menetapkan id sendiri dan mengabaikan `replaces_id` yang tak cocok, jadi id
  hardcode selalu membuat toast baru (diuji: 4 kirim = 4 toast). Yang benar =
  hint `x-canonical-private-synchronous` (diuji: 4 kirim = 1 toast).
- **JANGAN tambah `max-visible` ke blok criteria** — mako menolak dgn
  "Setting `max_visible` is allowed only for `output` and/or `anchor`" dan
  **seluruh file gagal di-parse**, jadi semua styling mako hilang.
- Timeout OSD hidup di `default-timeout` blok mako, bukan `-t` di script — satu
  tempat saja. `history=0` supaya OSD tak memenuhi `makoctl restore`.
- **Blok `[mode=do-not-disturb]` harus tetap paling bawah** — criteria mako
  dievaluasi berurutan, jadi DND harus menang atas `[category=osd]`.
- Validasi config tanpa mengganggu mako yang jalan:
  `mako -c <file>` (akan gagal di DBus, tapi parse error tercetak dgn jelas).

## Volume & brightness OSD — `volumectl` / `brightctl` (ketiga compositor)

Keybind `XF86Audio*` / `XF86MonBrightness*` di ketiga WM memanggil wrapper ini,
BUKAN `wpctl`/`brightnessctl` langsung. Balik ke pemanggilan langsung = OSD hilang.

- **Selalu BACA ULANG nilai sesudah aksi**, jangan hitung "lama ± step": wpctl
  meng-clamp di 0% dan di limit, brightnessctl di min/max — tebakan melenceng di
  kedua ujung. `wpctl get-volume` / `brightnessctl -m i` yang jadi sumber angka.
- **`wpctl set-volume -l 1.0` wajib** — wpctl tak punya batas atas sendiri; tanpa
  limit, spam volume-up terus menaikkan gain di atas 100% (software boost, mulai
  distorsi) dan angkanya melewati 100 (hint `value` mako cuma sah 0-100).
- **`brightnessctl -n1` HARUS menempel, bukan `-n 1`** — argumen `-n` bersifat
  opsional di getopt-nya, jadi bentuk terpisah membuat "1" lepas jadi argumen
  posisi dan dibaca sebagai *operation*: perintah berubah jadi "tampilkan info",
  brightness TAK berubah, **exit code tetap 0, tanpa pesan error**. Diuji:
  `-n 1 set 5%-` nilai tetap 100%; `-n1 set 5%-` turun ke 95%.
- **brightnessctl di mesin ini tak butuh sudo** walau user bukan anggota grup
  `video` dan sysfs milik root: binary Fedora di-build dgn dukungan logind
  (`strings` memuat `org.freedesktop.login1.Session`) jadi menulis lewat D-Bus
  `SetBrightness` sesi aktif. Konsekuensi: **gagal dari SSH** (bukan sesi aktif).
  Jangan "perbaiki" dgn `sudo`/`pkexec`/udev rule.
- **`export LC_ALL=C`** di kedua script — wpctl mencetak `Volume: 0.77` dan awk
  di locale id_ID membaca `0,77` sebagai 0, jadi OSD selalu 0%.
- Glyph terverifikasi (`fc-match ":charset=<cp>"`): volume F057E/F0580/F057F,
  mute F075F, mik F036C/F036D, brightness **F00E0 saja**. Seri nf-md-brightness
  lain (F00DB–F00DF) TIDAK terpasang (jatuh ke Jomolhari) — itu sebabnya
  brightness tak punya gradasi glyph terang/redup seperti volume.
- Mute dan mik dikirim **tanpa argumen persen** — state on/off; bar 0% akan
  tampak seperti volume 0 padahal nilainya masih tersimpan.
- dwl: keybind ada di `config.h` → **wajib salin ke `~/Dokumen/dwl` + recompile**.
  labwc `--reconfigure`, Hyprland auto-reload.
- Nama file `brightctl`, bukan `brightnessctl`, supaya tak menutupi binary asli
  kalau `~/.config/scripts` pernah masuk PATH.

## XDG autostart — `config/scripts/xdg-autostart` (ketiga compositor)

Peluncur entri `.desktop` dari `~/.config/autostart` + `/etc/xdg/autostart`.
Dipanggil **paling akhir** di blok autostart ketiga WM (`labwc/autostart`,
`dwl/autostart.sh`, `hypr/hyprland.lua`) supaya 5 daemon repo sudah hidup dulu.
Sebelum ini 39 entri `.desktop` di mesin tak pernah dieksekusi sama sekali.

Kenapa script sendiri: **`dex` tak ada di repo Fedora**, dan systemd
`xdg-desktop-autostart.target` punya `RefuseManualStart=yes` (butuh target sesi
sendiri + `import-environment`). Jangan "perbaiki" dgn mengganti ke salah satu
dari keduanya tanpa alasan baru.

Aturan yang mudah dilanggar:
- **Hanya grup `[Desktop Entry]` yang dibaca.** Banyak entri (mis. `slack.desktop`)
  punya grup `[Desktop Action …]` dengan `Exec=` sendiri; `grep '^Exec='` polos
  akan meluncurkan aksi yang salah. Itu sebabnya `get_key()` memakai awk dgn
  penanda grup.
- **`sh -c "exec $cmd"`, bukan `sh -c "$cmd"`.** Tanpa `exec`, `$!` mencatat PID
  shell dan program aslinya jadi anaknya — `-k` membunuh shell saja dan
  meninggalkan proses yatim (diuji: 1 `sleep` tersisa).
- **JANGAN `setsid`/`nohup`.** Itu persis penyebab helper nyangkut lintas sesi
  (lihat blok `pkill` di `dwl/autostart.sh`). PID dicatat ke
  `$XDG_RUNTIME_DIR/xdg-autostart.pids` dan dibunuh di awal run berikutnya —
  pembunuhan dilakukan SEBELUM peluncuran, kalau tidak PID baru bisa kebetulan
  sama dgn PID lama yang sudah mati.
- **Iterasi direktori tak boleh lewat pipe** (`printf | while read`) — subshell
  membuat variabel dedupe `seen` hilang tiap iterasi, dan entri user berhenti
  menimpa entri sistem bernama sama.
- Field code (`%U %f %i …`) wajib dibuang dari `Exec`; `slack.desktop` memakai
  `%U` dan akan menerima literal `%U` sebagai URL.
- `XDG_CURRENT_DESKTOP` di dwl di-set **inline** di baris pemanggilan, bukan
  `export` — sesi dwl sengaja tetap tak punya variabel itu (fallback `pgrep` di
  `sfwbar/wsctl` dan pemilihan backend `xdg-desktop-portal` bergantung padanya).
- `lxpolkit.desktop` punya `OnlyShowIn=LXDE;` → tak akan dobel dgn `lxpolkit`
  hardcode. Jangan tambahkan penanganan khusus untuk itu.
- Sumber kebenaran daftar buang = `config/scripts/xdg-autostart.skip`
  (**skip**-list, bukan allowlist — supaya paket baru otomatis jalan). Verifikasi
  perubahan dgn `xdg-autostart -n` sebelum relog; `-n` sengaja tanpa efek samping.

## Portabilitas monitor (JANGAN hardcode nama output)
`monitor = , preferred, auto, 1` = catch-all, cocok untuk output apa pun. Workspace
persistent 1-8 sengaja TANPA field `monitor:` supaya ikut display mana pun —
`workspace = N, persistent:true` (sudah diverifikasi jalan tanpa `monitor:`).
Override per-mesin masuk `~/.config/hypr/local.lua` (di-`dofile` paling bawah
`hyprland.lua`, dibuat otomatis oleh `make link`, di-gitignore). Kalau user minta
setting monitor spesifik: tulis di `local.lua`, BUKAN di `hyprland.lua`.
`hyprland.lua` mengecek keberadaan file itu sebelum `dofile` — `dofile` pada file
yang tak ada = error fatal, dan config yang gagal dimuat menjatuhkan sesi ke
**safe mode** (config tak dimuat sama sekali, keybind default `SUPER+Q` = kitty).

Workspace persistent WAJIB ada, kalau tidak swipe 3 jari tampak mati: Hyprland
cuma geser ke workspace yang sudah eksis (`workspace_swipe_create_new = false`),
dan tanpa persistent hanya workspace 1 yang eksis. Catatan: `hyprctl reload` tidak
retro-instansiasi workspace persistent (rule dieksekusi saat monitor connect) —
efek penuh setelah restart sesi.

## Config Lua — `config/hypr/hyprland.lua` (sumber kebenaran)

Sejak Agustus 2026 sesi Hyprland dimuat dari **`hyprland.lua`**, bukan `.conf`.
`.conf` dibuang di 0.57; file lamanya disimpan sebagai `hyprland.conf.bak`
(ekstensi `.bak` membuatnya inert — Hyprland tak melihatnya). **Jalur mundur:**
kalau Lua bermasalah, `mv hyprland.conf.bak hyprland.conf` lalu hapus/rename
`hyprland.lua`, relog. Selama `hyprland.lua` ada, mengedit `.bak` tak berefek
apa pun — kesalahan yang mudah terjadi setelah beberapa bulan.

Penemuan nama config otomatis: `~/.config/hypr/hyprland.lua` menang tanpa flag
apa pun (diverifikasi lewat instance bersarang tanpa `-c`: log berbunyi
`[cfg] Using lua config found at …`). Tak ada langkah salin — `make link` sudah
men-symlink dirnya, dan Hyprland auto-reload saat file disimpan.

**`hyprctl dispatch` mengikuti FORMAT CONFIG, bukan versi Hyprland.** Di sesi
ber-config Lua, argumen dispatch di-parse sebagai Lua:
`hyprctl dispatch workspace 2` gagal dgn `')' expected near '2'`, yang benar
`hyprctl dispatch 'hl.dsp.focus({workspace=2})'` (hyprctl membungkusnya sendiri
dgn `hl.dispatch(...)`, jadi JANGAN tulis `hl.dispatch(...)` — dobel-bungkus =
`expected a dispatcher`). Itu memutus `sfwbar/wsctl`; `hypr_set()` sekarang
mencoba bentuk Lua dulu lalu jatuh ke bentuk lama. Script lain yang memanggil
`hyprctl dispatch` harus ikut aturan ini. Query (`clients`, `getoption`,
`activeworkspace`, `layers`) TIDAK berubah.

Menguji perubahan tanpa mempertaruhkan sesi: jalankan Hyprland **bersarang**
(`HYPR_TEST=1 Hyprland -c <file>` membuka window sendiri di dalam sesi aktif),
lalu `hyprctl -i <signature> {configerrors,binds,getoption,clients}`.
`HYPR_TEST=1` dibaca `hyprland.lua` untuk melewati blok autostart — tanpa itu
instance uji menyalakan xremap/sfwbar/mako kedua yang berebut input.
Instance uji ditutup dgn `hyprctl -i <sig> dispatch 'hl.dsp.exit()'`.

Padanan bentuk `.conf` -> Lua yang tak jelas ditebak (semua diverifikasi lewat
`hyprctl -i <sig> eval`, yang HANYA jalan di instance ber-config Lua):

| `.conf` | Lua |
|---|---|
| `bind = SUPER, Q, killactive` | `hl.bind("SUPER + Q", hl.dsp.window.close())` |
| `fullscreen, 1` / `fullscreen, 0` | `hl.dsp.window.fullscreen({ mode = "maximized" })` / `{ mode = "fullscreen" }` |
| `resizeactive, -60 0` | `hl.dsp.window.resize({ x = -60, y = 0, relative = true })` |
| `movetoworkspacesilent, special:x` | `hl.dsp.window.move({ workspace = "special:x", silent = true })` |
| `movewindow, l` | `hl.dsp.window.move({ direction = "left" })` |
| `focusmonitor, -1` | `hl.dsp.focus({ monitor = "-1" })` |
| `movecurrentworkspacetomonitor, -1` | `hl.dsp.workspace.move({ monitor = "-1" })` |
| `layoutmsg, togglesplit` | `hl.dsp.layout("togglesplit")` |
| `bindel` / `bindl` | opsi ke-3 `{ locked = true, repeating = true }` / `{ locked = true }` |
| `windowrule = match:class ^(x)$, float on` | `hl.window_rule({ name = "…", match = { class = "^(x)$" }, float = true })` |
| `$mod, grave` dua baris berturut | Lua: bind kedua MENGGANTI yang pertama — gabungkan jadi satu `function() … end` |

Pesan error `eval` menyebutkan bentuk tabel yang sah (mis. `hl.window.resize:
expected … a table { x, y, relative?, window? }`), jadi menebak nama field tak
perlu: panggil, baca keluhannya. `hl.window_rule` WAJIB punya `name` unik.

Yang TIDAK dipakai lagi dari catatan `.conf`: `$var` hyprlang (di Lua pakai
variabel Lua biasa), `source =` (pakai `dofile`), dan `exec-once` (pakai
`hl.on("hyprland.start", …)` + `hl.exec_cmd`).
