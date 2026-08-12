# KEYMAP — macOS-style (labwc / dwl / Hyprland)

*🇮🇩 [Versi Bahasa Indonesia](KEYMAP.md)*

`Super` = the physical **Cmd** key.

Three compositors installed side by side, picked at login (SDDM):
- **labwc** (`config/labwc/rc.xml`) — stacking/floating. Manual snap. Runtime reload.
- **dwl** (`config/dwl/config.h`) — tiling (dwm-style). Compiled. Recompile on each change.
- **Hyprland** (`config/hypr/hyprland.lua`) — tiling + effects. Reloads on save.

The **xremap** layer (`config/xremap/config.yml`) is **shared** by all three — it remaps
app-shortcut letters `Super+` into `Ctrl+` so GUI apps feel mac-like.

Rule: letters remapped by xremap **never** reach the compositor. Keys NOT remapped
(`q m h space tab grave arrows 0-9 period slash bracket Print`) fall through to the WM.

---

# === labwc (stacking) ===

## Window management (labwc)

| Shortcut | Action |
|---|---|
| `Super+Space` / `Alt+Space` | Open fuzzel (launcher / Spotlight) |
| `Super+Return` | Open foot (terminal) |
| `Super+Q` | Close window |
| `Super+M` | Minimize (iconify) |
| `Super+H` | Hide (iconify) |
| `Super+Tab` / `Alt+Tab` | Next window |
| `Super+Shift+Tab` / `Alt+Shift+Tab` | Previous window |
| `Super+` `` ` `` (grave) | Next window |
| `Super+Up` | Toggle maximize |
| `Super+Down` | Minimize |
| `Super+Left` | Snap left |
| `Super+Right` | Snap right |

> `Alt+Space` and `Alt+Tab` are intentionally mirrored from `Super+` so Alt+Tab
> muscle memory still works.

## Workspaces (mac Spaces — 8 desktops)

| Shortcut | Action |
|---|---|
| `Super+1..8` | Switch to desktop 1–8 |
| `Ctrl+Super+Left` | Send window to desktop on the left |
| `Ctrl+Super+Right` | Send window to desktop on the right |

## Screenshot

Adding `Ctrl` sends to the **clipboard** (not a file), macOS-style.

| Shortcut | Action | Destination |
|---|---|---|
| `Super+Shift+3` | Full screen (`grim`) | file `~/Pictures/shot-<epoch>.png` |
| `Super+Shift+4` | Region select (`grim` + `slurp`) | file `~/Pictures/shot-<epoch>.png` |
| `Ctrl+Super+Shift+3` | Full screen | **clipboard** (`wl-copy -t image/png`) |
| `Ctrl+Super+Shift+4` | Region select | **clipboard** (`wl-copy -t image/png`) |
| `PrtSc` | Full screen | **clipboard** |
| `Shift+PrtSc` | Region select | **clipboard** |
| `Ctrl+PrtSc` | Full screen | file |
| `Ctrl+Shift+PrtSc` | Region select | file |

> `PrtSc` defaults to the clipboard; adding `Ctrl` saves to a file (the inverse of
> the `Super+Shift` set, so tapping PrtSc quickly lands an image on the clipboard).

## Media keys

| Shortcut | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume +5% (with OSD) |
| `XF86AudioLowerVolume` | Volume −5% (with OSD) |
| `XF86AudioMute` | Toggle mute (with OSD) |
| `XF86AudioMicMute` | Toggle microphone mute (with OSD) |
| `XF86MonBrightnessUp` | Brightness +5% (with OSD) |
| `XF86MonBrightnessDown` | Brightness −5% (with OSD) |

> All of the above go through the wrappers `~/.config/scripts/volumectl` and
> `~/.config/scripts/brightctl` — the wrapper calls `wpctl`/`brightnessctl`, then
> shows a centered OSD (glyph + percent + bar) via mako. Volume is capped at 100%
> (`wpctl -l 1.0`); brightness has a floor of raw value 1 (`brightnessctl -n1`) so
> the screen can never be driven fully dark.

---

# === dwl (tiling) ===

dwl uses **tags** (dwm-style), not workspaces. Layout letters `t/f` are remapped by
xremap → dwl uses `period/slash/m`. Screenshots use `Print` (not `Super+Shift+digit`,
which collides with move-to-tag).

## Window management (dwl)

| Shortcut | Action |
|---|---|
| `Super+Space` | Open fuzzel (launcher) |
| `Super+Return` | Open foot (terminal) |
| `Super+Q` | Close window (killclient) |
| `Super+Tab` / `Super+` `` ` `` | Focus next window |
| `Super+Shift+Tab` | Focus previous window |
| `Super+Up` | Toggle fullscreen |
| `Super+Down` | Toggle floating |
| `Super+Left` / `Super+Right` | Resize master (mfact −/+) |
| `Super+Shift+Return` | Zoom (make window master) |
| `Super+Shift+.` | More masters (nmaster +1) |
| `Super+Shift+,` | Fewer masters (nmaster −1) |
| `Super+Shift+Q` | Quit dwl |

