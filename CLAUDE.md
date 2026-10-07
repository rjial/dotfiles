# CLAUDE.md — macOS-style Hyprland Deployment (Void Linux)

> **Untuk sesi Claude Code yang berjalan di mesin Void Linux milik user (rjial).**
> Sesi ini punya akses langsung ke `~/.config/`, `xbps-install`/`xbps-src`, dan
> compositor-nya. Branch ini (`void-hyprland`) berisi config **Hyprland saja**
> (bukan labwc/dwl — itu di branch `master`, untuk mesin Fedora user yang lain);
> tugasmu adalah men-deploy-nya ke mesin ini dan memandu setup sampai shortcut
> ala macOS + rice teks-only berfungsi.

## Apa isi branch ini

Config Hyprland (Wayland compositor) dengan shortcut ala macOS DAN nuansa rice
teks-only ala polybar (bar sfwbar, font bitmap GohuFont, panel fastfetch+foto,
workspace label angka romawi) — replikasi rice lama user (bspwm + polybar +
urxvt + neofetch) di atas Hyprland, khusus mesin Void.

`Super` = tombol **Cmd**. `xremap` me-remap huruf shortcut aplikasi
(`Super+c/v/x/s/z/…`) menjadi `Ctrl+` supaya aplikasi GUI terasa mac-like;
tombol window-management (`Super+q/m/h/space/tab/grave/arrows/digits`)
diteruskan ke Hyprland. Launcher = **fuzzel** (Spotlight), terminal = **foot**
(dengan smart copy: Cmd+C = copy, Ctrl+C asli = SIGINT).

```
config/
  xremap/config.yml    # engine remap Cmd->Ctrl (blok foot HARUS pertama)
  hypr/hyprland.lua    # keybind + env + autostart + efek + rule window (satu file)
  hypr/local.lua       # override per-mesin (monitor, geometri) — gitignored
  mako/config          # notification daemon + blok [category=osd]
  scripts/powermenu    # power menu fuzzel
  scripts/osd          # renderer OSD generik lewat mako
  scripts/volumectl    # volume/mute via wpctl + OSD
  scripts/brightctl    # backlight via brightnessctl + OSD
  scripts/fastfetch-panel    # launcher panel fastfetch+foto pinned
  scripts/xdg-autostart      # jalankan entri .desktop autostart
  scripts/xdg-autostart.skip # entri yang TAK boleh jalan
  swaylock/config      # tema lock screen
  foot/foot.ini        # terminal — font GohuFont:pixelsize=14
  fuzzel/fuzzel.ini    # launcher — font GohuFont:pixelsize=14 (fcft, sama pola foot)
  sfwbar/sfwbar.config # bar teks-only: taskbar + workspace romawi + status + power
  sfwbar/wsctl         # baca/ganti workspace aktif (Hyprland IPC saja)
  sfwbar/cmus-status   # modul now-playing cmus
  fastfetch/config.jsonc     # panel info sistem + foto (logo via sixel)
  snappy-switcher/     # overlay Alt+Tab (butuh Hyprland IPC)
  waypaper/            # wallpaper picker
README.md              # dokumentasi ringkas (rujukan)
```

`make link` mem-symlink dir di `DIRS` (`Makefile:15`) ke `~/.config/`. Menambah
**dir baru** di `config/` WAJIB ditambah ke `DIRS` juga — file baru di dalam dir
yang sudah ter-symlink langsung hidup tanpa ubah Makefile.

## Tugas deploy (jalankan berurutan, konfirmasi ke user di tiap langkah sudo)

### 1. Install paket yang SUDAH ada di repo resmi Void

Terverifikasi langsung lewat `xbps-query -Rs <nama>` di mesin ini — aman
dieksekusi tanpa cek ulang:

```bash
sudo xbps-install foot fuzzel mako swaylock grim slurp wl-clipboard swaybg \
  cmus fastfetch polkit-gnome gohufont
```

`elogind` + `dbus` biasanya sudah terpasang & aktif di instalasi desktop Void
(`sv status dbus elogind`). Kalau belum:

```bash
sudo xbps-install elogind dbus
sudo ln -s /etc/sv/dbus    /var/service/
sudo ln -s /etc/sv/elogind /var/service/
```

Powermenu (`loginctl terminate-session`, poweroff/reboot/suspend via logind
D-Bus) memakai API yang disediakan elogind — TIDAK perlu branching kode untuk
skenario tanpa-elogind; kalau mesin ini suatu saat murni `seatd` tanpa elogind,
`loginctl` tak akan ada dan powermenu perlu diganti manual ke
`doas poweroff`/`doas zzz` dkk (dicatat di sini sbg fallback, bukan diimplementasikan).

