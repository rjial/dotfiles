# macOS-style Hyprland dotfiles (Void Linux)

Hyprland config dgn shortcut ala macOS, di-port dari branch `master` (Fedora,
tiga compositor) ke satu compositor saja untuk mesin **Void Linux** (runit +
elogind). Nuansa visual: bar teks-only ala polybar, font bitmap **GohuFont**
(terminal + bar), panel `fastfetch`+foto pinned, workspace diberi label angka
romawi — mengulang rice lama user (bspwm + polybar + urxvt + neofetch) tapi di
atas Hyprland.

`Super` = tombol **Cmd**. `xremap` me-remap huruf shortcut aplikasi
(`Super+c/v/x/s/z/…`) jadi `Ctrl+` supaya app GUI terasa mac-like; tombol
window-management (`Super+q/m/h/space/tab/grave/arrows/digits`) diteruskan ke
Hyprland. Launcher = **fuzzel** (Spotlight), terminal = **foot** (smart copy:
Cmd+C = copy, Ctrl+C asli = SIGINT), bar = **sfwbar**, wallpaper = **waypaper**.

> Branch `master` (Fedora) masih punya referensi keybind lintas-WM yang lebih
> lengkap di `KEYMAP.md`/`KEYMAP.en.md` — dokumen itu BELUM di-pangkas ulang
> untuk branch ini (keluar dari cakupan kerja saat ini) dan masih menyebut
> labwc/dwl yang sudah tak ada di sini. Rujuk `config/hypr/hyprland.lua`
> langsung sbg sumber kebenaran keybind di branch ini.

## Layout

```
config/
  xremap/config.yml    # engine remap Cmd->Ctrl (blok foot HARUS pertama)
  hypr/hyprland.lua    # Hyprland: keybind + env + autostart + efek (satu file)
  mako/config          # notification daemon (toast + OSD)
  scripts/powermenu    # power menu fuzzel (lock/logout/suspend/…)
  scripts/osd          # renderer OSD generik lewat mako
  scripts/volumectl    # volume/mute via wpctl + OSD
  scripts/brightctl    # backlight via brightnessctl + OSD
  scripts/fastfetch-panel    # launcher panel fastfetch+foto pinned
  scripts/xdg-autostart      # jalankan entri autostart .desktop
  scripts/xdg-autostart.skip # entri yang TAK boleh jalan
  swaylock/config      # tema lock screen
  foot/foot.ini        # terminal — font GohuFont:pixelsize=14
  fuzzel/fuzzel.ini    # launcher
  sfwbar/sfwbar.config # bar teks-only (taskbar + workspace romawi + status + power)
  sfwbar/wsctl         # baca/ganti workspace aktif (Hyprland IPC)
  sfwbar/cmus-status   # modul now-playing cmus utk bar
  fastfetch/config.jsonc     # panel info sistem + foto
  snappy-switcher/     # overlay Alt+Tab (butuh Hyprland IPC)
  waypaper/            # wallpaper picker (config.ini di-gitignore = state)
Makefile               # symlink manager (config/* -> ~/.config/*)
CLAUDE.md              # catatan deploy/arsitektur
```

`make link` mem-symlink tiap dir di `DIRS` (`Makefile:15`) ke `~/.config/`.
Menambah **dir baru** di `config/` WAJIB ditambah ke `DIRS` juga.

## 1. Install paket

```bash
# sudah terverifikasi ADA di repo resmi Void (xbps-query -Rs <nama>):
sudo xbps-install foot fuzzel mako swaylock grim slurp wl-clipboard swaybg \
  cmus fastfetch polkit-gnome gohufont
```

> **GohuFont butuh satu langkah tambahan**, bukan cuma `xbps-install` — lihat
> `CLAUDE.md` §4. Fontconfig modern (termasuk di mesin ini) default MENOLAK
> semua font bitmap lewat `/etc/fonts/conf.d/70-no-bitmaps-except-emoji.conf`;
> tanpa override tambahan, `fc-match "GohuFont"` diam-diam jatuh ke DejaVu Sans
> walau paketnya sudah terpasang dgn benar.

```bash

# elogind + dbus biasanya sudah aktif secara default di instalasi desktop Void
# (runit service di /var/service/{dbus,elogind}) — cek dulu:
sv status dbus elogind
```

**Hyprland sendiri TIDAK ADA di repo resmi Void**, begitu juga sebagian besar
ekosistemnya (`hyprlang`, `hyprcursor`, `hyprgraphics`, `aquamarine`,
`xdg-desktop-portal-hyprland` — hanya `hyprutils` & `hyprwayland-scanner` yang
sudah ada). Build lewat `~/void-packages`, pakai template komunitas yang
aktif dipelihara (versi Hyprland 0.56.2, SAMA dgn yang dipakai di branch
master Fedora — `hyprland.lua` kompatibel tanpa port ulang):

