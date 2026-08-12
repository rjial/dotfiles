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
  dwl/autostart.sh     # dwl startup (dwl -s ...) + tag OSD stdin loop
  dwl/dwl.desktop      # SDDM session entry
  hypr/hyprland.lua    # Hyprland: keybinds + env + autostart + effects (one file)
  hypr/hyprland.conf.bak # previous .conf config — INERT, kept as a fallback
  mako/config          # notification daemon (toast top-right + OSD) — SHARED
  scripts/powermenu    # power menu via fuzzel (lock/logout/suspend/…) — SHARED
  scripts/osd          # generic OSD renderer via mako — SHARED
  scripts/osd-dwl-tag  # dwl tag bitmask -> OSD text (dwl only)
  scripts/volumectl    # volume/mute via wpctl + OSD — SHARED
  scripts/brightctl    # backlight via brightnessctl + OSD — SHARED
  scripts/xdg-autostart      # run XDG .desktop autostart entries — SHARED
  scripts/xdg-autostart.skip # entries that must NOT run
  swaylock/config      # lock screen theme — SHARED
  foot/foot.ini        # terminal font/theme
  fuzzel/fuzzel.ini    # launcher look
  sfwbar/sfwbar.config # top menu-bar (launcher + taskbar + clock + status + power)
  snappy-switcher/     # Alt+Tab overlay switcher (Hyprland only)
  waypaper/            # wallpaper picker (config.ini is git-ignored = state)
