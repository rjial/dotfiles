-- hyprland.lua — config Hyprland format Lua. SUMBER KEBENARAN sejak 0.56.
--
-- KENAPA Lua: format `.conf` (hyprlang) dibuang di Hyprland 0.57. 0.56 sudah
-- menampilkan dialog "You are using the .conf config format, support for which
-- will be removed in Hyprland 0.57." tiap start sesi. `hyprland.conf` masih
-- disimpan di repo sebagai rujukan, tapi Hyprland MENGABAIKANNYA total begitu
-- file .lua ini ada: log memberi `[cfg] Using lua config found at …`.
--
-- KENDALA xremap (WAJIB DIBACA sebelum menambah keybind):
-- xremap me-remap Super+<huruf> berikut menjadi Ctrl+ untuk shortcut GUI app:
--   a b c d e f g i j k l n o p r s t u v w x y z , - = backspace
--   + Shift-z Shift-t Shift-g
-- Huruf itu TAK PERNAH sampai ke Hyprland. Yang tersisa untuk compositor:
--   q m h  space Return Tab grave  panah  digit 0-9  period slash
--   bracketleft bracketright  Print  XF86*  dan semua kombinasi
--   Ctrl+Super+* / Alt+Super+* (xremap exact-match, jadi modifier tambahan lolos)
--
-- Deploy: `make link` (symlink config/hypr -> ~/.config/hypr). Hyprland
-- auto-reload saat file disimpan; paksa dgn `hyprctl reload`.
-- Validasi: `hyprctl configerrors` (kosong = bersih), `hyprctl binds`.

local mod   = "SUPER"
local term  = "foot"
local menu  = "fuzzel"
local home  = os.getenv("HOME")
local script = home .. "/.config/scripts/"

---------------------------------------------------------------- monitor
-- output = "" -> catch-all, berlaku untuk output apa pun (eDP-1, HDMI-A-1, ...).
-- Multi-monitor / skala khusus: JANGAN edit sini — tulis di
-- ~/.config/hypr/local.lua (di-load paling bawah file ini, tak di-track git).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Workspace 1-8 selalu ada. WAJIB untuk swipe 3 jari: Hyprland hanya menggeser
-- ke workspace yang SUDAH ada (workspace_swipe_create_new = false), jadi tanpa
-- persistent cuma workspace 1 yg eksis dan gesture tampak mati.
-- Tanpa field `monitor` = ikut monitor mana pun, jadi portabel antar mesin.
--
-- default_name = glyph nerd-font md-numeric_N_circle U+F0CA0 + 2*(N-1),
-- HARUS sama dgn labwc/rc.xml <desktops><names> dan sfwbar.config label pager.
-- Kalau beda, pager sfwbar render dua set tombol (glyph phantom + "1".."8").
local ws_glyphs = { "󰲠", "󰲢", "󰲤", "󰲦", "󰲨", "󰲪", "󰲬", "󰲮" }
for i, glyph in ipairs(ws_glyphs) do
    hl.workspace_rule({ workspace = tostring(i), persistent = true, default_name = glyph })
end

---------------------------------------------------------------- env
-- Mirror config/labwc/environment
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
-- Chromium/Electron (Thorium, Helium, VSCode) native Wayland — memperbaiki
-- address bar tak bisa diklik saat jalan lewat XWayland di WM wlroots.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- JetBrains/Java di XWayland
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

---------------------------------------------------------------- autostart
-- Mirror config/labwc/autostart — stack dibagi dgn labwc/dwl.
--
-- Guard HYPR_TEST: instance Hyprland bersarang (dipakai untuk menguji config ini
-- tanpa mempertaruhkan sesi asli) TIDAK boleh menyalakan daemon kedua kalinya —
-- xremap kedua berebut grab input, sfwbar/mako kedua menumpuk. Uji dgn
-- `HYPR_TEST=1 Hyprland -c <file>`.
if os.getenv("HYPR_TEST") ~= "1" then
    hl.on("hyprland.start", function()
        hl.exec_cmd("lxpolkit")                          -- polkit agent (udisks mount)
        hl.exec_cmd("xremap " .. home .. "/.config/xremap/config.yml")
        -- path absolut: ~/.local/bin belum tentu ada di PATH sesi display manager
        hl.exec_cmd(home .. "/.local/bin/waypaper --restore")
        hl.exec_cmd("sfwbar")                            -- menu-bar ala macOS
        hl.exec_cmd("mako")                              -- notification daemon
        hl.exec_cmd("snappy-wrapper")                    -- daemon Alt+Tab overlay;
                                                         -- wrapper menunggu socket
                                                         -- Hyprland siap dulu
        -- Entri XDG .desktop (nm-applet, blueman, spice-vdagent, slack).
        -- Dijalankan PALING AKHIR supaya 5 daemon di atas hidup lebih dulu.
        hl.exec_cmd(script .. "xdg-autostart")
    end)
