# labwc Config — macOS-style Shortcuts (Fedora 42)

## Context

User wants a labwc (Wayland stacking WM) setup on Fedora 42 KDE with macOS-like
keyboard shortcuts for productivity. Decisions from user:

- **Full Cmd feel**: `xremap` (app-aware remap) + labwc keybinds.
- **Cmd key = Super/Win** key. Real Ctrl stays Ctrl (terminal SIGINT intact).
- **Launcher = fuzzel** (Spotlight-like), **terminal = foot**.
- **Smart terminal**: Cmd+C copies in foot, real Ctrl+C = SIGINT.
- User installs packages **manually via dnf/copr** — plan only lists commands + writes config files.

### Why xremap, not keyd
Smart terminal requires *per-application* behavior (Cmd+C → `Ctrl+Shift+C` inside foot,
but → `Ctrl+C` everywhere else). `keyd` is kernel-level with no app awareness and cannot do
this. `xremap` reads labwc's `wlr-foreign-toplevel-management` protocol → per-app rules work.

### Core architecture (the important idea)
Super is the physical Cmd. xremap remaps **only the app-shortcut letters** (`Super+c/v/x/s/z/...`)
into their `Ctrl+` equivalents so GUI apps behave mac-like. Keys xremap **does NOT touch**
(`Super+q/m/h/space/tab/grave/arrows/digits`) fall through to labwc as real `Super+` binds for
window management. This split avoids collisions: each key is handled by exactly one layer.

---

## Packages (user runs manually)

```bash
# base — all in Fedora repos
sudo dnf install labwc fuzzel foot grim slurp swaybg wl-clipboard

# xremap — NOT in repos. Install via COPR (preferred) …
sudo dnf copr enable emd/xremap        # verify slug exists; else use cargo route below
sudo dnf install xremap-wlroots        # wlroots feature build (labwc = wlroots)

# … OR via cargo if no COPR:
sudo dnf install cargo
cargo install xremap --features wlroots     # binary lands in ~/.cargo/bin
```

> At execution: confirm which xremap route works (`dnf copr search xremap` / fallback cargo).
> `xremap --features wlroots` is required — the generic build lacks labwc app detection.

### uinput permissions (xremap needs to inject events as non-root)
```bash
sudo usermod -aG input $USER
echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' \
  | sudo tee /etc/udev/rules.d/99-uinput.rules
echo uinput | sudo tee /etc/modules-load.d/uinput.conf
sudo modprobe uinput
# log out / reboot so the `input` group membership applies
```

---

## Files to create

All under `~/.config/`. None exist yet (`~/.config/labwc/` absent).

### 1. `~/.config/xremap/config.yml` — the Cmd remap engine
```yaml
# foot block FIRST — app-specific overrides the global block per key.
keymap:
  - name: Terminal smart copy/paste (foot)
    application:
      only: [foot]
    remap:
      Super-c: Ctrl-Shift-c      # copy in foot; real Ctrl-c untouched = SIGINT
      Super-v: Ctrl-Shift-v      # paste
      Super-x: Ctrl-Shift-x
      Super-f: Ctrl-Shift-f      # search (foot)

  - name: Global Cmd -> Ctrl (GUI app shortcuts)
    remap:
      Super-a: Ctrl-a
      Super-c: Ctrl-c
      Super-v: Ctrl-v
      Super-x: Ctrl-x
      Super-z: Ctrl-z
      Super-Shift-z: Ctrl-Shift-z     # redo
      Super-s: Ctrl-s
      Super-f: Ctrl-f
      Super-n: Ctrl-n
      Super-t: Ctrl-t
      Super-Shift-t: Ctrl-Shift-t     # reopen tab
      Super-r: Ctrl-r
      Super-p: Ctrl-p
      Super-o: Ctrl-o
      Super-w: Ctrl-w                  # close tab (app), window close = Super-q via labwc
      Super-l: Ctrl-l
      Super-d: Ctrl-d
      Super-e: Ctrl-e
      Super-g: Ctrl-g
      Super-Shift-g: Ctrl-Shift-g
      Super-b: Ctrl-b
      Super-i: Ctrl-i
      Super-u: Ctrl-u
      Super-y: Ctrl-y
      Super-k: Ctrl-k
      Super-j: Ctrl-j
      Super-comma: Ctrl-comma          # preferences
      Super-minus: Ctrl-minus          # zoom out
      Super-equal: Ctrl-equal          # zoom in
      Super-backspace: Ctrl-backspace
# NOT remapped (reach labwc): q, m, h, space, tab, grave, arrows, digits 0-9
```

### 2. `~/.config/labwc/rc.xml` — window mgmt + system binds
Keybinds (Super = Cmd, passthrough keys only):