## Layout (dwl)

| Shortcut | Layout |
|---|---|
| `Super+.` (period) | Tile `[]=` |
| `Super+/` (slash) | Floating `><>` |
| `Super+M` | Monocle `[M]` |

## Tags (dwm-style, 9 tags)

| Shortcut | Action |
|---|---|
| `Super+1..9` | View tag N |
| `Super+Shift+1..9` | Move window to tag N |
| `Super+Ctrl+1..9` | Toggle-view tag N |
| `Super+Ctrl+Shift+1..9` | Toggle tag on the window |
| `Super+0` | View all tags |

### Tag OSD (dwl only)

Every tag switch shows a brief OSD in the centre of the screen (`󰓩 Tag 3`).
The OSD now **complements** the pager rather than replacing it: since `wsctl`
gained dwl support, the sfwbar pager is driven by the same stdin loop. sfwbar's
built-in `pager` widget still never tracked dwl tags — `config/sfwbar/wsctl` is
what does. The pager has 8 labels while dwl has 9 tags, so tag 9 is recorded but
lights nothing; there the OSD is the only indication.

How it works, since this differs from labwc/Hyprland: dwl pipes its stdout into
`autostart.sh`'s **stdin** (`dwl.c:2254-2271`), and `printstatus()` emits a
`tags <occupied> <selected> <clienttags> <urgent>` line whenever state changes.
A loop at the bottom of `config/dwl/autostart.sh` reads those lines and calls
`config/scripts/osd-dwl-tag`. Practical consequences:

- **No recompile needed** — the OSD lives in a shell script, not `config.h`.
- Tag changes from **clicking the sfwbar taskbar** or from window rules also
  raise the OSD, not just key presses.
- Switching focus between windows on the same tag does **not** raise the OSD
  (`printstatus()` also fires on `focusclient`, so the loop de-duplicates).
- Multi-tag via `Super+Ctrl+N` shows as `Tag 1,3`.
- Requires **mako running** in the dwl session. If mako is dead, the OSD is
  silent with no error.
- If **dwlb** is added later, dwl's stdout may only have one consumer —
  `autostart.sh` must `tee` to dwlb rather than two processes reading stdin.

## Multi-monitor (dwl)

| Shortcut | Action |
|---|---|
| `Super+[` / `Super+]` | Focus monitor left / right |
| `Super+Shift+{` / `Super+Shift+}` | Send window to monitor left / right |

## Mouse (dwl)

| Action | Function |
|---|---|
| `Super+left-drag` | Move window |
| `Super+right-drag` | Resize window |
| `Super+middle-click` | Toggle floating |

Screenshots & media keys in dwl are the **same** as labwc (see above):
`Print` (+Ctrl/Shift), `XF86Audio*`.

---

# === Hyprland (tiling + effects) ===

`dwindle` tiling. The labwc keymap is kept wherever it still makes sense; only the
binds that mean nothing under tiling (snap) or don't exist in Hyprland (minimize)
changed. Everything lives in one file, `config/hypr/hyprland.lua`, which
**reloads on save**.

## Window management (Hyprland)