end

---------------------------------------------------------------- appearance
-- Catppuccin Frappé — sinkron dgn labwc themerc + fuzzel + sfwbar.
hl.config({
    general = {
        gaps_in     = 3,                                 -- labwc <gap>6</gap> antar window
        gaps_out    = 6,
        border_size = 2,
        -- Border satu warna, persis labwc themerc (window.active/inactive.border.color)
        col = {
            active_border   = "rgba(626880ff)",          -- surface2
            inactive_border = "rgba(414559ff)",          -- surface0
        },
        layout           = "dwindle",
        resize_on_border = true,                         -- drag tepi tanpa modifier
        allow_tearing    = false,
    },

    decoration = {
        rounding         = 0,                            -- sudut tajam (labwc cornerRadius 0)
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 18,
            render_power = 3,
            color        = "rgba(232634aa)",             -- crust
        },
        blur = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            new_optimizations = true,
            xray              = false,
            noise             = 0.0117,
            contrast          = 1.0,
            brightness        = 0.9,
            -- popup/context menu (Electron, GTK) ikut diblur kalau true — blur
            -- bleed di tepi rounded corner-nya kelihatan seperti margin.
            popups            = false,
        },
    },

    animations = { enabled = true },

    dwindle = {
        -- `pseudotile` DIHAPUS upstream: pseudotile sekarang state per-window,
        -- toggle-nya dispatcher `pseudo` (Super+/ di bawah).
        preserve_split = true,
        smart_split    = false,
    },

    misc = {
        force_default_wallpaper  = 0,                    -- waypaper yang pegang wallpaper
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        focus_on_activate        = true,
        -- `vfr` pindah ke debug.vfr dan defaultnya sudah aktif — jangan ditulis.
    },

    -- Dua nag ini default HIDUP, dan baru benar-benar muncul setelah paket
    -- `hyprland-guiutils` dipasang (dialog-nya dirender hyprland-dialog):
    --   update-screen "what's new" tiap versi naik, + nag donasi berkala.
    -- Mematikannya TIDAK menyentuh dialog ANR ("aplikasi tak merespons").
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },

    -- debug.suppress_errors sengaja DIBIARKAN MATI: banner merah config error
    -- adalah satu-satunya gejala saat config pecah — rule yang tak kena tak
    -- bergejala sama sekali. Kalau terlalu ramai, kecilkan debug.error_limit.

    input = {
        kb_layout    = "us",
        follow_mouse = 0,                                -- click-to-focus (mac), sama labwc
        float_switch_override_focus = 0,
        touchpad = {
            natural_scroll       = true,                 -- mac natural scroll
            tap_to_click         = true,
            tap_and_drag         = true,
            drag_lock            = true,
            disable_while_typing = true,
            scroll_factor        = 1.0,
        },
    },

    -- Penyetel perilaku swipe workspace. "Hidup/mati" + jumlah jari TIDAK di sini
    -- lagi — itu pindah ke hl.gesture() di bawah.
    gestures = {
        workspace_swipe_distance   = 300,
        workspace_swipe_invert     = true,               -- arah natural (mac)
        workspace_swipe_create_new = false,
        workspace_swipe_forever    = true,
    },
})

-- Animasi ala macOS: cepat, ease-out, tanpa bouncing lebay.
hl.curve("macEase", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })
hl.curve("macOut",  { type = "bezier", points = { { 0.16, 1.0 }, { 0.3,  1.0 } } })

