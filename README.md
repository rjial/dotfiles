# macOS-style Wayland dotfiles — labwc + dwl + Hyprland (Fedora 42)

![Desktop preview](assets/preview.png)

Three wlroots-based compositors side by side, sharing one macOS-like keyboard layer:

- **labwc** — stacking/floating WM (manual window snapping).
- **dwl** — tiling WM (dwm-style, compiled from source).
- **Hyprland** — tiling WM with effects (animations, blur, gestures; runtime reload).

`Super` is the physical **Cmd** key. `xremap` remaps app-shortcut letters
(`Super+c/v/x/s/z/…`) to their `Ctrl+` equivalents so GUI apps feel mac-like,
while window-management keys fall through to the compositor. Launcher = **fuzzel**
(Spotlight), terminal = **foot** (smart copy: Cmd+C copies, real Ctrl+C = SIGINT),
top bar = **sfwbar**, wallpaper = **waypaper**.

Full keybind reference: [`KEYMAP.en.md`](KEYMAP.en.md) (English) · [`KEYMAP.md`](KEYMAP.md) (Indonesia).

## Layout

```
config/
  xremap/config.yml    # Cmd->Ctrl remap engine (foot block first) — SHARED
  labwc/rc.xml         # labwc window mgmt + system keybinds
  labwc/autostart      # lxpolkit + xremap + waypaper + sfwbar
  labwc/environment    # session env vars
  labwc/menu.xml       # right-click root menu
  labwc/labwc.desktop  # SDDM session entry
  dwl/config.h         # dwl keybinds/appearance (compiled in)
  dwl/autostart.sh     # dwl startup (dwl -s ...)
  dwl/dwl.desktop      # SDDM session entry
  hypr/hyprland.conf   # Hyprland: keybinds + env + autostart + effects (one file)
  foot/foot.ini        # terminal font/theme
  fuzzel/fuzzel.ini    # launcher look
  sfwbar/sfwbar.config # top menu-bar (launcher + taskbar + clock + status)
  snappy-switcher/     # Alt+Tab overlay switcher (Hyprland only)
  waypaper/            # wallpaper picker (config.ini is git-ignored = state)
Makefile               # symlink manager (config/* -> ~/.config/*)
KEYMAP.md              # full keybind reference (labwc + dwl + Hyprland)
CLAUDE.md              # deploy/architecture notes
```

## 1. Install packages (run manually)

```bash
# base — all in Fedora repos
sudo dnf install labwc fuzzel foot grim slurp swaybg wl-clipboard sfwbar waypaper

# Hyprland session (optional — see step 6)
sudo dnf install hyprland xdg-desktop-portal-hyprland brightnessctl

# xremap — NOT in repos. COPR (preferred):
sudo dnf copr enable emd/xremap        # verify slug: `dnf copr search xremap`
sudo dnf install xremap-wlroots        # wlroots build (labwc/dwl = wlroots)

# … OR cargo fallback if no COPR:
sudo dnf install cargo
cargo install xremap --features wlroots     # binary lands in ~/.cargo/bin
```

> `--features wlroots` is required — the generic build lacks app detection.
> If you used cargo, edit the autostart files to call `~/.cargo/bin/xremap`.

## 2. uinput permissions (xremap injects events as non-root)

```bash
sudo usermod -aG input $USER
echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' \
  | sudo tee /etc/udev/rules.d/99-uinput.rules
echo uinput | sudo tee /etc/modules-load.d/uinput.conf
sudo modprobe uinput
# log out / reboot so the `input` group membership applies
```

## 3. Deploy the configs (symlink via make)

Repo is the source of truth — `make link` symlinks each `config/<app>` into
`~/.config/<app>` (existing real dirs are backed up to `*.bak`). Editing a file
in the repo takes effect live, no re-copy.

```bash
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles
make link        # symlink config/* -> ~/.config/
make theme       # symlink labwc theme(s) -> ~/.local/share/themes/
mkdir -p ~/Pictures
```

| target | action |
|---|---|
| `make link`   | symlink `config/*` → `~/.config/` (backup real dirs to `.bak`) |
| `make theme`  | symlink `config/labwc/themes/*` → `~/.local/share/themes/` |
| `make unlink` | remove all symlinks, restore `.bak` |
| `make relink` | unlink then re-link + theme |
| `make status` | show each symlink's state |

> `make theme` is separate from `make link` because window themes live in
> `~/.local/share/themes/`, not `~/.config/`.

## 4. labwc — start & verify

- From a TTY: `dbus-run-session labwc`
- Or pick **labwc** in SDDM. Install the session entry once:
  ```bash
  sudo cp config/labwc/labwc.desktop /usr/share/wayland-sessions/
  ```
- Iterating: `labwc --reconfigure` reloads `rc.xml` without restart.