| Shortcut | Action |
|---|---|
| `Super+Space` / `Alt+Space` | Open fuzzel (launcher) |
| `Super+Return` | Open foot (terminal) |
| `Super+Q` | Close window (killactive) |
| `Super+Shift+Q` | Quit Hyprland |
| `Super+Up` | Maximize (fullscreen 1 — bar stays visible) |
| `Super+Shift+Up` | True fullscreen (fullscreen 0) |
| `Super+Down` | Toggle floating |
| `Super+Left` / `Super+Right` | Move focus left / right |
| `Alt+Tab` / `Alt+Shift+Tab` | snappy-switcher overlay — all windows, MRU order |
| `Super+Tab` / `Super+Shift+Tab` | Overlay — current workspace only |
| `Super+` `` ` `` | Next window (cyclenext) — no-overlay fallback |
| `Super+M` / `Super+H` | "Minimize" → park on the `special:minimized` workspace |
| `Super+Shift+M` | Show/hide the `special:minimized` workspace |
| `Super+Shift+Left/Right/Down` | Move the window within the tiling tree |
| `Super+Alt+arrows` | Resize the active window (60px / 40px per press) |
| `Super+.` (period) | Toggle split direction (dwindle) |
| `Super+/` (slash) | Toggle pseudotile |

> Hyprland has no iconify. `special:minimized` is a hidden workspace — same effect
> as minimize, the window keeps running.

> **The switcher overlay is Hyprland-only.** snappy-switcher reads the window list
> and MRU order over Hyprland IPC, so `Alt+Tab` stays a plain cycle on labwc/dwl.
> The daemon comes from `hl.on("hyprland.start", …)` + `hl.exec_cmd("snappy-wrapper")`; if it dies, `Super+` `` ` ``
> still works. Config: `config/snappy-switcher/config.ini`.

## Workspaces (Hyprland — 8 desktops, mac Spaces)

| Shortcut | Action |
|---|---|
| `Super+1..8` | Switch to workspace 1–8 |
| `Super+Shift+1..8` | Move window to workspace 1–8 |
| `Ctrl+Super+Left` / `Ctrl+Super+Right` | Send window to the neighbouring workspace |
| `Ctrl+Alt+Left` / `Ctrl+Alt+Right` | Switch workspace without taking the window |
| `Super+scroll` | Switch workspace (skips empty ones) |
| **3-finger swipe** | Switch workspace (touchpad gesture, mac-natural direction) |

## Multi-monitor (Hyprland)

| Shortcut | Action |
|---|---|
| `Super+[` / `Super+]` | Focus previous / next monitor |
| `Super+Shift+[` / `Super+Shift+]` | Move the current workspace to another monitor |

## Mouse (Hyprland)

| Action | Function |
|---|---|
| `Super+left-drag` | Move window |
| `Super+right-drag` | Resize window |
| `Super+middle-click` | Toggle floating |
| drag a window edge | Resize (`resize_on_border`, no modifier) |

Screenshots & media keys on Hyprland are **identical** to labwc (see above):
`Super+Shift+3/4`, `+Ctrl` for clipboard, the `Print` family, `XF86Audio*` and
`XF86MonBrightness*` (all via the `volumectl`/`brightctl` wrappers, with OSD).

## Hyprland features in use

