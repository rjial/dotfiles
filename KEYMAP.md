# KEYMAP — macOS-style (labwc / dwl)

*🇬🇧 [English version](KEYMAP.en.md)*

`Super` = tombol fisik **Cmd**.

Dua compositor terpasang berdampingan, pilih saat login (SDDM):
- **labwc** (`config/labwc/rc.xml`) — stacking/floating. Snap manual. Reload runtime.
- **dwl** (`config/dwl/config.h`) — tiling (dwm-style). Compiled. Recompile tiap ubah.

Lapisan **xremap** (`config/xremap/config.yml`) di-**share** dua-duanya — remap huruf
shortcut aplikasi `Super+` menjadi `Ctrl+` supaya GUI app terasa mac-like.

Aturan: huruf yang di-remap xremap **tidak** sampai ke compositor. Tombol yang TIDAK
di-remap (`q m h space tab grave arrows 0-9 period slash bracket Print`) jatuh ke WM.

---

# === labwc (stacking) ===

## Window management (labwc)

| Shortcut | Aksi |
|---|---|
| `Super+Space` / `Alt+Space` | Buka fuzzel (launcher / Spotlight) |
| `Super+Return` | Buka foot (terminal) |
| `Super+Q` | Close window |
| `Super+M` | Minimize (iconify) |
| `Super+H` | Hide (iconify) |
| `Super+Tab` / `Alt+Tab` | Window berikutnya |
| `Super+Shift+Tab` / `Alt+Shift+Tab` | Window sebelumnya |
| `Super+` `` ` `` (grave) | Window berikutnya |
| `Super+Up` | Toggle maximize |
| `Super+Down` | Minimize |
| `Super+Left` | Snap kiri |
| `Super+Right` | Snap kanan |

> `Alt+Space` dan `Alt+Tab` sengaja di-mirror dari `Super+` supaya muscle memory Alt+Tab tetap kepakai.

## Workspaces (mac Spaces — 4 desktop)

| Shortcut | Aksi |
|---|---|
| `Super+1..4` | Pindah ke desktop 1–4 |
| `Ctrl+Super+Left` | Kirim window ke desktop kiri |
| `Ctrl+Super+Right` | Kirim window ke desktop kanan |

## Screenshot

Tambah `Ctrl` = ke **clipboard** (bukan file), pola ala macOS.

| Shortcut | Aksi | Tujuan |
|---|---|---|
| `Super+Shift+3` | Full screen (`grim`) | file `~/Pictures/shot-<epoch>.png` |
| `Super+Shift+4` | Region select (`grim` + `slurp`) | file `~/Pictures/shot-<epoch>.png` |
| `Ctrl+Super+Shift+3` | Full screen | **clipboard** (`wl-copy -t image/png`) |
| `Ctrl+Super+Shift+4` | Region select | **clipboard** (`wl-copy -t image/png`) |
| `PrtSc` | Full screen | **clipboard** |
| `Shift+PrtSc` | Region select | **clipboard** |
| `Ctrl+PrtSc` | Full screen | file |
| `Ctrl+Shift+PrtSc` | Region select | file |

> Tombol `PrtSc` default ke clipboard; tambah `Ctrl` = simpan ke file (kebalikan dari set `Super+Shift`, biar tekan PrtSc cepat langsung dapat gambar di clipboard).

## Media keys

| Shortcut | Aksi |
|---|---|
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume −5% |
| `XF86AudioMute` | Toggle mute |

---

# === dwl (tiling) ===

dwl pakai **tags** (dwm-style), bukan workspace. Huruf `t/f` (layout) di-remap
xremap → dwl pakai `period/slash/m`. Screenshot pakai `Print` (bukan `Super+Shift+digit`,
karena bentrok dgn pindah-tag).

## Window management (dwl)

| Shortcut | Aksi |
|---|---|
| `Super+Space` | Buka fuzzel (launcher) |
| `Super+Return` | Buka foot (terminal) |
| `Super+Q` | Close window (killclient) |
| `Super+Tab` / `Super+` `` ` `` | Fokus window berikutnya |
| `Super+Shift+Tab` | Fokus window sebelumnya |
| `Super+Up` | Toggle fullscreen |
| `Super+Down` | Toggle floating |
| `Super+Left` / `Super+Right` | Resize master (mfact −/+) |
| `Super+Shift+Return` | Zoom (jadikan window master) |
| `Super+Shift+.` | Tambah master (nmaster +1) |
| `Super+Shift+,` | Kurang master (nmaster −1) |
| `Super+Shift+Q` | Keluar dwl |

## Layout (dwl)

| Shortcut | Layout |
|---|---|
| `Super+.` (period) | Tile `[]=` |
| `Super+/` (slash) | Floating `><>` |
| `Super+M` | Monocle `[M]` |

## Tags (dwm-style, 9 tag)

