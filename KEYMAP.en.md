# KEYMAP — macOS-style (labwc / dwl)

*🇮🇩 [Versi Bahasa Indonesia](KEYMAP.md)*

`Super` = the physical **Cmd** key.

Two compositors installed side by side, picked at login (SDDM):
- **labwc** (`config/labwc/rc.xml`) — stacking/floating. Manual snap. Runtime reload.
- **dwl** (`config/dwl/config.h`) — tiling (dwm-style). Compiled. Recompile on each change.

The **xremap** layer (`config/xremap/config.yml`) is **shared** by both — it remaps
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

## Workspaces (mac Spaces — 4 desktops)

| Shortcut | Action |
|---|---|
| `Super+1..4` | Switch to desktop 1–4 |
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
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume −5% |
| `XF86AudioMute` | Toggle mute |

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

# === Shared (labwc + dwl) ===

## App shortcuts (xremap: Super → Ctrl)

Global across all GUI apps, on **both** compositors. `Super+<letter>` is delivered
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

---

## Tradeoffs (by design, not bugs)

- **Cmd+arrow text-nav dropped** — arrows drive window snap (labwc) / master size
  (dwl). Native Home/End still work.
- **Cmd+1..9 browser tabs dropped** — digits switch workspaces/tags. Use `Ctrl+Tab`.
- **No Mission Control / Exposé** — neither WM has a native window-overview.
- **Cmd+W** = close tab; window close = **Cmd+Q**.

---

## Editing keybinds

Source of truth = files under `config/`:
- labwc window/system: `config/labwc/rc.xml` → deploy to `~/.config/` → `labwc --reconfigure`
- dwl window/system: `config/dwl/config.h` → copy to `~/Dokumen/dwl/` → **recompile**
  (`make CC=clang && sudo make install`) → log out/in. No runtime reload.
- App remap (shared): `config/xremap/config.yml` → restart xremap

After editing, re-deploy to the live location then reload/recompile.