Verify:
1. `pgrep xremap` — running.
2. GUI copy: focus a browser text field → **Super+C / Super+V**.
3. Smart terminal: in foot, select text → **Super+C** copies; `sleep 100` →
   **Ctrl+C** interrupts (SIGINT). Confirms per-app rule active.
4. Window: **Super+Space** fuzzel; **Super+Q** close; **Super+Left/Right** snap;
   **Super+1/2** workspace; **Super+Shift+4**… (see KEYMAP.md; screenshots use `Print`).

## 5. dwl — build & install (optional, for tiling)

dwl has no runtime config — everything lives in `config.h`, compiled in.
**Every keybind change needs a recompile.** Built with clang/LLVM here.

```bash
# build deps (manual, sudo)
sudo dnf install clang make pkgconf-pkg-config lld \
  wlroots-devel wayland-devel wayland-protocols-devel \
  libinput-devel libxkbcommon-devel pixman-devel libdrm-devel

# clone (branch main targets wlroots 0.19, matching Fedora 42's runtime)
git clone https://codeberg.org/dwl/dwl ~/Dokumen/dwl

# use this repo's config.h, then compile
cp ~/.dotfiles/config/dwl/config.h ~/Dokumen/dwl/config.h
cd ~/Dokumen/dwl
make CC=clang \
  CFLAGS="-O3 -march=native -mtune=native -pipe -flto=thin -fuse-ld=lld -DNDEBUG" \
  LDFLAGS="-flto=thin -fuse-ld=lld"
sudo make install

# autostart + SDDM session
mkdir -p ~/.config/dwl && cp ~/.dotfiles/config/dwl/autostart.sh ~/.config/dwl/
chmod +x ~/.config/dwl/autostart.sh
sudo cp ~/.dotfiles/config/dwl/dwl.desktop /usr/share/wayland-sessions/
```

Log out → pick **dwl** in SDDM. Switch back to **labwc** anytime from the same
session menu.

> Note: dwl uses **tags** (not workspaces), so sfwbar's workspace pager won't
> track them; the taskbar (foreign-toplevel) still works. Native dwl bar = dwlb.

## 6. Hyprland — install & verify (optional, tiling + effects)

Same keymap as labwc where it makes sense, but tiling, and using Hyprland's own
features: dwindle auto-tiling, animations, blur/shadow/gradient borders,
3-finger workspace swipe, special workspace (stands in for minimize).
Everything lives in one file — **`config/hypr/hyprland.conf`** — and Hyprland
**reloads on save**: no recompile (unlike dwl), no `--reconfigure` (unlike labwc).

```bash
sudo dnf install hyprland xdg-desktop-portal-hyprland brightnessctl
make link          # symlinks config/hypr -> ~/.config/hypr
```

The SDDM session entry ships with the package (`/usr/share/wayland-sessions/hyprland.desktop`),
so there is nothing to copy. Log out → pick **Hyprland**.

### Your monitors

Nothing is hardcoded: `monitor = , preferred, auto, 1` is a catch-all that matches
any output (`eDP-1`, `HDMI-A-1`, `DP-1`, …), and the persistent workspaces 1–4 carry
no `monitor:` field, so they follow whatever display you have.

Multi-monitor or a specific mode/scale? Don't edit `hyprland.conf` — put your lines in
**`~/.config/hypr/local.conf`**, which `make link` creates and `hyprland.conf` sources
last. It is gitignored, so your layout never conflicts on `git pull`:

```conf
monitor = eDP-1,    1920x1080@60, 0x0,    1
monitor = HDMI-A-1, 2560x1440@144, 1920x0, 1
```

`hyprctl monitors` lists the names your machine reports. `hyprctl reload` applies.

Verify:
1. `pgrep xremap` — running (the `xremap-wlroots` build works here: Hyprland
   implements `wlr-foreign-toplevel-management`, so the per-app `foot` rule still fires).
2. **Super+Space** fuzzel; **Super+Q** close; **Super+1..4** workspaces;
   **Super+Left/Right** move focus; **Super+M** minimize → **Super+Shift+M** brings it back.
3. Three-finger swipe on the touchpad switches workspaces.
4. **Super+Shift+4** region screenshot → `~/Pictures`.

### The Alt+Tab overlay (snappy-switcher)

`Alt+Tab` and `Super+Tab` open **snappy-switcher**, an overlay switcher with app
icons and window titles — the macOS `Cmd+Tab` panel, roughly. It is **Hyprland-only**:
it reads the window list and MRU order over Hyprland IPC, so labwc and dwl keep
their own plain cycle binds.

It is not packaged for Fedora. Build and install from source:

```bash
git clone https://github.com/OpalAayan/snappy-switcher ~/Dokumen/snappy-switcher
cd ~/Dokumen/snappy-switcher && make && sudo make install
```