```bash
mkdir -p ~/repos && cd ~/repos
# cek dulu: ls ~/void-packages — jangan clone ulang kalau sudah ada.
# Fork pribadi user, BUKAN void-linux/void-packages upstream langsung.
git clone https://github.com/rjial/void-packages
cd void-packages && ./xbps-src binary-bootstrap && cd ..

git clone https://github.com/sofijacom/hyprland-void.git
cat hyprland-void/common/shlibs >> void-packages/common/shlibs
cp -r --remove-destination hyprland-void/srcpkgs/* void-packages/srcpkgs/

cd void-packages
# remote "origin" di sini = fork sendiri (hasil clone di atas). Tambah remote
# "upstream" kalau belum ada, lalu WAJIB sync dgn upstream SEBELUM build —
# fork bisa ketinggalan versi (mis. mesa) dibanding apa yg sudah live di repo
# binary resmi, dan xbps-src lalu memutuskan BUILD DARI SOURCE (mesa+llvm+rust,
# puluhan menit) padahal binary resminya sudah ada. Commit dulu template yg
# baru ditempel, baru pull upstream.
git remote add upstream https://github.com/void-linux/void-packages 2>/dev/null
git add srcpkgs common/shlibs && git commit -m "Add hyprland-void templates"
git fetch upstream && git pull --rebase upstream master

# `xbps-src pkg` cuma terima SATU nama paket per panggilan — dua baris
# terpisah, bukan `pkg hyprland xdg-desktop-portal-hyprland` sekaligus
# (argumen kedua diam-diam diabaikan, tanpa pesan error apa pun).
./xbps-src pkg hyprland                      # build Hyprland + seluruh dependensinya
./xbps-src pkg xdg-desktop-portal-hyprland
sudo xbps-install --repository=hostdir/binpkgs hyprland xdg-desktop-portal-hyprland

# simpan template ke fork sendiri (commit sudah di atas, tinggal push)
git push origin master
```

> **Gotcha nyata yang pernah kejadian**: `cat hyprland-void/common/shlibs >>
> void-packages/common/shlibs` bisa membawa baris STALE kalau template-nya
> baru saja naik versi minor tapi `common/shlibs` upstream-nya belum
> di-update (persis terjadi pada `hyprutils`: template bilang `0.14.1`, tapi
> `common/shlibs` mereka masih `0.14.0`). xbps-src `99-pkglint` lalu menolak
> build dgn `SONAME bump detected` — bukan krn ada yg salah, tapi krn baris
> LAMA utk `hyprutils` (dari template resmi yg sudah ditimpa) masih nyangkut
> di file dan bikin cocok ganda. Perbaikannya: pastikan tiap `pkgname` cuma
> 1 baris di `common/shlibs` yg relevan dgn versi template SAAT INI — hapus
> baris lama kalau ada (`grep <pkgname> common/shlibs` dulu utk cek).