Makefile               # symlink manager (config/* -> ~/.config/*)
KEYMAP.md              # full keybind reference (labwc + dwl + Hyprland)
CLAUDE.md              # deploy/architecture notes
```

## 1. Install packages (run manually)

```bash
# base — all in Fedora repos
sudo dnf install labwc fuzzel foot grim slurp swaybg wl-clipboard sfwbar waypaper mako swaylock

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
make link          # symlinks config/dwl -> ~/.config/dwl (autostart.sh lives there)
sudo cp ~/.dotfiles/config/dwl/dwl.desktop /usr/share/wayland-sessions/
```

> `~/.config/dwl` is a **symlink** (`dwl` is in the Makefile's `DIRS`), so editing
> `config/dwl/autostart.sh` in the repo takes effect on the next session with no
> copy step. `config.h` is the exception — it must still be copied to
> `~/Dokumen/dwl/` and recompiled. Copying `autostart.sh` by hand instead is how
> it silently went stale before: the repo gained `mako &` but the running session
> never saw it.

Log out → pick **dwl** in SDDM. Switch back to **labwc** anytime from the same
session menu.

> Note: dwl uses **tags** (not workspaces), so sfwbar's workspace pager won't
> track them; the taskbar (foreign-toplevel) still works. Native dwl bar = dwlb.

## 6. Hyprland — install & verify (optional, tiling + effects)

Same keymap as labwc where it makes sense, but tiling, and using Hyprland's own
features: dwindle auto-tiling, animations, blur/shadow/gradient borders,
3-finger workspace swipe, special workspace (stands in for minimize).
Everything lives in one file — **`config/hypr/hyprland.lua`** — and Hyprland
**reloads on save**: no recompile (unlike dwl), no `--reconfigure` (unlike labwc).
The config is **Lua**, not the old `.conf` format: hyprlang is dropped in Hyprland
0.57, so the session moved over in August 2026. The old file is kept as
`hyprland.conf.bak` (the `.bak` extension makes Hyprland ignore it) purely as a
fallback — while `hyprland.lua` exists, editing the `.bak` does nothing.

```bash
sudo dnf install hyprland xdg-desktop-portal-hyprland brightnessctl
make link          # symlinks config/hypr -> ~/.config/hypr
```

The SDDM session entry ships with the package (`/usr/share/wayland-sessions/hyprland.desktop`),
so there is nothing to copy. Log out → pick **Hyprland**.

### Your monitors

Nothing is hardcoded: `hl.monitor({ output = "", mode = "preferred", … })` is a
catch-all that matches any output (`eDP-1`, `HDMI-A-1`, `DP-1`, …), and the
persistent workspaces 1–8 carry no `monitor` field, so they follow whatever
display you have.

Multi-monitor or a specific mode/scale? Don't edit `hyprland.lua` — put your lines in
**`~/.config/hypr/local.lua`**, which `make link` creates and `hyprland.lua` `dofile`s
last. It is gitignored, so your layout never conflicts on `git pull`:

```lua
hl.monitor({ output = "eDP-1",    mode = "1920x1080@60",  position = "0x0",    scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "1920x0", scale = 1 })
```

`hyprctl monitors` lists the names your machine reports. `hyprctl reload` applies.

Verify:
1. `pgrep xremap` — running (the `xremap-wlroots` build works here: Hyprland
   implements `wlr-foreign-toplevel-management`, so the per-app `foot` rule still fires).
2. **Super+Space** fuzzel; **Super+Q** close; **Super+1..4** workspaces;
   **Super+Left/Right** move focus; **Super+M** minimize → **Super+Shift+M** brings it back.
3. Three-finger swipe on the touchpad switches workspaces.
4. **Super+Shift+4** region screenshot → `~/Pictures`.

### Picture-in-Picture

Two rules, because browsers ship **two different** PiP mechanisms:

| Rule | Fires for | How it is matched |
|---|---|---|
| `pip` | classic video PiP (YouTube, Netflix, `<video>`) | title `Picture-in-picture` — the window has **no app-id at all** |
| `pip-document` | Document PiP API (**Google Meet**, Discord, YouTube Music) | browser class **plus** a `negative:` title match |

Google Meet does not use video PiP. It calls
`documentPictureInPicture.requestWindow()`, which produces an ordinary HTML
window: the app-id is a real one (`helium`), and the title is just the page
title (`Meet – <meeting>`) — it never says "Picture-in-picture". So the `pip`
rule never fired, and the Meet window stayed at ~954x822, unpinned, disappearing
whenever you switched workspace.

The only thing separating a doc-PiP window from a normal browser window is that
the title carries **no ` - Helium` suffix**. Hyprland links **RE2**, which has no
lookahead, so `(?!…)` is off the table; the rule uses the `negative:` match
prefix instead. Detached DevTools windows are excluded in the same regex, since
they are unsuffixed too.

If some other Chromium window ever ends up pinned and tiny, add its title to the
`negative:` list in `config/hypr/hyprland.lua` — don't add a second rule.

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
| Hyprland | `.socket2.sock` event stream | `hyprctl dispatch 'hl.dsp.focus({workspace=N})'` |
| labwc | state file, written by `set` / `mark` | `wtype` synthesises Super+N |
| dwl | state file, fed by the `autostart.sh` stdin loop | `wtype` synthesises Super+N |

The Hyprland dispatch form follows the **config format, not the version**: with a
Lua config, `hyprctl dispatch workspace 2` fails (`')' expected near '2'`), so
`wsctl` tries the Lua form first and falls back to the old one. Queries
(`clients`, `activeworkspace`, `layers`, `getoption`) are unchanged.

dwl reports tags, not workspaces, so `wsctl` marks the lowest lit tag; the pager
has 8 labels while dwl has 9 tags, so tag 9 is recorded but lights nothing.

labwc extras: `sudo dnf install wtype`, and every `GoToDesktop` in `rc.xml` is
paired with `Execute ~/.config/sfwbar/wsctl mark N` so keyboard switches also
update the bar. Keep the pairs in sync or the highlight drifts.

Changing the glyphs means editing three files: `labwc/rc.xml`
(`<desktops><names>`), `hypr/hyprland.lua` (`default_name`), and
`sfwbar/sfwbar.config` (the label `value`s).

**dwl also gets a tag OSD** — alongside the pager, not instead of it. The dwl
session shows a brief centred toast (`󰓩 Tag 3`) on every tag change, driven
by a stdin loop at the bottom of `config/dwl/autostart.sh` reading dwl's own
status output. That same loop is what feeds `wsctl mark`. It needs no recompile
and no bar. Details:
[KEYMAP.en.md → Tag OSD](KEYMAP.en.md#tag-osd-dwl-only).

## Volume & brightness OSD

The `XF86Audio*` / `XF86MonBrightness*` keys in all three sessions call
`config/scripts/volumectl` and `config/scripts/brightctl` instead of `wpctl` /
`brightnessctl` directly. Each wrapper performs the change, **re-reads** the
resulting value (never guesses old ± step — the value is clamped at both ends),
and renders a centred OSD via `config/scripts/osd`: glyph + percent + a progress
bar. The bar is mako's `value` hint filling the toast background
(`progress-color=over` in the `[category=osd]` block), not a separate widget.

Guard rails baked in: volume caps at 100% (`wpctl -l 1.0`, otherwise repeated
volume-up keeps boosting gain past 100% into distortion) and brightness has a
floor of raw value 1 (`brightnessctl -n1`, otherwise the screen can go fully dark
with no way to see it back up). `brightnessctl` needs no sudo here — the Fedora
build talks to logind's `SetBrightness` D-Bus method, which also means it only
works from the active graphical session.

> Gotcha: `brightnessctl -n 1` (with a space) silently does nothing — `-n` takes
> an *optional* argument, so the detached `1` is parsed as the operation and the
> command degrades into "print info", exit code 0. It must be `-n1`.

## XDG autostart

None of the three compositors process `.desktop` autostart entries on their own,
so `~/.config/autostart` and `/etc/xdg/autostart` used to be dead files —
`nm-applet`, `blueman`, `spice-vdagent` and Slack never started.
`config/scripts/xdg-autostart` is a ~100-line POSIX shell parser called last from
each session's autostart block (`labwc/autostart`, `dwl/autostart.sh`,
`hypr/hyprland.lua`), after the five hardcoded daemons are already up.

`dex` is not packaged for Fedora, and systemd's `xdg-desktop-autostart.target`
carries `RefuseManualStart=yes` (it needs a session target plus
`import-environment` to be usable) — hence the small script.

It honours `Hidden`, `X-GNOME-Autostart-enabled`, `TryExec`, `OnlyShowIn` /
`NotShowIn` (matched against `XDG_CURRENT_DESKTOP`), reads only the
`[Desktop Entry]` group, strips `%U`-style field codes, and lets a user entry
override a system entry of the same basename.

```bash
~/.config/scripts/xdg-autostart -n   # dry run: what starts, and why the rest doesn't
~/.config/scripts/xdg-autostart      # (re)launch everything
~/.config/scripts/xdg-autostart -k   # kill what the last run started
```

On this machine 7 entries start: `blueman-applet`, `nm-applet`,
`spice-vdagent`, `xdg-user-dirs-update`, `abrt-applet`, `geoclue-demo-agent`,
`slack`. `OnlyShowIn` alone drops the whole Plasma/XFCE/GNOME stack; the
remaining noise (KDE daemons that forgot to set `OnlyShowIn`, VM guest tools,
the live-installer setup) is listed in `config/scripts/xdg-autostart.skip`.
It is a **skip**-list, not an allowlist, so a newly installed package's tray
applet works without editing anything. Delete a line to re-enable an entry.

> Launched PIDs are recorded in `$XDG_RUNTIME_DIR/xdg-autostart.pids` and killed
> at the start of the next run, so a second login without a reboot does not leave
> two `nm-applet`s fighting over the tray. The command is run as
> `sh -c "exec …"` — without `exec` the recorded PID is the shell's, and killing
> it leaves the real process orphaned.

## Power menu

`Ctrl+Cmd+Q` in all three sessions opens `config/scripts/powermenu` — a
`fuzzel --dmenu` list: Lock, Log Out, Suspend, Reboot, Shut Down. The three
session-ending entries require a second confirmation with `Cancel` preselected.
Also reachable from the `󰐥` button at the right end of sfwbar and from labwc's
right-click **Power** submenu (that route has no confirmation).

Log Out runs `loginctl terminate-session`, not a per-WM exit action: labwc has no
exit CLI and dwl has no IPC, so logind is the only uniform path — and unlike
labwc's `Exit` or Hyprland's `Super+Shift+Q`, it actually closes the logind
session instead of just killing the compositor. `poweroff`/`reboot`/`suspend`
need no sudo (logind + polkit, with `lxpolkit` already autostarted).

> Gotcha: the Fedora package is **upstream** swaylock, not swaylock-effects, so
> `screenshots` / `effect-blur` do not exist. Putting them in
> `config/swaylock/config` makes swaylock fail to start — leaving the screen
> unlocked.

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

## Troubleshooting

### Session goes unresponsive after being left alone (clicks stop registering)

Not a compositor bug — on Fedora it is almost always **`plasma-drkonqi`'s coredump
handler in a self-feeding crash loop**. Some app crashes (here: `vicinae`),
`drkonqi-coredump-processor@` fires, `drkonqi-coredump-launcher` *itself*
segfaults, its own coredump re-triggers the processor, and it never stops. Measured
on this machine: **14,219 launcher segfaults in 3 hours** (~1.3/s), `systemd --user`
burning 40+ minutes of CPU, 87 failed `drkonqi-coredump-processor@*` units. The
compositor's event loop starves and input queues up:

```
[libinput] client bug: event processing lagging behind by 72ms, your system is too slow
```

drkonqi is a KDE component and does nothing in a labwc/dwl/Hyprland session. Check
and kill it:

```bash
coredumpctl list --no-pager --since "-1 hour" | awk '{print $NF}' | sort | uniq -c | sort -rn
sudo systemctl mask drkonqi-coredump-processor@.service
sudo systemctl reset-failed 'drkonqi-coredump-processor@*'
# the user-side units too (mask on disk works even when the user bus is wedged):
for u in drkonqi-coredump-launcher.socket drkonqi-coredump-pickup.service \
         drkonqi-coredump-cleanup.timer drkonqi-sentry-postman.path \
         drkonqi-sentry-postman.timer; do
  ln -sfn /dev/null ~/.config/systemd/user/$u
done
```

Once the loop has run for a while `systemctl --user` may answer *"Transport
endpoint is not connected"* — the user manager is buried. Masking on disk (above)
sidesteps the bus; it applies at next login. Also check `df -h /`: the storm plus
journal growth can push the root filesystem to 99%, which stalls everything on its
own.

### Duplicate helpers leaking across sessions

`xremap`, `sfwbar`, and `wsctl watch` are backgrounded from the autostart scripts,
so they reparent to PID 1 and can **survive a logout**. Logging into a second
session then leaves two of each — visible as two virtual keyboards:

```bash
grep 'Name="xremap' /proc/bus/input/devices   # expect exactly one
pgrep -a xremap                               # expect exactly one
```

Two `xremap` instances both try to `EVIOCGRAB` the same keyboard and mouse; only
one wins and the loser retries, so remaps and clicks get erratic. Kill the older
PID (compare `ps -o pid,lstart` against the compositor's own start time).