Skip upstream's `snappy-install-config` — it would write a real
`~/.config/snappy-switcher/config.ini` and `make link` would then shove it aside
to `.bak`. This repo already owns that file; `make link` symlinks it. Themes are
*not* vendored here: `sudo make install` drops them in
`/usr/local/share/snappy-switcher/themes/`, which the binary searches after
`~/.config/snappy-switcher/themes/`, so `name = catppuccin-frappe.ini` resolves
on its own.

| Bind | Action |
|---|---|
| `Alt+Tab` / `Alt+Shift+Tab` | all windows, MRU order |
| `Super+Tab` / `Super+Shift+Tab` | current workspace only |
| `Super+`` ` `` | plain `cyclenext` — fallback if the daemon is dead |

The daemon starts from `exec-once = snappy-wrapper`; the wrapper waits for the
Hyprland socket first, so it doesn't race SDDM login. Verify with
`pgrep -x snappy-switcher`.

> Gotcha: the `--mod` flag **must** name the modifier in its own bind
> (`ALT, TAB` → `--mod alt`). snappy holds the panel open while that modifier is
> held; a mismatch means it never sees the key down and it paints a CONFIG ERROR
> banner instead of the switcher.

> Notes: the workspace pager in the bar is **not** sfwbar's `pager` widget — see
> [The workspace pager](#the-workspace-pager) below for why. Chromium-based
> browsers are forced onto native Wayland via `ELECTRON_OZONE_PLATFORM_HINT`,
> which also fixes the XWayland "address bar not clickable" bug.

## The workspace pager

The four workspace glyphs in the bar are **not** sfwbar's `pager` widget. That
widget only speaks sway IPC and Hyprland, and its Hyprland backend reads state
once at startup and then stops following focus events — measured on sfwbar
1.0~beta16.1: a window on workspace 3, workspace 3 focused, highlight still stuck
on 2. sfwbar's own man page says *"Placer and pager require sway"*. labwc has no
sway IPC at all, so the pager never worked there either — the glyphs were
decoration and clicks did nothing.

Replacement: `config/sfwbar/wsctl`, a dependency-free python3 helper, plus four
plain `label` widgets in `sfwbar.config`.

```
wsctl watch    emits {"ws": N} whenever the focused workspace changes
wsctl set N    switch to workspace N
wsctl mark N   record N as active without switching (labwc path)
```

| WM | read (highlight) | write (click) |
|---|---|---|
| Hyprland | `.socket2.sock` event stream | `hyprctl dispatch workspace N` |
| labwc | state file, written by `set` / `mark` | `wtype` synthesises Super+N |
| dwl | not supported (tags, not workspaces) | not supported |

labwc extras: `sudo dnf install wtype`, and every `GoToDesktop` in `rc.xml` is
paired with `Execute ~/.config/sfwbar/wsctl mark N` so keyboard switches also
update the bar. Keep the pairs in sync or the highlight drifts.

Changing the glyphs means editing three files: `labwc/rc.xml`
(`<desktops><names>`), `hypr/hyprland.conf` (`defaultName:`), and
`sfwbar/sfwbar.config` (the label `value`s).

## Theming (labwc window decorations)

labwc uses Openbox-style themes (`themerc`). This repo ships **CatppuccinFrappe**
(`config/labwc/themes/CatppuccinFrappe/openbox-3/themerc`), wired via
`<theme><name>CatppuccinFrappe</name></theme>` in `rc.xml`.

- Tweak colors/border: edit the `themerc` (live via symlink) → `labwc --reconfigure`.
- Full key list: `man 5 labwc-theme`.
- **CSD caveat:** GTK/Electron apps draw their own titlebars (client-side
  decoration) and ignore the labwc theme; it applies to server-side-decorated
  windows only.

## Known tradeoffs (by design, not bugs)

- **Cmd+arrow text-nav dropped** — arrows drive window snap (labwc) / master size
  (dwl) / focus movement (Hyprland). Native Home/End still work.
- **Cmd+1..9 browser tabs dropped** — digits switch workspaces/tags. Use Ctrl+Tab.
- **No Mission Control / Exposé** — none of the three ships a native window
  overview. Closest: Hyprland's 3-finger workspace swipe, or the `hyprexpo`
  plugin (needs `hyprpm` + build headers, not wired up here).
- **Cmd+W** = app close-tab (`Ctrl+W`); window close = **Cmd+Q**.
- **dwl screenshots use `Print`** (not `Super+Shift+3/4`) — the latter collides
  with move-to-tag. labwc and Hyprland keep the full mac set.
- **No minimize on Hyprland** — the compositor has no iconify; `Super+M/H` parks
  the window on the `special:minimized` workspace instead.