> Cek dulu [`sofijacom/hyprland-void`](https://github.com/sofijacom/hyprland-void)
> masih jadi fork paling aktif sebelum dipakai — proyek komunitas begini bisa
> pindah maintainer. Repo yang sama juga menyediakan binary pre-built pihak
> ketiga (`/etc/xbps.d/hyprland-void.conf`) sebagai jalur lebih cepat, TAPI itu
> bukan default di sini — build dari source sendiri lebih bisa diaudit.

`xremap` sendiri tak perlu di-build dari source — upstream menyediakan binary
rilis per-backend compositor. Varian Hyprland (`xremap-hypr-bin`, SUDAH ditulis
& dibangun) dipasang sbg `/usr/bin/xremap-hypr` (bukan `/usr/bin/xremap` polos)
supaya tak bentrok dgn `xremap-gnome-bin` yang sudah terpasang untuk sesi
GNOME — lihat `CLAUDE.md` §2b.

`sfwbar`, `snappy-switcher`, `waypaper` masih tak ada di repo resmi Void
maupun template komunitas — ditulis manual di
`~/void-packages/srcpkgs/<nama>/template` (lihat `CLAUDE.md` §"Paket custom
lewat `~/void-packages`" untuk `build_style` masing-masing).

## 2. uinput permission (xremap inject event tanpa root)

Sudah terkonfigurasi di mesin ini (`xremap-gnome-bin` sudah berjalan untuk
sesi GNOME membuktikannya — lihat `CLAUDE.md` §3). Kalau mesin lain belum:

```bash
sudo usermod -aG input $USER
echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' \
  | sudo tee /etc/udev/rules.d/99-uinput.rules
echo uinput | sudo tee /etc/modules-load.d/uinput.conf
sudo modprobe uinput
# logout/reboot supaya keanggotaan grup `input` aktif
```

## 3. Deploy config (symlink via make)

```bash
cd ~/Documents/dotfiles     # atau lokasi clone repo ini
make link        # symlink config/* -> ~/.config/
mkdir -p ~/Pictures
```

| target | aksi |
|---|---|
| `make link`   | symlink `config/*` → `~/.config/` (backup dir asli ke `.bak`) |
| `make unlink` | hapus semua symlink, restore `.bak` kalau ada |
| `make relink` | unlink lalu link ulang |
| `make status` | tampilkan status tiap symlink |

Jangan timpa config existing tanpa konfirmasi — cek `ls ~/.config/hypr` dulu;
kalau sudah ada isinya, putuskan backup atau merge.

## 4. Jalankan & verifikasi

Session entry `/usr/share/wayland-sessions/hyprland.desktop` **sudah ikut
terpasang** dari paket `hyprland` (template `sofijacom/hyprland-void`) — tak
perlu dibuat manual. Isinya `Exec=/usr/bin/start-hyprland`, watchdog resmi
upstream Hyprland (bukan exec `Hyprland` polos) yg bisa restart compositor
kalau crash — biarkan apa adanya.

Log out → pilih **Hyprland** di layar login, atau dari TTY: `Hyprland`.
Hyprland **reload otomatis saat file disimpan**; paksa dgn `hyprctl reload`.

Checklist verifikasi:
1. `pgrep xremap sfwbar mako snappy-wrapper` — semua jalan.
2. GUI copy: fokus field teks di browser → **Super+C / Super+V**.
3. Smart terminal: di foot, seleksi teks → **Super+C** copy; `sleep 100` →
   **Ctrl+C** interrupt (SIGINT).
4. Window: **Super+Space** fuzzel; **Super+Q** close; **Super+1..8** ganti
   workspace (bar menampilkan I..VIII); **Super+Shift+4** screenshot region.
5. `fc-match "GohuFont:pixelsize=14"` balas `gohufont-14.pcf.gz` (bukan
   fallback DejaVu — kalau fallback, cek `CLAUDE.md` §4: fontconfig modern
   biasa menolak SEMUA font bitmap lewat `70-no-bitmaps-except-emoji.conf`,
   perlu override tambahan utk mengizinkan `GohuFont` khusus). Teks di foot &
   sfwbar tampil bitmap tajam di 14px, bukan buram.
6. cmus + lagu diputar → modul bar berubah jadi "Artist - Title".
7. Panel fastfetch (foot `--app-id fastfetch-panel`) muncul pinned, gambar
   tampil via sixel, dan jadi shell interaktif setelah fastfetch selesai.

### Monitor Anda

Tak ada yang di-hardcode: `hl.monitor({ output = "", mode = "preferred", … })`
cocok untuk output apa pun. Monitor spesifik / multi-monitor? Jangan edit
`hyprland.lua` — tulis di **`~/.config/hypr/local.lua`** (dibuat otomatis oleh
`make link`, gitignored, `dofile`'d paling bawah):

```lua
hl.monitor({ output = "eDP-1",    mode = "1920x1080@60",  position = "0x0",    scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "1920x0", scale = 1 })
```

### Picture-in-Picture

Dua rule, karena browser punya dua mekanisme PiP berbeda:

| Rule | Berlaku untuk | Cara match |
|---|---|---|
| `pip` | video PiP klasik (YouTube, Netflix, `<video>`) | title `Picture-in-picture` — window TANPA app-id sama sekali |
| `pip-document` | Document PiP API (**Google Meet**, Discord, YouTube Music) | class browser + match `negative:` pada title |

Detail lengkap (kenapa Meet butuh rule terpisah, kenapa `negative:` bukan
lookahead) ada sbg komentar di `config/hypr/hyprland.lua`.

### Overlay Alt+Tab (snappy-switcher)

`Alt+Tab`/`Super+Tab` membuka **snappy-switcher** — overlay switcher ala
Cmd+Tab macOS. Hyprland-only (baca daftar window + MRU lewat Hyprland IPC).
Tak ada paket Void — build dari source:

```bash
git clone https://github.com/OpalAayan/snappy-switcher ~/Dokumen/snappy-switcher
cd ~/Dokumen/snappy-switcher && make && sudo make install
```

Jangan jalankan `snappy-install-config` upstream — repo ini sudah pegang
`config/snappy-switcher/config.ini`, `make link` yang men-symlink-nya. Tema
tak di-vendor; binary cari di `~/.config/snappy-switcher/themes/` lalu
`/usr/local/share/snappy-switcher/themes/` (lokasi `sudo make install`),
jadi `name = catppuccin-frappe.ini` ketemu sendiri.

Verifikasi: `pgrep -x snappy-switcher`.

## Workspace pager

Workspace di bar (angka romawi I-VIII) **bukan** widget `pager` bawaan
sfwbar — widget itu cuma baca state Hyprland sekali saat start lalu berhenti
menyimak event fokus (man sfwbar: *"Placer and pager require sway"*).
Pengganti: `config/sfwbar/wsctl` (python3 tanpa dependensi):

```
wsctl watch    cetak {"ws": N} tiap workspace aktif berubah
wsctl set N    pindah ke workspace N (hyprctl dispatch)
```

Ganti label romawi berarti edit DUA file yang harus tetap sinkron:
`config/hypr/hyprland.lua` (`ws_names`) dan `config/sfwbar/sfwbar.config`
(label `value` di grid `pager`).

## OSD volume & brightness

Keybind `XF86Audio*`/`XF86MonBrightness*` memanggil
`config/scripts/volumectl`/`brightctl`, bukan `wpctl`/`brightnessctl`
langsung — wrapper ini yang membaca ULANG nilai setelah aksi (clamp di kedua
ujung) dan menampilkan OSD via `config/scripts/osd` (toast + progress bar
dari hint `value` mako, bukan widget terpisah).

> Gotcha: `brightnessctl -n 1` (pakai spasi) diam-diam tak melakukan apa-apa —
> `-n` punya argumen opsional, jadi `1` yang terpisah dibaca sbg *operation*.
> Harus `-n1` menempel.

## XDG autostart

Hyprland tak memproses entri `.desktop` autostart sama sekali, jadi
`config/scripts/xdg-autostart` (parser shell ~100 baris) dipanggil paling
akhir dari `hyprland.lua` setelah daemon inti (xremap, sfwbar, mako, dll)
hidup. Daftar yang DIBUANG (bukan allowlist) ada di
`config/scripts/xdg-autostart.skip`.

```bash
~/.config/scripts/xdg-autostart -n   # dry run
~/.config/scripts/xdg-autostart      # jalankan
~/.config/scripts/xdg-autostart -k   # bunuh hasil run sebelumnya
```

## Power menu

`Ctrl+Cmd+Q` membuka `config/scripts/powermenu` (`fuzzel --dmenu`): Lock,
Log Out, Suspend, Reboot, Shut Down — tiga aksi terakhir butuh konfirmasi
kedua. Log Out pakai `loginctl terminate-session` (lewat elogind), BUKAN
`Super+Shift+Q` (itu cuma membunuh compositor, bukan menutup sesi logind).
`poweroff`/`reboot`/`suspend` tak butuh sudo (logind + polkit, `polkit-gnome`
sudah di-autostart).

## Panel fastfetch + foto

Pengganti panel neofetch+foto di rice lama: window foot pinned
(`--app-id fastfetch-panel`, dari `config/scripts/fastfetch-panel`) yang
menjalankan `fastfetch` (config di `config/fastfetch/config.jsonc`) dgn logo
foto via protokol **sixel**, lalu jatuh ke shell interaktif. `logo.source` di
config menunjuk ke foto milik Anda sendiri — isi path-nya sebelum dipakai.

Kalau build `foot` di Void mematikan sixel, gambar tak akan muncul — cek
dulu, fallback `logo.type: "kitty"` atau ASCII polos di `config.jsonc`.

## Tradeoff yang disengaja (bukan bug)

- **Cmd+panah (navigasi teks) dihilangkan** — panah dipakai fokus/pindah
  window. Home/End native tetap jalan.
- **Cmd+1..9 (tab browser) dihilangkan** — digit untuk ganti workspace.
  Pakai Ctrl+Tab.
- **Tidak ada Mission Control/Exposé native** — 3-jari swipe workspace jadi
  penggantinya. Plugin `hyprexpo` belum dipasang (butuh `hyprpm` + header
  build).
- **Cmd+W** = close-tab aplikasi (`Ctrl+W`); tutup window = **Cmd+Q**.
- **Tidak ada minimize sungguhan** — `Super+M/H` memarkir window di
  `special:minimized`, `Super+Shift+M` memunculkannya kembali.

## Catatan

- Jangan commit/push kecuali user memintanya.
- Kalau user memodifikasi keybind, edit file di `config/` (sumber kebenaran),
  lalu `hyprctl reload` (otomatis saat save, biasanya tak perlu manual).
- `KEYMAP.md`/`KEYMAP.en.md` masih versi tri-compositor dari branch master —
  belum di-pangkas untuk branch ini, lihat catatan di bagian atas README ini.