### 2. Paket custom lewat `~/void-packages`

Paket berikut **TIDAK ADA** di repo resmi Void (dicek langsung via
`xbps-query -Rs`) — dibangun sendiri via `xbps-src`, bukan `make install`
manual ke `/usr/local`, bukan `cargo install`/`pip install` lepas. Hasilnya
tetap terkelola xbps (upgrade/hapus normal).

**Cek dulu apakah `~/void-packages` sudah ada** sebelum clone ulang
(`ls ~/void-packages`). Kalau belum, clone **fork pribadi user**
(`https://github.com/rjial/void-packages`, BUKAN `void-linux/void-packages`
upstream langsung) — fork ini sudah ada & aktif, jadi template yang ditempel
bisa di-commit+push ke sana untuk backup. `./xbps-src binary-bootstrap` cukup
sekali per mesin.

#### 2a. Hyprland + ekosistemnya (pakai template komunitas)

Hyprland sendiri dan sebagian besar dependensinya (`hyprlang`, `hyprcursor`,
`hyprgraphics`, `hyprland-protocols`, `aquamarine`,
`xdg-desktop-portal-hyprland`) tak ada di repo resmi maupun void-packages
upstream (dicek: `raw.githubusercontent.com/void-linux/void-packages/master/
srcpkgs/hyprland/template` → 404). Hanya `hyprutils` & `hyprwayland-scanner`
yang sudah ada. Menulis ~7 template dari nol berisiko tinggi (versi
saling-bergantung) — pakai template komunitas yang aktif dipelihara:

```bash
mkdir -p ~/repos && cd ~/repos
# fork pribadi user, BUKAN void-linux/void-packages upstream langsung — supaya
# template yang ditempel bisa di-commit+push ke fork sendiri, bukan cuma lokal.
# Remote "origin" dari clone ini = fork sendiri.
git clone https://github.com/rjial/void-packages
cd void-packages && ./xbps-src binary-bootstrap && cd ..

git clone https://github.com/sofijacom/hyprland-void.git
cat hyprland-void/common/shlibs >> void-packages/common/shlibs
cp -r --remove-destination hyprland-void/srcpkgs/* void-packages/srcpkgs/

cd void-packages
# Commit DULU, baru sync dgn upstream (bukan push dulu) — supaya tak kehilangan
# template yang baru ditempel kalau upstream punya versi lebih baru utk paket
# yang sama (mis. mesa). WAJIB dilakukan SEBELUM build: fork yang basi bikin
# xbps-src salah sangka suatu dependensi (mis. libgbm-devel dari mesa) tak
# tersedia sbg binary dan malah membangunnya dari source (mesa+llvm+rust,
# puluhan menit sia-sia) padahal binary resminya sudah ada.
git add srcpkgs common/shlibs
git commit -m "Add hyprland-void templates"
git remote add upstream https://github.com/void-linux/void-packages 2>/dev/null
git fetch upstream && git pull --rebase upstream master

# `xbps-src pkg` cuma terima SATU nama paket per panggilan — dua baris
# terpisah, BUKAN `pkg hyprland xdg-desktop-portal-hyprland` sekaligus (argumen
# kedua diam-diam diabaikan, tanpa pesan error apa pun — ini yg kejadian saat
# eksekusi pertama kali, xdg-desktop-portal-hyprland diam-diam tak terbangun).
./xbps-src pkg hyprland
./xbps-src pkg xdg-desktop-portal-hyprland
sudo xbps-install --repository=hostdir/binpkgs hyprland xdg-desktop-portal-hyprland

# simpan template ke fork sendiri (commit sudah di atas, tinggal push)
git push origin master
```

> **Gotcha nyata yang pernah kejadian**: `cat hyprland-void/common/shlibs >>
> void-packages/common/shlibs` bisa membawa baris STALE kalau template
> komunitas baru naik versi minor tapi `common/shlibs`-nya belum di-update
> (persis terjadi pada `hyprutils`: template bilang `0.14.1`, shlibs mereka
> masih bilang `0.14.0`). xbps-src `99-pkglint` lalu menolak build dgn "SONAME
> bump detected" — bukan krn ada yg salah, tapi krn baris LAMA utk `hyprutils`
> (dari template resmi void-packages yg sudah ditimpa `cp --remove-destination`)
> masih nyangkut di `common/shlibs` dan bikin cocok ganda utk pkgname yg sama.
> Perbaikan: `grep <pkgname> common/shlibs` dulu sebelum build — kalau ada
> >1 baris utk pkgname yg sama dgn revision version berbeda, hapus yg basi,
> sisakan yg sesuai versi template saat ini.