dwindle auto-tiling · macOS-ish bezier animations · blur + shadow + `rounding 8`
(matching labwc's `cornerRadius`) · Catppuccin Frappé gradient border (surface2 → teal)
· 3-finger `hl.gesture` swipe · `special:minimized` · `hl.layer_rule` blur for
sfwbar/fuzzel · `resize_on_border` · `follow_mouse=0` (click-to-focus, same as labwc)
· `ELECTRON_OZONE_PLATFORM_HINT=auto` (Chromium/Electron on native Wayland).

---

# === Shared (labwc + dwl + Hyprland) ===

## App shortcuts (xremap: Super → Ctrl)

Global across all GUI apps, on **all three** compositors. `Super+<letter>` is delivered
to the app as `Ctrl+<letter>`.

| Super | Becomes | Common function |
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
| `Super+W` | `Ctrl+W` | Close **tab** (window close = `Super+Q` via WM) |
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
| `Super+Backspace` | `Ctrl+Backspace` | Delete word |

## Terminal (foot) — smart copy/paste

The foot-specific block wins over the global one, keeping real `Ctrl+C` = SIGINT.

| Super | Becomes | Function |
|---|---|---|
| `Super+C` | `Ctrl+Shift+C` | Copy (foot) |
| `Super+V` | `Ctrl+Shift+V` | Paste (foot) |
| `Super+X` | `Ctrl+Shift+X` | — |
| `Super+F` | `Ctrl+Shift+F` | Search (foot) |

> Raw `Ctrl+C` is untouched in foot → still sends SIGINT (interrupt).

## Notifications (mako)

Same on all three compositors. Uses `Ctrl+Super` because bare `Super+N`/`Super+D`
are consumed by xremap (they become app-level `Ctrl+N`/`Ctrl+D`).

| Key | Action |
|---|---|
| `Ctrl+Cmd+N` | Dismiss topmost notification |
| `Ctrl+Cmd+Shift+N` | Dismiss all |
| `Ctrl+Cmd+D` | Toggle Do Not Disturb |
| `Ctrl+Cmd+Shift+D` | Restore last notification from history |

Mouse: left = invoke default action, middle = dismiss group, right = dismiss.
Theme/timeouts live in `config/mako/config`; apply without restart via
`makoctl reload`.

## Power menu (fuzzel)

Same on all three compositors. `Ctrl+Super` is used because bare `Super+Q` is
already close-window.

| Key | Action |
|---|---|
| `Ctrl+Cmd+Q` | Open power menu |

Menu contents (`config/scripts/powermenu`):

| Entry | Command |
|---|---|
| `󰌾 Lock` | `swaylock -f` |
| `󰗽 Log Out` | `loginctl terminate-session $XDG_SESSION_ID` |
| `󰖔 Suspend` | lock first, then `systemctl suspend` |
| `󰜉 Reboot` | `systemctl reboot` |
| `󰐥 Shut Down` | `systemctl poweroff` |

Log Out / Reboot / Shut Down ask for a **second confirmation** with `Cancel`
highlighted — one reflex Enter will not power off the machine. Esc cancels.

Other routes to the same menu: the `󰐥` button at the right end of sfwbar, and
the **Power** submenu in labwc's desktop right-click menu
(`config/labwc/menu.xml` — that route has **no** confirmation step, Openbox
menus cannot chain prompts).

Notes:
- **Log Out ≠ labwc Exit / Hyprland `Super+Shift+Q`.** Those only kill the
  compositor; `loginctl terminate-session` closes the logind session properly.
  Per-WM exit actions are not used because labwc has no exit CLI and dwl has no
  IPC at all.
- `poweroff`/`reboot`/`suspend` need **no sudo** — logind permits them for the
  active session via polkit, and `lxpolkit` is already autostarted on all three.
- Lock screen theme lives in `config/swaylock/config`. The Fedora package is
  **upstream** swaylock, so `screenshots`/`effect-blur` DO NOT EXIST — using
  them makes swaylock fail to start, leaving the screen unlocked.

---

## Tradeoffs (by design, not bugs)

- **Cmd+arrow text-nav dropped** — arrows drive window snap (labwc) / master size
  (dwl) / focus movement (Hyprland). Native Home/End still work.
- **Cmd+1..9 browser tabs dropped** — digits switch workspaces/tags. Use `Ctrl+Tab`.
- **No Mission Control / Exposé** — none of the three has a native window overview.
  Closest: Hyprland's 3-finger swipe, or the `hyprexpo` plugin (needs `hyprpm` +
  build headers, not wired up in this repo).
- **Cmd+W** = close tab; window close = **Cmd+Q**.
- **Minimize on Hyprland isn't iconify** — the window is parked on `special:minimized`.

---

## Editing keybinds

Source of truth = files under `config/`. After `make link`, every directory in
`DIRS` (`Makefile:15`) is symlinked into `~/.config/`, so there is **nothing to
copy** — except dwl, which has to be recompiled in its upstream clone.
- labwc window/system: `config/labwc/rc.xml` → `labwc --reconfigure`
- dwl window/system: `config/dwl/config.h` → copy to `~/Dokumen/dwl/` → **recompile**
  (`make CC=clang && sudo make install`) → log out/in. No runtime reload.
- Hyprland window/system: `config/hypr/hyprland.lua` → **reloads on save**. Force it
  with `hyprctl reload`; check the result with `hyprctl configerrors` (empty = clean).
- App remap (shared): `config/xremap/config.yml` → restart xremap

> Before adding a compositor keybind, check the key isn't eaten by xremap. What's
> left safe: `q m h space Return Tab grave arrows 0-9 period slash [ ] Print`
> plus any `Ctrl+Super+*` / `Alt+Super+*` combo (xremap matches modifiers exactly).

dwl is the exception: `config.h` **and** `config.mk` get copied into
`~/Dokumen/dwl/` and recompiled — neither is symlinked, because that directory is
an upstream git clone.