hl.animation({ leaf = "windows",          enabled = true, speed = 4, bezier = "macOut",  style = "popin 92%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3, bezier = "macEase", style = "popin 92%" })
hl.animation({ leaf = "border",           enabled = true, speed = 6, bezier = "macEase" })
hl.animation({ leaf = "fade",             enabled = true, speed = 4, bezier = "macEase" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5, bezier = "macOut",  style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "macOut",  style = "slidevert" })

-- Fitur Hyprland: 3-finger swipe antar workspace = Mission Control-ish ala mac.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

---------------------------------------------------------------- rules
-- Tiap rule butuh `name` unik: itu pegangan untuk mematikannya saat runtime
-- (`rule:set_enabled(false)`) dan yang muncul saat rule bentrok.
hl.window_rule({ name = "float-lxpolkit", match = { class = "^(lxpolkit)$" }, float = true })
hl.window_rule({
    name  = "float-system-dialogs",
    match = { class = "^(pavucontrol|nm-connection-editor|blueman-manager)$" },
    float = true,
})
hl.window_rule({
    name  = "float-file-dialogs",
    match = { title = "^(Open File|Save File|Save As)$" },
    float = true,
})

-- --- Picture-in-Picture ---
-- Window PiP Chromium (Helium/Thorium) TIDAK punya app-id sama sekali —
-- `class` di `hyprctl clients` betul-betul string kosong, jadi match HARUS
-- lewat title. Judulnya beda kapital antar browser: Chromium
-- "Picture-in-picture", Firefox/Zen "Picture-in-Picture"; regex menampung dua-duanya.
-- Anchor ^…$ WAJIB: tanpa itu judul halaman biasa spt "Picture-in-Picture
-- Sample - Helium" ikut kena dan tab browser penuh berubah jadi jendela mungil.
--
-- pin = tampil di SEMUA workspace, dan hanya berlaku untuk window floating —
-- jadi float harus menyertainya.
-- Tanpa ukuran paksa, Chromium memberi jendela ~954x864, bukan bentuk PiP biasa.
-- 480x270 = 16:9 seperempat lebar layar 1920.
-- Posisi = piksel absolut untuk 1920x1080 (1420+480=1900, 760+270=1030, sfwbar
-- mulai 1056). Monitor lain: timpa lewat ~/.config/hypr/local.lua, jangan di sini.
hl.window_rule({
    name  = "pip",
    match = { title = "^([Pp]icture[- ][Ii]n[- ][Pp]icture)$" },

    float             = true,
    pin               = true,
    size              = "480 270",
    keep_aspect_ratio = true,
    move              = "1420 760",
    no_initial_focus  = true,                            -- jangan curi fokus
})

-- Google Meet TIDAK memakai video-PiP di atas; ia memakai **Document
-- Picture-in-Picture API** (`documentPictureInPicture.requestWindow`) — window
-- HTML biasa, bukan surface video. Konsekuensi yang terlihat di `hyprctl clients`:
--   * `class` TERISI ("helium"), bukan string kosong spt video-PiP;
--   * `title` = judul halaman ("Meet – <judul rapat>") TANPA sufiks " - Helium";
--   * ukuran ~954x822 dan tidak pinned.
-- Jadi rule "pip" di atas tak pernah kena, dan window PiP Meet hilang begitu
-- ganti workspace — itu gejala yang dilaporkan user.
--
-- Pembeda satu-satunya dari window browser normal = sufiks nama browser di
-- title. Karena itu match memakai prefiks **`negative:`** (didukung 0.56,
-- diverifikasi dgn window umpan foot). Regex engine Hyprland = **RE2**
-- (`ldd /usr/bin/Hyprland` -> libre2), jadi lookahead `(?!…)` TIDAK ADA —
-- `negative:` inilah satu-satunya jalan meniadakan.
-- DevTools ikut dikecualikan: window DevTools lepas juga tak bersufiks browser.
-- Tanpa keep_aspect_ratio — isi doc-PiP HTML yang reflow, bukan video rasio tetap.
-- 640x360 di sudut kanan-bawah: 1260+640=1900, 670+360=1030 (sfwbar mulai 1056).
hl.window_rule({
    name  = "pip-document",
    match = {
        class = "^(helium|thorium|chromium|brave|google-chrome)$",
        title = "negative:^(.*(- Helium|- Thorium|- Chromium|- Brave|- Google Chrome)|DevTools.*)$",
    },

    float            = true,
    pin              = true,
    size             = "640 360",
    move             = "1260 670",
    no_initial_focus = true,
})

-- SourceGit (Avalonia, XWayland) memakai CSD: shadow + margin transparan dicat
-- SENDIRI DI DALAM surface-nya. Geometri Hyprland normal, jadi bukan gaps yang
-- salah — padding gelap itu isi window. no_blur menghentikan blur menembus
-- margin transparan; no_shadow mencegah shadow Hyprland dobel dgn shadow app.
hl.window_rule({
    name      = "sourcegit-csd",
    match     = { class = "^([Ss]ource[Gg]it)$" },
    no_shadow = true,
    no_blur   = true,
})

-- File picker portal (xdg-desktop-portal-gtk) sama persis: CSD shadow dicat di
-- dalam surface. Match by class, BUKAN title — title portal ikut bahasa/aksi
-- dialog ("Pilih folder untuk sesi lokal", dll), class-nya tetap tetap sama.
hl.window_rule({
    name      = "portal-gtk-csd",
    match     = { class = "^([Xx]dg-desktop-portal-gtk)$" },
    float     = true,
    no_shadow = true,
    no_blur   = true,
})

-- NAMESPACE sfwbar = `gtk-layer-shell`, BUKAN `sfwbar` — itu default library
-- gtk-layer-shell yang dipakai sfwbar; cek dgn `hyprctl layers`. Rule blur bar
-- yang lama menyebut `sfwbar` karena itu tak pernah kena.
hl.layer_rule({
    name         = "blur-bar",
    match        = { namespace = "^(gtk-layer-shell)$" },
    blur         = true,
    ignore_alpha = 0,
})
hl.layer_rule({
    name         = "blur-launcher",
    match        = { namespace = "^(launcher)$" },       -- fuzzel
    blur         = true,
    ignore_alpha = 0,
})

---------------------------------------------------------------- keybind
-- --- Launcher / terminal (mirror labwc) ---
hl.bind(mod .. " + space", hl.dsp.exec_cmd(menu))
hl.bind("ALT + space",     hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(term))

-- --- Window management ---
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exit())
-- mode "maximized" hormati bar (labwc ToggleMaximize); "fullscreen" = sejati.
hl.bind(mod .. " + up",         hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + down",  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))

-- --- Window switcher (snappy-switcher) ---
-- Flag `--mod` WAJIB sama dgn modifier bind-nya. Kalau beda, snappy render
-- banner CONFIG ERROR (dia menahan panel selama modifier ditekan; salah nama
-- modifier = dia tak pernah lihat tombolnya ditahan).
hl.bind("ALT + Tab",         hl.dsp.exec_cmd("snappy-switcher next --mod alt"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("snappy-switcher prev --mod alt"))
-- Super+Tab = hanya window di workspace aktif.
hl.bind(mod .. " + Tab",         hl.dsp.exec_cmd("snappy-switcher next --workspace --mod super"))
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.exec_cmd("snappy-switcher prev --workspace --mod super"))
-- Fallback tanpa GUI (kalau daemon mati). Dua aksi dalam satu bind: di format
-- .conf ini dua baris `bind` bertumpuk pada tombol yang sama; di Lua bind kedua
-- MENGGANTI yang pertama, jadi harus digabung dalam satu fungsi.
hl.bind(mod .. " + grave", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Pengganti minimize (Hyprland tak punya iconify) — special workspace.
-- labwc: Super+M / Super+H = Iconify.
hl.bind(mod .. " + M", hl.dsp.window.move({ workspace = "special:minimized", silent = true }))
hl.bind(mod .. " + H", hl.dsp.window.move({ workspace = "special:minimized", silent = true }))
hl.bind(mod .. " + SHIFT + M", hl.dsp.workspace.toggle_special("minimized"))

-- Pindah posisi window dlm tiling
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Resize (Super+minus/equal dipakai xremap untuk zoom app, jadi pakai Alt).
-- relative = true -> delta, bukan ukuran absolut.
hl.bind(mod .. " + ALT + left",  hl.dsp.window.resize({ x = -60, y = 0,   relative = true }))
hl.bind(mod .. " + ALT + right", hl.dsp.window.resize({ x = 60,  y = 0,   relative = true }))
hl.bind(mod .. " + ALT + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }))
hl.bind(mod .. " + ALT + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }))

-- Layout dwindle
hl.bind(mod .. " + period", hl.dsp.layout("togglesplit"))  -- putar arah split
hl.bind(mod .. " + slash",  hl.dsp.window.pseudo())        -- pseudotile (per-window)

-- Notifikasi (mako). Pakai Ctrl+Super supaya xremap meloloskannya —
-- Super+n / Super+d polos sudah dimakan xremap jadi Ctrl+n / Ctrl+d.
hl.bind("CTRL + " .. mod .. " + N",         hl.dsp.exec_cmd("makoctl dismiss"))
hl.bind("CTRL + " .. mod .. " + SHIFT + N", hl.dsp.exec_cmd("makoctl dismiss --all"))
hl.bind("CTRL + " .. mod .. " + D",         hl.dsp.exec_cmd("makoctl mode -t do-not-disturb"))
hl.bind("CTRL + " .. mod .. " + SHIFT + D", hl.dsp.exec_cmd("makoctl restore"))

-- Power menu (fuzzel) — sama di labwc (rc.xml C-W-q) dan dwl (config.h).
-- Ctrl+Super karena Super+Q polos = close window. Log Out di dalam menu memakai
-- `loginctl terminate-session`, jadi lebih benar daripada Super+Shift+Q (exit)
-- yang cuma membunuh compositor tanpa menutup sesi logind.
hl.bind("CTRL + " .. mod .. " + Q", hl.dsp.exec_cmd(script .. "powermenu"))

-- Multi-monitor
hl.bind(mod .. " + bracketleft",          hl.dsp.focus({ monitor = "-1" }))
hl.bind(mod .. " + bracketright",         hl.dsp.focus({ monitor = "+1" }))
hl.bind(mod .. " + SHIFT + bracketleft",  hl.dsp.workspace.move({ monitor = "-1" }))
hl.bind(mod .. " + SHIFT + bracketright", hl.dsp.workspace.move({ monitor = "+1" }))

-- --- Workspaces (8 desktop = mac Spaces; labwc/rc.xml sama) ---
-- 9 sengaja tak dipakai — sisakan kalau butuh slot khusus.
for i = 1, 8 do
    hl.bind(mod .. " + " .. i,             hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
end

-- labwc SendToDesktop left/right
hl.bind("CTRL + " .. mod .. " + left",  hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("CTRL + " .. mod .. " + right", hl.dsp.window.move({ workspace = "r+1" }))
-- Pindah workspace tanpa membawa window
hl.bind("CTRL + ALT + left",  hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + ALT + right", hl.dsp.focus({ workspace = "r+1" }))
-- Scroll di area kosong / di atas bar = ganti workspace
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- --- Screenshot (mirror labwc, mac-style Cmd+Shift+3/4) ---
local shot_file = "grim " .. home .. "/Pictures/shot-$(date +%s).png"
local shot_area = 'grim -g "$(slurp)" ' .. home .. "/Pictures/shot-$(date +%s).png"
local copy_file = "grim - | wl-copy -t image/png"
local copy_area = 'grim -g "$(slurp)" - | wl-copy -t image/png'

hl.bind(mod .. " + SHIFT + 3",          hl.dsp.exec_cmd(shot_file))
hl.bind(mod .. " + SHIFT + 4",          hl.dsp.exec_cmd(shot_area))
hl.bind("CTRL + " .. mod .. " + SHIFT + 3", hl.dsp.exec_cmd(copy_file))
hl.bind("CTRL + " .. mod .. " + SHIFT + 4", hl.dsp.exec_cmd(copy_area))
-- Tombol PrtSc: default clipboard; + Ctrl = ke file
hl.bind("Print",               hl.dsp.exec_cmd(copy_file))
hl.bind("SHIFT + Print",       hl.dsp.exec_cmd(copy_area))
hl.bind("CTRL + Print",        hl.dsp.exec_cmd(shot_file))
hl.bind("CTRL + SHIFT + Print", hl.dsp.exec_cmd(shot_area))

-- --- Media key ---
-- Lewat wrapper ~/.config/scripts/{volumectl,brightctl} supaya tiap perubahan
-- memunculkan OSD (mako, kategori `osd`). Wrapper-lah yang memanggil wpctl/
-- brightnessctl — jangan balik ke pemanggilan langsung, OSD-nya ikut hilang.
--
-- locked = tetap jalan saat layar terkunci (bindl di .conf);
-- repeating = auto-repeat saat tombol ditahan (huruf `e` di bindel).
local el = { locked = true, repeating = true }
local l  = { locked = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(script .. "volumectl up"),       el)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(script .. "volumectl down"),     el)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(script .. "volumectl mute"),     l)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(script .. "volumectl mic-mute"), l)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(script .. "brightctl up"),       el)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(script .. "brightctl down"),     el)

-- --- Mouse (mirror dwl buttons[]) ---
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })  -- pindah
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })  -- resize
hl.bind(mod .. " + mouse:274", hl.dsp.window.float({ action = "toggle" }))

---------------------------------------------------------------- local override
-- Override per-mesin: monitor tambahan, resolusi/refresh/skala, posisi PiP.
-- TIDAK di-track git; `make link` membuatnya kalau belum ada. Dicek dulu
-- keberadaannya sebab `dofile` pada file yang tak ada = error fatal, dan config
-- yang gagal dimuat menjatuhkan sesi ke safe mode.
local localfile = home .. "/.config/hypr/local.lua"
local f = io.open(localfile, "r")
if f then
    f:close()
    dofile(localfile)
end