Templatenya sudah masuk `~/void-packages/srcpkgs/` lewat langkah `cp` di atas
(bukan ditinggal di clone terpisah). **Sebelum dipakai, cek ulang**
[`sofijacom/hyprland-void`](https://github.com/sofijacom/hyprland-void) masih
jadi fork paling aktif (per 2026-10 ini `pushed` 2026-10-01, fork dari
`Makrennel/hyprland-void` yang stale sejak Mei 2025) — proyek komunitas begini
bisa pindah maintainer. Versi yang dibawa saat dicek: **Hyprland 0.56.2**,
PERSIS sama dgn yang dipakai & diuji di branch `master` (Fedora, COPR
`ashbuk/Hyprland-Fedora`) — jadi `hyprland.lua` (API `hl.*` 0.56) di branch ini
kompatibel tanpa port ulang.

Alternatif lebih cepat yang TIDAK dipakai di sini: repo yang sama menyediakan
binary pre-built pihak ketiga (`/etc/xbps.d/hyprland-void.conf` →
`repository=https://raw.githubusercontent.com/sofijacom/hyprland-void/repository-x86_64-glibc`).
Build dari source sendiri lebih bisa diaudit — dicatat sbg opsi, bukan default.

#### 2b. xremap — SUDAH DIBUAT (`xremap-hypr-bin`)

Mesin ini sudah punya `xremap-gnome-bin` terpasang (paket custom lain di fork
`~/void-packages`, untuk sesi GNOME) yang memasang binary rilis prebuilt
upstream ke `/usr/bin/xremap`. **Jangan pakai `build_style=cargo`** — upstream
xremap sudah menyediakan binary rilis per-backend compositor
(`xremap-linux-x86_64-{gnome,hypr,wlroots,kde,niri,...}.zip` di GitHub
Releases), jauh lebih simpel daripada build dari source. Untuk Hyprland,
varian yang benar adalah **`-hypr`** (backend khusus Hyprland, bukan
`-wlroots` generik — ada sejak v0.15.x).

Template `srcpkgs/xremap-hypr-bin/template` sudah ditulis (meniru persis pola
`xremap-gnome-bin`), SATU bedanya: `do_install()` memasang binary sbg
**`/usr/bin/xremap-hypr`** (`vbin xremap xremap-hypr`), bukan `/usr/bin/xremap`
polos — kalau nama file sama, `xbps-install` menolak (`xremap-gnome-bin` sudah
memiliki path itu). Konsekuensi: `config/hypr/hyprland.lua` memanggil
`xremap-hypr`, bukan `xremap`. Sudah di-build & diverifikasi (`xbps-query
--repository=hostdir/binpkgs -f xremap-hypr-bin` → `/usr/bin/xremap-hypr` +
lisensi, tanpa bentrok file). Tinggal `sudo xbps-install --repository=hostdir/
binpkgs xremap-hypr-bin`.

Checksum release di-pin ke v0.15.13 — kalau upstream rilis versi baru, update
`version=`/checksum di template (unduh ulang zip + `sha256sum`), jangan ditebak.

#### 2c. sfwbar, snappy-switcher, waypaper — SUDAH DIBUAT & diverifikasi

Tak ada template komunitas siap pakai untuk ketiga ini (sudah dicek via
pencarian web) — ditulis manual di `srcpkgs/<nama>/template`, sudah dibangun &
diinstal. Alur umum (per paket baru serupa di masa depan):

```bash
cd ~/void-packages
mkdir -p srcpkgs/<nama>
$EDITOR srcpkgs/<nama>/template
./xbps-src pkg <nama>
sudo xbps-install --repository=hostdir/binpkgs <nama>
```

| Paket | `build_style` | Catatan (semua terverifikasi lewat build sungguhan) |
|---|---|---|
| **sfwbar** (`1.0.beta17_1`) | `meson` | Tag upstream `v1.0_beta17` — underscore DITOLAK xbps-src di `version=` ("version contains invalid character: _"); `version=1.0.beta17` (titik) + `wrksrc="sfwbar-1.0_beta17"` manual krn nama direktori tarball ikut tag asli. `configure_args="-Dmpd=disabled -Dbsdctl=disabled -Dbluez=disabled -Diwd=disabled"` (modul yg tak dipakai config/sfwbar/sfwbar.config repo ini). Modul yg AKTIF: alsactl, pulsectl, network(nm), dbus, idle, idleinhibit, pipewire, xkb, appmenu, ncenter — semua butuh devel lib yg sudah dideklarasi `makedepends`. |
| **snappy-switcher** (`4.5.0_1`) | manual (`do_build`/`do_install`) | Tak ada tag rilis upstream — dipin ke commit (`_commit=`), distfiles pakai tarball GitHub `archive/<sha>.tar.gz`. Tak ada file LICENSE di repo walau README mengklaim GPL-3.0 (tak ada yg di-`vlicense`). **Makefile upstream TIDAK menghormati `$DESTDIR` sama sekali** — semua path instal pakai `$(PREFIX)` literal, dan `SYSCONFDIR` malah hardcode absolut `/etc/xdg/snappy-switcher` tanpa `$(PREFIX)`. `do_install()` override KEDUANYA: `make PREFIX="${DESTDIR}/usr" SYSCONFDIR="${DESTDIR}/etc/xdg/snappy-switcher" install`. **Konsekuensi penting**: tema ikut `$(PREFIX)/share/...` jadi terpasang di `/usr/share/snappy-switcher/themes/` — BUKAN `/usr/local/share/snappy-switcher/themes/` seperti catatan `sudo make install` manual ala Fedora (lihat README §"Overlay Alt+Tab"), karena PREFIX di-set ke `/usr` di sini, bukan default upstream `/usr/local`. |
| **waypaper** (`2.9_1`) | `python3-pep517` | Tak ada di repo resmi Void, ADA di PyPI. 2 dependensi Python-nya (`imageio-ffmpeg`, `screeninfo`) JUGA tak ada di repo resmi → dipaketkan terpisah (`python3-imageio-ffmpeg`, `python3-screeninfo`, masing-masing `python3-pep517` juga — `screeninfo` pakai `poetry-core` sbg build backend, bukan setuptools, jadi `hostmakedepends="python3-poetry-core ..."`). Semua distfiles pakai `${PYPI_SITE}/<huruf-pertama>/<nama>/<nama>-${version}.tar.gz` (var `PYPI_SITE` sudah didefinisikan xbps-src di `common/environment/setup/misc.sh`, pola URL lawas PyPI yg masih resolve lewat redirect). |

### 3. uinput permission (xremap inject event tanpa root)

**SUDAH terkonfigurasi di mesin ini** — terverifikasi lewat `xremap-gnome-bin`
yang sudah berjalan nyata untuk sesi GNOME (`pgrep -a xremap` menunjukkan PID
aktif membaca `~/.config/gnome-macos-remap/config.yml`), jadi tak ada langkah
baru yang perlu dijalankan:
- `$USER` sudah anggota grup `input` (`groups $USER`).
- Rule udev sudah ada di `/etc/udev/rules.d/input.rules` (nama file beda dari
  dugaan awal, isinya pun pakai pendekatan lebih modern:
  `KERNEL=="uinput", GROUP="input", TAG+="uaccess"` — `uaccess` memberi akses
  ke sesi aktif via elogind/seatd, bukan static mode/group statis).
- `/dev/uinput` sudah ada dgn `crw-rw----+` (grup `input`).

Kalau langkah ini perlu diulang di mesin Void lain yang BELUM punya
`xremap-gnome-bin`/rule serupa, baru jalankan:
```bash
sudo usermod -aG input $USER
echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' \
  | sudo tee /etc/udev/rules.d/99-uinput.rules
echo uinput | sudo tee /etc/modules-load.d/uinput.conf
sudo modprobe uinput
# logout/reboot supaya keanggotaan grup `input` aktif
```

### 4. Font GohuFont (bitmap, terminal + launcher + bar)

```bash
sudo xbps-install gohufont
fc-match "GohuFont:pixelsize=14"   # HARUS balas gohufont-14.pcf.gz, BUKAN
                                   # fallback DejaVu Sans — lihat gotcha di bawah
```

> **Gotcha nyata yang pernah kejadian**: `fc-list | grep gohu` tetap KOSONG
> walau paket terpasang, berkas `.pcf.gz` ada, dan `fc-cache -f` (bahkan
> `sudo fc-cache -f`) dilaporkan sukses meng-cache 8 font dari
> `/usr/share/fonts/misc`. Penyebabnya BUKAN cache — sistem Void ini (dan
> kemungkinan besar instalasi fontconfig modern pada umumnya) memasang
> `/etc/fonts/conf.d/70-no-bitmaps-except-emoji.conf` (symlink ke
> `/usr/share/fontconfig/conf.avail/...`) yang MENOLAK semua font
> `outline=false` DAN `scalable=false` — persis properti PCF bitmap biasa.
> `fc-scan` langsung ke file tetap berhasil baca `family: "GohuFont"` (policy
> ini beroperasi di tahap seleksi/listing, bukan di parsing file), jadi
> `fc-scan` yg "berhasil" BUKAN bukti font akan ketemu lewat nama family.
>
> Perbaikan: file override baru bernama LEBIH BESAR dari `70` (supaya
> diproses belakangan, "acceptfont" menang) yg eksplisit mengizinkan family
> `GohuFont`:
> ```bash
> sudo tee /etc/fonts/conf.d/71-allow-gohufont.conf <<'EOF'
> <?xml version="1.0"?>
> <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
> <fontconfig>
>   <description>Re-allow the GohuFont bitmap family rejected by 70-no-bitmaps-except-emoji.conf</description>
>   <selectfont>
>     <acceptfont>
>       <pattern>
>         <patelt name="family"><string>GohuFont</string></patelt>
>       </pattern>
>     </acceptfont>
>   </selectfont>
> </fontconfig>
> EOF
> sudo fc-cache -f
> fc-match "GohuFont:pixelsize=14"   # harus balas gohufont-14.pcf.gz sekarang
> ```
> File ini di luar `config/` repo (bukan `~/.config`, melainkan `/etc/fonts/`
> sistem) — jadi TIDAK ikut `make link`, cukup sekali per mesin, sama seperti
> session `.desktop` entry Hyprland di §6.

GohuFont cuma punya strike bitmap diskrit 11px/14px (tak bisa di-scale ke
ukuran lain tanpa buram) — `foot.ini` & `fuzzel.ini` dipatok ke **14px**
(pilihan user), `sfwbar` dipatok ke **11px** (ukuran berbeda per-app,
disengaja — lihat gotcha render sfwbar di bawah utk kenapa familinya pun
beda). Cakupannya: terminal + launcher + bar. `mako/config`/`swaylock/config`
SENGAJA tak diubah (tetap Inter).

> **Gotcha nyata yang pernah kejadian (beda dari gotcha rejectfont di atas)**:
> `sfwbar` (GTK3/Cairo) TIDAK BISA merender `GohuFont` mentah (PCF bitmap asli)
> SAMA SEKALI — diverifikasi langsung lewat harness PyGObject berdiri sendiri
> (bukan dugaan): `fontconfig` SUKSES menemukan filenya (`fc-match` balas
> benar), tapi `PangoLayout`/Cairo tetap diam-diam jatuh ke font lain
> (DejaVu Sans atau SF Pro Text lewat rantai fallback) — **apa pun satuan
> ukuran yg dipakai** (pt, px, atau `:pixelsize=` eksplisit pada
> `Pango.FontDescription`). Ini soal jalur RENDERING (rasterisasi PCF legacy
> via Cairo), bukan soal SELEKSI font (`rejectfont` policy) — dua masalah
> berbeda yg kebetulan menimpa font yg sama.
>
> `foot` dan `fuzzel` **TIDAK kena masalah ini** — keduanya link `libfcft.so.4`
> (dicek via `ldd`), bukan GTK/Cairo, dan `fcft` memang dibangun dgn dukungan
> bitmap-font kelas satu. Jadi keduanya tetap pakai `GohuFont:pixelsize=14`
> polos di `foot.ini`/`fuzzel.ini`.
>
> Perbaikan utk sfwbar: pakai varian **`GohuFont 11 Nerd Font Mono`** —
> TTF scalable hasil patch nerd-fonts dari bitmap yg sama persis (sudah
> terpasang via paket NerdFonts, cek `fc-list | grep "GohuFont 11 Nerd Font
> Mono"`), BUKAN keluarga "GohuFont" polos. sfwbar sengaja dipatok 11px
> (beda dgn foot/fuzzel yg 14px) — keputusan user, bukan keterbatasan teknis.
> Sudah diverifikasi lewat CSS cascade GTK sungguhan (bukan cuma
> `Pango.FontDescription` manual, dan dgn varian "14" saat investigasi awal —
> pola resolusinya identik di varian "11"): hasil resolve = `GohuFont 14
> Nerd Font Mono Medium 10.5` persis sesuai
> permintaan, tanpa fallback. `config/sfwbar/sfwbar.config` CSS-nya juga
> dipecah jadi `font-family:`/`font-size:` terpisah (bukan shorthand `font:`)
> saat investigasi ini — tak terbukti itu akar masalahnya, tapi dipertahankan
> krn longhand lebih robust lintas versi GTK3 CSS engine.
>
> Cara verifikasi serupa di masa depan (tanpa perlu akses visual): tulis
> script PyGObject kecil yg bikin `Gtk.CssProvider`, apply CSS yg sama persis
> dgn file config, lalu baca `PangoLayout.get_iter().get_run().item.analysis
> .font.describe()` — itu font yg BENAR-BENAR dipakai utk rasterisasi,
> beda dgn `label.get_pango_context().get_font_description()` yg cuma
> menunjukkan apa yg DIMINTA (bisa beda kalau terjadi fallback diam-diam).

### 5. Salin config ke ~/.config/

```bash
mkdir -p ~/Pictures
make link
```

Jangan timpa config existing tanpa konfirmasi — cek `ls ~/.config/hypr` dulu;
kalau sudah ada isinya, tanyakan ke user apakah mau di-backup atau di-merge.

### 6. Session entry — SUDAH otomatis, tak perlu dibuat manual

Paket `hyprland` dari template `sofijacom/hyprland-void` SUDAH menyertakan
`/usr/share/wayland-sessions/hyprland.desktop` sendiri (terverifikasi langsung
setelah install — dugaan awal rencana ini, "Void tak punya paket resmi = tak
ada .desktop bawaan", SALAH untuk template komunitas ini, koreksi dicatat di
sini). Entry itu memanggil `Exec=/usr/bin/start-hyprland` — **bukan**
`Exec=Hyprland` polos seperti yg sempat direncanakan di sini; `start-hyprland`
adalah tool resmi upstream Hyprland sendiri ("A binary to properly start
Hyprland via a watchdog process", dari `strings /usr/bin/start-hyprland`) yg
mengawasi & bisa me-restart compositor kalau crash — lebih baik drpd exec
langsung, JANGAN ditimpa dgn entry manual.

### 7. Jalankan & verifikasi

- Dari TTY: `Hyprland` — atau pilih sesi **Hyprland** di layar login (GDM
  sudah aktif di mesin ini per cek `/var/service/gdm`... verifikasi ulang kalau
  layar login berubah).
- Saat iterasi: Hyprland **reload otomatis saat file disimpan**; paksa dgn
  `hyprctl reload`. Validasi: `hyprctl configerrors` (kosong = bersih).
- Uji tanpa pertaruhkan sesi aktif: `HYPR_TEST=1 Hyprland -c
  config/hypr/hyprland.lua` (nested instance, autostart di-skip lewat guard
  `HYPR_TEST` di `hyprland.lua`).

> **Gotcha nyata yang pernah kejadian**: nested test di ATAS sesi GNOME/Mutter
> (bukan di atas compositor wlroots lain) CRASH dgn
> `wl_seat (15): expected at most 8, got 9` lalu `CBackend::create() failed!`
> — Mutter versi terbaru expose protokol `wl_seat` v9, sedangkan backend
> aquamarine Hyprland 0.56.2 cuma terima maks v8. Ini BUKAN error config: log
> menunjukkan `[cfg] Config is lua, loading lua mgr` sukses duluan, crash
> baru terjadi jauh SETELAH config selesai di-parse, di tahap pembuatan
> backend grafis. Konsekuensi: nested test di mesin ini (sesi aktifnya GNOME)
> tak bisa dipakai utk validasi runtime penuh — cuma membuktikan Lua-nya
> ter-load tanpa syntax error. Validasi runtime sungguhan (keybind, rule
> window, dll) WAJIB logout dari GNOME lalu pilih sesi Hyprland dari layar
> login, bukan via nested test dari dalam sesi ini.

Checklist verifikasi:
1. `pgrep xremap sfwbar mako snappy-wrapper` → semua jalan.
2. GUI copy: fokus field teks di browser → **Super+C / Super+V**.
3. Smart terminal: di foot, seleksi teks → **Super+C** copy; jalankan
   `sleep 100` → **Ctrl+C** interrupt (SIGINT).
4. Window: **Super+Space** buka fuzzel; **Super+Q** close; **Super+Left/Right**
   fokus; **Super+1..8** ganti workspace (bar menampilkan I..VIII);
   **Ctrl+Shift+Print** screenshot region ke `~/Pictures` (screenshot HANYA
   lewat `Print` key family, bukan `Super+Shift+N`).
5. `fc-match "GohuFont:pixelsize=14"` balas `gohufont-14.pcf.gz` (BUKAN
   fallback DejaVu — kalau fallback, lihat gotcha policy bitmap-font di §4);
   foot & fuzzel tampil bitmap tajam (bukan buram/di-scale) di 14px; sfwbar
   pakai varian TTF `GohuFont 11 Nerd Font Mono` (11px, gotcha rendering di §4).
6. `cmus`, putar lagu → modul bar berubah jadi "Artist - Title"; stop cmus →
   balik ke "[cmus off]"/"[cmus stopped]" tanpa crash sfwbar.
7. Panel fastfetch (foot `--app-id fastfetch-panel`) muncul pinned di posisi
   yang diset di `local.lua`, gambar logo tampil via sixel (cek dulu build
   `foot` di Void tak mematikan sixel — kalau tak muncul, ganti `logo.type` di
   `config/fastfetch/config.jsonc` ke `"kitty"` atau ASCII polos), dan setelah
   fastfetch selesai window tetap jadi shell interaktif.
8. `Ctrl+Super+Q` → fuzzel powermenu; Log Out → `loginctl list-sessions` tak
   lagi menunjukkan sesi itu (bukan cuma compositor mati).

## Catatan class window polkit-gnome (belum terverifikasi)

`hyprland.lua` menebak class dialog polkit-gnome sbg
`"Polkit-gnome-authentication-agent-1"` (rule `float-polkit-gnome`) — path
binary-nya sudah terverifikasi (`/usr/libexec/polkit-gnome-authentication-agent-1`,
dari `xbps-query -R -f polkit-gnome`), tapi nama `class` window GTK-nya BELUM
bisa dipastikan tanpa sesi Hyprland hidup + dialog itu benar-benar muncul
(trigger: aksi yang butuh otorisasi, mis. mount disk dari file manager). Cek
`hyprctl clients` saat dialog itu tampil, perbaiki regex match kalau beda.

## Tradeoff yang disengaja (bukan bug)

- **Cmd+panah (navigasi teks) dihilangkan** — panah dipakai fokus/pindah
  window. Home/End native tetap jalan; bisa ditambah lewat xremap kalau diminta.
- **Cmd+1..9 (tab browser) dihilangkan** — digit untuk ganti workspace. Pakai
  Ctrl+Tab.
- **Tidak ada Mission Control/Exposé native** — 3-jari swipe workspace jadi
  penggantinya. Plugin `hyprexpo` belum dipasang (butuh `hyprpm` + header
  build) — tawarkan hanya kalau user minta.
- **Cmd+W** = close-tab aplikasi (`Ctrl+W`); tutup window = **Cmd+Q**.
- **Tidak ada minimize sungguhan** — `Super+M/H` memarkir window di
  `special:minimized`, `Super+Shift+M` memunculkannya kembali.
- **cmus harus jalan + ada lagu dimuat** supaya modul bar berisi sesuatu —
  ini keputusan desain (poll `cmus-remote -Q`), bukan bug kalau modul kosong
  saat cmus mati.

## Catatan

- Jangan commit/push kecuali user memintanya.
- Kalau user memodifikasi keybind, edit file di `config/` (sumber kebenaran);
  Hyprland reload otomatis saat file disimpan.
- Branch ini **bukan** tempat mengubah config labwc/dwl — itu di branch
  `master`, untuk mesin Fedora user yang lain. Jangan port perubahan dari sana
  ke sini tanpa diminta, dan sebaliknya.
- `KEYMAP.md`/`KEYMAP.en.md` masih versi tri-compositor dari `master` — belum
  dipangkas untuk branch ini (di luar cakupan kerja saat file ini ditulis).
  Rujuk `config/hypr/hyprland.lua` langsung sbg sumber kebenaran keybind.
- `assets/preview.png` juga masih screenshot dari setup Fedora/labwc lama —
  ganti kalau sudah ada screenshot rice baru di mesin ini.

## Gotcha nyata: ganti sesi GNOME → Hyprland di TTY yang sama tanpa logout penuh

Mesin ini punya dua sesi (GNOME harian + Hyprland rice). Kalau beralih dari
GNOME ke Hyprland TANPA logout penuh (mis. switch sesi di layar login yang
mendaur-ulang TTY yang sama alih-alih membuka TTY baru), proses `xremap`
milik sesi GNOME lama (`xremap-gnome-bin`, baca
`~/.config/gnome-macos-remap/config.yml`) bisa **tetap hidup** — persis
seperti gejala "Duplicate helpers leaking across sessions" yg sudah dicatat
di `master` README, tapi di sini pemicunya lintas-WM (GNOME→Hyprland), bukan
dua sesi WM yang sama. Dua instance xremap (lama + `xremap-hypr` baru) lalu
rebutan `EVIOCGRAB` atas keyboard/mouse fisik yang sama → **semua keybind
Hyprland maupun remap xremap jadi tak berfungsi/erratic**, padahal
`hyprctl configerrors` kosong dan `hyprctl binds` menunjukkan binding
terdaftar normal (config-nya SEHAT, masalahnya di lapisan input device).

Diagnosa: `grep -c 'Name="xremap' /proc/bus/input/devices` — kalau hasilnya
**>1**, ada xremap ganda. Cocokkan tiap device sama proses lewat
`pgrep -af xremap` (cek config yg dibaca tiap PID — `gnome-macos-remap` vs
`xremap/config.yml` jadi penanda sesi mana yg basi).

Perbaikan manual (kalau belum reload config/belum restart Hyprland):
`kill <PID xremap sesi lama>` — device virtualnya ikut hilang otomatis begitu
prosesnya mati, tak perlu langkah lain. Keybind pulih seketika setelah itu,
tanpa restart Hyprland.

**Sudah diotomatiskan** (kejadian berulang terlalu sering utk ditangani
manual tiap kali): `config/hypr/hyprland.lua` sekarang menjalankan
`pkill -x xremap` di `hyprland.start`, TEPAT SEBELUM menyalakan
`xremap-hypr`. `pkill -x` cocok nama proses PERSIS ("xremap"), jadi tak
pernah ikut membunuh `xremap-hypr` sendiri (nama binary beda, lihat §2b).
Konsekuensi: proses GNOME `xremap` yg nyangkut otomatis direap setiap kali
sesi Hyprland start — baik lewat boot/login baru maupun switch sesi di
layar login yang mendaur-ulang TTY. Kalau gejala ini muncul lagi SETELAH
perbaikan ini (keybind erratic pasca restart), curigai xremap-gnome-bin
start ULANG setelah `hyprland.start` jalan (race lintas-DM), bukan gagal
reap — cek `pgrep -af xremap` dulu sebelum asumsi fix-nya rusak.

## Gotcha nyata: Super+Shift+3/4 bentrok dgn "pindah window ke workspace 3/4"

`hyprland.lua` sempat punya DUA bind berbeda pada kombinasi tombol yg SAMA
PERSIS: loop workspace (`for i = 1, 8 do hl.bind(mod.." + SHIFT + "..i, ...
window.move) end`) mendaftarkan `Super+Shift+3` dan `Super+Shift+4` utk
"pindah window aktif ke workspace 3/4" — lalu BEBERAPA BARIS DI BAWAHNYA,
blok screenshot mendaftarkan kombinasi tombol yg SAMA utk screenshot
(`Super+Shift+3` = screenshot full, `+4` = screenshot area, meniru macOS).

Di Lua config Hyprland, bind kedua pada kombinasi tombol yg identik
**MENGGANTIKAN** yg pertama — bukan error, bukan warning, `hyprctl binds`
cuma menunjukkan satu entri (yg terakhir didaftarkan) utk kombinasi itu.
Konsekuensi: `Super+Shift+3/4` HANYA mengambil screenshot; "pindah window ke
workspace 3/4" via kombinasi itu tak pernah benar-benar terdaftar — diam-diam
hilang, baru ketahuan saat user coba pakainya scr langsung.

Perbaikan: pindah SELURUH grup "pindah window ke workspace N" (N=1..8, bukan
cuma 3/4 — biar modifier tetap konsisten lintas semua slot) ke
**`CTRL+Super+N`**, bukan `Super+Shift+N`. Dipilih krn CTRL+Super sudah
dipakai utk tema "pindah workspace" lain (`CTRL+Super+Left/Right` = kirim
window ke workspace tetangga relatif) — satu modifier, satu tema.

**Update lanjutan (keputusan user)**: alih-alih cuma memindah screenshot ke
modifier lain, `Super+Shift+3/4` (dan turunannya `CTRL+Super+Shift+3/4` utk
clipboard) **DIBUANG SELURUHNYA** dari screenshot — screenshot sekarang
HANYA lewat `Print` key family (`Print`/`Shift+Print`/`Ctrl+Print`/
`Ctrl+Shift+Print`, sudah ada & tetap jalan apa adanya). Alasan: slot digit
3/4/5 dibebaskan total supaya kelas masalah yg sama (dua `hl.bind` pada
kombinasi identik, salah satu diam-diam kalah) tak bisa kejadian lagi kalau
ada fitur lain nanti yg "kebetulan" butuh `Super+Shift+<digit>`.

Cara ketahuan kalau kejadian lagi di tempat lain: `hyprctl binds -j | jq
'.[] | select(.key=="<digit>")'` (atau pola python serupa) — kalau CUMA ada
SATU entri utk kombinasi yg kamu kira didaftarkan dua kali, salah satunya
kalah. Bandingkan urutan baris `hl.bind(...)` di file: yg terakhir menang.
