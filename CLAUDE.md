# CLAUDE.md — labwc macOS-style Config Deployment

> **Untuk sesi Claude Code yang berjalan di mesin Fedora 42 milik user (rjial).**
> Sesi ini punya akses langsung ke `~/.config/`, `dnf`, dan `labwc`. Repo ini
> berisi config labwc siap-pakai; tugasmu adalah men-deploy-nya ke mesin ini
> dan memandu setup sampai shortcut ala macOS berfungsi.

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
