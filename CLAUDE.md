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
  labwc/menu.xml       # menu klik-kanan
  hypr/hyprland.conf   # sesi Hyprland (keybind+env+autostart+efek, satu file)
  foot/foot.ini        # terminal
  fuzzel/fuzzel.ini    # launcher
README.md              # dokumentasi lengkap (rujukan)
```

## Tugas deploy (jalankan berurutan, konfirmasi ke user di tiap langkah sudo)

### 1. Install paket
```bash
sudo dnf install labwc fuzzel foot grim slurp swaybg wl-clipboard
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
```bash
git clone https://codeberg.org/dwl/dwl ~/src/dwl
git clone https://github.com/kolunmi/dwlb ~/src/dwlb   # kalau pakai dwlb
```

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
1. `~/src/dwl/config.h` — mirror keybind labwc `rc.xml`:
   - MODKEY = Super (Cmd). Snap → tag/layout dwl. Screenshot (grim/slurp),
     media key (wpctl), launcher fuzzel, terminal foot.
   - Digit 1-9 = tags (bukan workspace). Tetap SISAKAN huruf shortcut app
     (c/v/x/s/z/…) untuk xremap — jangan bind di dwl.
2. `config/dwl/` di repo — salinan `config.h`, autostart, config dwlb (sumber
   kebenaran, sama pola seperti `config/labwc/`).
3. autostart dwl: `lxpolkit`, `xremap`, `waypaper --restore`, bar (`dwlb` atau
   `sfwbar`) — dwl jalankan lewat flag `-s` (startup command) atau script.

## Sumber kebenaran & sinkronisasi
Sama seperti labwc: edit di `config/dwl/` (repo) DULU, lalu salin ke lokasi
pakai. Beda: dwl `config.h` harus **recompile** tiap ubah, bukan sekadar salin.

---

# Sesi Hyprland (tiling + efek) — `config/hypr/hyprland.conf`

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
Fedora 42 repo = `hyprland 0.45.2`. Session entry `.desktop` **ikut paket**
(`/usr/share/wayland-sessions/hyprland.desktop`) — jangan bikin sendiri (beda
dgn labwc/dwl yang perlu `sudo cp ... /usr/share/wayland-sessions/`).

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
`cornerRadius` labwc) · gradient border surface2→teal · `workspace_swipe` 3 jari
· `special:minimized` · `layerrule blur` untuk sfwbar & fuzzel · `resize_on_border`
· `follow_mouse = 0` (click-to-focus, mac-like, sama labwc) · `misc:vfr`.

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
- **`ExecClient` tak lewat shell** (beda dgn action `Exec` yang lewat shell), jadi
  `$HOME` tak diekspansi. Wajib dibungkus: `ExecClient("sh -c 'exec $HOME/…'", "ws")`.
- **Nama style dari expression, bukan class** — `style = If(WsActive=1,"ws_on","ws_off")`
  plus `trigger = "ws"` di tiap label. CSS pakai `#ws_on` / `#ws_off`.
- Nama style tombol taskbar = `#taskbar_item` dgn class `.active`. Bukan
  pseudo-class `:active` (itu "sedang ditekan").
- Glyph workspace harus sama di tiga file: `labwc/rc.xml` `<desktops><names>`,
  `hypr/hyprland.conf` `defaultName:`, `sfwbar/sfwbar.config` label `value`.
- labwc: tiap `GoToDesktop` di `rc.xml` WAJIB dipasangkan `Execute wsctl mark N`
  nomor sama, kalau tidak highlight melenceng. `wsctl set` di labwc butuh
  **wtype** (`sudo dnf install wtype`) sebab labwc tak punya IPC perintah —
  script mensintesis Super+N supaya keybind rc.xml yang bekerja.
- dwl belum didukung `wsctl` (tags, bukan workspace). Butuh dwlb.

## Portabilitas monitor (JANGAN hardcode nama output)
`monitor = , preferred, auto, 1` = catch-all, cocok untuk output apa pun. Workspace
persistent 1-4 sengaja TANPA field `monitor:` supaya ikut display mana pun —
`workspace = N, persistent:true` (sudah diverifikasi jalan tanpa `monitor:`).
Override per-mesin masuk `~/.config/hypr/local.conf` (di-`source` paling bawah
`hyprland.conf`, dibuat otomatis oleh `make link`, di-gitignore). Kalau user minta
setting monitor spesifik: tulis di `local.conf`, BUKAN di `hyprland.conf`.

Workspace persistent WAJIB ada, kalau tidak swipe 3 jari tampak mati: Hyprland
cuma geser ke workspace yang sudah eksis (`workspace_swipe_create_new = false`),
dan tanpa persistent hanya workspace 1 yang eksis. Catatan: `hyprctl reload` tidak
retro-instansiasi workspace persistent (rule dieksekusi saat monitor connect) —
efek penuh setelah restart sesi.

## Sumber kebenaran
`config/hypr/hyprland.conf` di repo. Kalau sudah `make link`, file itu = file
hidup (symlink) → **tak ada langkah salin**, Hyprland auto-reload saat disimpan.
Paksa reload: `hyprctl reload`. Verifikasi keybind aktif: `hyprctl binds`.
