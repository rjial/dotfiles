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
  fuzzel/fuzzel.ini    # launcher — font tetap JetBrains Mono (tak diubah)
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
# template yang ditempel bisa di-commit+push ke fork sendiri, bukan cuma lokal
git clone https://github.com/rjial/void-packages
cd void-packages && ./xbps-src binary-bootstrap && cd ..

git clone https://github.com/sofijacom/hyprland-void.git
cat hyprland-void/common/shlibs >> void-packages/common/shlibs
cp -r --remove-destination hyprland-void/srcpkgs/* void-packages/srcpkgs/

cd void-packages
./xbps-src pkg hyprland
sudo xbps-install --repository=hostdir/binpkgs hyprland xdg-desktop-portal-hyprland

# opsional tapi disarankan: simpan template yang baru ditempel ke fork sendiri.
# Commit dulu SEBELUM pull --rebase — rebase di atas working tree yang masih
# kotor berisiko (autostash bisa gagal/konflik); commit dulu baru rebase aman.
git add srcpkgs common/shlibs
git commit -m "Add hyprland-void templates"
git pull --rebase   # bukan merge — fork bisa sudah berubah di remote sejak
                    # clone, rebase menjaga histori tetap linear
git push
```

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

#### 2b. sfwbar, snappy-switcher, xremap, waypaper (tulis template sendiri)

Tak ada template komunitas siap pakai untuk keempat ini (sudah dicek via
pencarian web) — tulis manual di `srcpkgs/<nama>/template`. Alur umum:

```bash
cd ~/void-packages
mkdir -p srcpkgs/<nama>
$EDITOR srcpkgs/<nama>/template
./xbps-src pkg <nama>
sudo xbps-install --repository=hostdir/binpkgs <nama>
```

Per paket (deps PERSIS wajib diverifikasi dari source upstream masing-masing
saat ditulis — jangan ditebak dari daftar ini):

| Paket | `build_style` | Catatan |
|---|---|---|
| **sfwbar** | `meson` | hostmakedepends/makedepends (gtk+3-devel, json-glib-devel, dll) dari `meson.build` upstream sfwbar. |
| **snappy-switcher** | `gnu-makefile` atau `do_build`/`do_install` manual | upstream pakai `make`/`make install` biasa, bukan meson — cek `Makefile` upstream (`github.com/OpalAayan/snappy-switcher`) untuk target+flag yang benar. |
| **xremap** | `cargo` | pakai cargo feature `--features wlroots` di template — WAJIB, tanpa itu deteksi per-app (blok `foot`) tak jalan. |
| **waypaper** | `python3-pep517` | tak ada di repo resmi maupun PyPI index resmi Void, tapi ADA di PyPI (versi 2.9 saat dicek) — template menarik sdist dari sana. |

### 3. uinput permission (xremap inject event tanpa root)

```bash
sudo usermod -aG input $USER
echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' \
  | sudo tee /etc/udev/rules.d/99-uinput.rules
echo uinput | sudo tee /etc/modules-load.d/uinput.conf
sudo modprobe uinput
```
> Keanggotaan grup `input` baru aktif setelah **logout/reboot**. Ingatkan user.

### 4. Font GohuFont (bitmap, terminal + bar saja)

```bash
sudo xbps-install gohufont
fc-list | grep -i gohu   # pastikan nama family persis "GohuFont" sebelum
                         # dipercaya oleh foot.ini / CSS sfwbar
```

GohuFont cuma punya strike bitmap diskrit 11px/14px (tak bisa di-scale ke
ukuran lain tanpa buram) — `foot.ini` & CSS sfwbar sudah dipatok ke **14px**
(lebih terbaca di bar 24px daripada 11px). `fuzzel.ini`/`mako/config`/
`swaylock/config` SENGAJA tak diubah (tetap JetBrains Mono/Inter) — cakupan
GohuFont hanya terminal + bar sesuai permintaan user.

### 5. Salin config ke ~/.config/

```bash
mkdir -p ~/Pictures
make link
```

Jangan timpa config existing tanpa konfirmasi — cek `ls ~/.config/hypr` dulu;
kalau sudah ada isinya, tanyakan ke user apakah mau di-backup atau di-merge.

### 6. Session entry (Void tak punya paket Hyprland resmi = tak ada `.desktop` bawaan)

```bash
sudo tee /usr/share/wayland-sessions/hyprland.desktop <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
```

### 7. Jalankan & verifikasi

- Dari TTY: `Hyprland` — atau pilih sesi **Hyprland** di layar login (GDM
  sudah aktif di mesin ini per cek `/var/service/gdm`... verifikasi ulang kalau
  layar login berubah).
- Saat iterasi: Hyprland **reload otomatis saat file disimpan**; paksa dgn
  `hyprctl reload`. Validasi: `hyprctl configerrors` (kosong = bersih).
- Uji tanpa pertaruhkan sesi aktif: `HYPR_TEST=1 Hyprland -c
  config/hypr/hyprland.lua` (nested instance, autostart di-skip lewat guard
  `HYPR_TEST` di `hyprland.lua`).

Checklist verifikasi:
1. `pgrep xremap sfwbar mako snappy-wrapper` → semua jalan.
2. GUI copy: fokus field teks di browser → **Super+C / Super+V**.
3. Smart terminal: di foot, seleksi teks → **Super+C** copy; jalankan
   `sleep 100` → **Ctrl+C** interrupt (SIGINT).
4. Window: **Super+Space** buka fuzzel; **Super+Q** close; **Super+Left/Right**
   fokus; **Super+1..8** ganti workspace (bar menampilkan I..VIII);
   **Super+Shift+4** screenshot region ke `~/Pictures`.
5. `fc-list | grep -i gohu` menemukan family GohuFont; foot & sfwbar tampil
   bitmap tajam (bukan buram/di-scale) di 14px.
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