| Shortcut | Action | labwc |
|---|---|---|
| Super+Space | launcher (Spotlight) | `Execute` fuzzel |
| Super+Return | terminal | `Execute` foot |
| Super+Q | close window (≈ Cmd+Q quit) | `Close` |
| Super+M | minimize | `Iconify` |
| Super+H | hide/minimize | `Iconify` |
| Super+Tab / Super+Shift+Tab | next / prev window | `NextWindow` / `PreviousWindow` |
| Super+grave (\`) | cycle windows | `NextWindow` |
| Super+Up | maximize toggle | `ToggleMaximize` |
| Super+Down | restore / iconify | `Iconify` |
| Super+Left / Super+Right | snap half (Magnet-like) | `SnapToEdge left`/`right` |
| Super+1..9 | switch workspace (mac Spaces) | `GoToDesktop 1..9` |
| Ctrl+Super+Left/Right | move window to workspace | `SendToDesktop` |
| Super+Shift+3 | full screenshot | `Execute` grim |
| Super+Shift+4 | region screenshot | `Execute` grim+slurp |
| XF86 media keys | volume/brightness | `Execute` wpctl/brightnessctl |

Skeleton:
```xml
<?xml version="1.0"?>
<labwc_config>
  <core><gap>6</gap></core>
  <desktops number="4"/>
  <theme><cornerRadius>8</cornerRadius></theme>
  <keyboard>
    <keybind key="W-space"><action name="Execute" command="fuzzel"/></keybind>
    <keybind key="W-Return"><action name="Execute" command="foot"/></keybind>
    <keybind key="W-q"><action name="Close"/></keybind>
    <keybind key="W-m"><action name="Iconify"/></keybind>
    <keybind key="W-h"><action name="Iconify"/></keybind>
    <keybind key="W-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-S-Tab"><action name="PreviousWindow"/></keybind>
    <keybind key="W-grave"><action name="NextWindow"/></keybind>
    <keybind key="W-Up"><action name="ToggleMaximize"/></keybind>
    <keybind key="W-Down"><action name="Iconify"/></keybind>
    <keybind key="W-Left"><action name="SnapToEdge" direction="left"/></keybind>
    <keybind key="W-Right"><action name="SnapToEdge" direction="right"/></keybind>
    <keybind key="W-1"><action name="GoToDesktop" to="1"/></keybind>
    <!-- W-2 .. W-4 similar -->
    <keybind key="C-W-Left"><action name="SendToDesktop" to="left"/></keybind>
    <keybind key="C-W-Right"><action name="SendToDesktop" to="right"/></keybind>
    <keybind key="W-S-3">
      <action name="Execute" command='sh -c "grim ~/Pictures/shot-$(date +%s).png"'/>
    </keybind>
    <keybind key="W-S-4">
      <action name="Execute" command='sh -c "grim -g \"$(slurp)\" ~/Pictures/shot-$(date +%s).png"'/>
    </keybind>
    <keybind key="XF86AudioRaiseVolume"><action name="Execute" command="wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"/></keybind>
    <keybind key="XF86AudioLowerVolume"><action name="Execute" command="wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"/></keybind>
    <keybind key="XF86AudioMute"><action name="Execute" command="wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"/></keybind>
  </keyboard>
  <mouse/>
</labwc_config>
```
> `date +%s` in Execute is fine (runs in a shell, not the labwc process).

### 3. `~/.config/labwc/autostart`
```sh
# remap engine — must run inside the labwc session for app detection
xremap ~/.config/xremap/config.yml &   # if cargo route: ~/.cargo/bin/xremap
swaybg -i ~/Pictures/wallpaper.jpg -m fill &
```

### 4. `~/.config/labwc/environment`
```sh
XKB_DEFAULT_LAYOUT=us
XCURSOR_THEME=Adwaita
XCURSOR_SIZE=24
QT_QPA_PLATFORM=wayland
MOZ_ENABLE_WAYLAND=1
```

### 5. `~/.config/labwc/menu.xml` — right-click root menu
Entries: Terminal (foot), Launcher (fuzzel), Reconfigure, Exit.

### 6. `~/.config/foot/foot.ini`
Default copy stays `Ctrl+Shift+c` (xremap routes Super+C here). Set font/theme, e.g.:
```ini
[main]
font=monospace:size=11
[key-bindings]
# defaults already: copy-clipboard=Control+Shift+c, paste-clipboard=Control+Shift+v
```

### 7. `~/.config/fuzzel/fuzzel.ini` — Spotlight look
```ini
[main]
font=sans-serif:size=13
width=40
lines=8
horizontal-pad=20
vertical-pad=14
[border]
radius=12
```

---

## Known tradeoffs (documented, not bugs)

- **Cmd+arrow = text nav** (Home/End/word-jump on mac) is **dropped** — arrows are reserved for
  labwc window snapping. Native Home/End keys still work. Can be added later via xremap if user
  prefers text-nav over Super+arrow snapping.
- **Cmd+1..9 = browser tabs** dropped — digits reserved for workspace switching. Use Ctrl+Tab for tabs.
- **Mission Control / Exposé** — labwc has no native window-overview; no equivalent bound.
- **Cmd+W** = app close-tab (`Ctrl+W`), **not** window close. Window close = **Cmd+Q**.

---

## Verification (end-to-end)

1. `sudo dnf install …` + xremap route + uinput perms; reboot (for `input` group).
2. Start labwc from a TTY: `dbus-run-session labwc` (or pick "labwc" in SDDM — labwc ships a
   `wayland-sessions` desktop file).
3. Check xremap running: `pgrep xremap` and `xremap` prints detected windows on focus change.
4. GUI copy: focus a text field in a browser → **Super+C / Super+V** copy/paste.
5. Terminal smart copy: in foot, select text → **Super+C** copies; run `sleep 100` → **Ctrl+C**
   interrupts (SIGINT). Confirms per-app rule active.
6. Window mgmt: **Super+Space** opens fuzzel; **Super+Q** closes; **Super+Left/Right** snaps;
   **Super+1/2** switches workspace; **Super+Shift+4** saves a region screenshot to `~/Pictures`.
7. `labwc --reconfigure` (SIGHUP) reloads rc.xml without restart while iterating.

## Execution order
1. Print dnf/copr/uinput commands for user to run; wait for confirmation packages + perms done.
2. Write config files 1–7.
3. Guide user through verification steps 2–7; iterate on rc.xml via `--reconfigure`.