| Shortcut | Aksi |
|---|---|
| `Super+1..9` | Lihat tag N |
| `Super+Shift+1..9` | Pindah window ke tag N |
| `Super+Ctrl+1..9` | Toggle tampilkan tag N |
| `Super+Ctrl+Shift+1..9` | Toggle tag pada window |
| `Super+0` | Lihat semua tag |

## Multi-monitor (dwl)

| Shortcut | Aksi |
|---|---|
| `Super+[` / `Super+]` | Fokus monitor kiri / kanan |
| `Super+Shift+{` / `Super+Shift+}` | Kirim window ke monitor kiri / kanan |

## Mouse (dwl)

| Aksi | Fungsi |
|---|---|
| `Super+drag kiri` | Pindah window |
| `Super+drag kanan` | Resize window |
| `Super+klik tengah` | Toggle floating |

Screenshot & media key dwl = **sama** dgn labwc (lihat atas): `Print` (+Ctrl/Shift), `XF86Audio*`.

---

# === Shared (labwc + dwl) ===

## App shortcuts (xremap: Super → Ctrl)

Berlaku global di semua GUI app, di **kedua** compositor. `Super+<huruf>` dikirim ke app sebagai `Ctrl+<huruf>`.

| Super | Jadi | Fungsi umum |
|---|---|---|
| `Super+A` | `Ctrl+A` | Select all |
| `Super+C` | `Ctrl+C` | Copy |
| `Super+V` | `Ctrl+V` | Paste |
| `Super+X` | `Ctrl+X` | Cut |
| `Super+Z` | `Ctrl+Z` | Undo |
| `Super+Shift+Z` | `Ctrl+Shift+Z` | Redo |
| `Super+S` | `Ctrl+S` | Save |
| `Super+F` | `Ctrl+F` | Find |
| `Super+N` | `Ctrl+N` | New |
| `Super+T` | `Ctrl+T` | New tab |
| `Super+Shift+T` | `Ctrl+Shift+T` | Reopen tab |
| `Super+R` | `Ctrl+R` | Reload |
| `Super+P` | `Ctrl+P` | Print |
| `Super+O` | `Ctrl+O` | Open |
| `Super+W` | `Ctrl+W` | Close **tab** (window close = `Super+Q` via labwc) |
| `Super+L` | `Ctrl+L` | Address bar / go-to-line |
| `Super+D` | `Ctrl+D` | Bookmark / duplicate |
| `Super+E` | `Ctrl+E` | — |
| `Super+G` | `Ctrl+G` | Find next |
| `Super+Shift+G` | `Ctrl+Shift+G` | Find prev |
| `Super+B` | `Ctrl+B` | Bold |
| `Super+I` | `Ctrl+I` | Italic |
| `Super+U` | `Ctrl+U` | Underline / view source |
| `Super+Y` | `Ctrl+Y` | — |
| `Super+K` | `Ctrl+K` | — |
| `Super+J` | `Ctrl+J` | — |
| `Super+,` | `Ctrl+,` | Preferences |
| `Super+-` | `Ctrl+-` | Zoom out |
| `Super+=` | `Ctrl+=` | Zoom in |
| `Super+Backspace` | `Ctrl+Backspace` | Hapus kata |

## Terminal (foot) — smart copy/paste

Blok khusus foot menang atas global. Bikin `Ctrl+C` asli tetap = SIGINT.

| Super | Jadi | Fungsi |
|---|---|---|
| `Super+C` | `Ctrl+Shift+C` | Copy (foot) |
| `Super+V` | `Ctrl+Shift+V` | Paste (foot) |
| `Super+X` | `Ctrl+Shift+X` | — |
| `Super+F` | `Ctrl+Shift+F` | Search (foot) |

> `Ctrl+C` mentah tidak disentuh di foot → tetap kirim SIGINT (interrupt).

---

## Tradeoff (disengaja, bukan bug)

- **Cmd+panah (navigasi teks) dihilangkan** — panah dipakai snap window. Home/End native tetap jalan.
- **Cmd+1..9 (tab browser) dihilangkan** — digit untuk ganti workspace. Pakai `Ctrl+Tab`.
- **Tidak ada Mission Control / Exposé** — labwc tak punya window-overview native.
- **Cmd+W** = close tab; tutup window = **Cmd+Q**.

---

## Edit keybind

Sumber kebenaran = file di `config/`:
- labwc window/sistem: `config/labwc/rc.xml` → salin ke `~/.config/` → `labwc --reconfigure`
- dwl window/sistem: `config/dwl/config.h` → salin ke `~/Dokumen/dwl/` → **recompile**
  (`make CC=clang && sudo make install`) → logout/login. Tak ada reload runtime.
- App remap (shared): `config/xremap/config.yml` → restart xremap

Abis edit, salin ulang ke lokasi pakai lalu reload/recompile.
