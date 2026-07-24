/* dwl config.h — mirror setup labwc macOS-style (Super = Cmd).
 *
 * KENDALA xremap: xremap me-remap Super+<huruf> (a c v x z s f n t r p o w l d
 * e g b i u y k j , - =) menjadi Ctrl+ untuk shortcut GUI app. Huruf-huruf itu
 * TAK PERNAH sampai ke dwl. Maka semua keybind window-management dwl HANYA pakai
 * key yang xremap lewatkan: q m h space tab grave arrow digit period slash
 * bracket Print, dan Shift+huruf (kecuali Shift+z/t/g yang juga di-remap).
 *
 * Sumber kebenaran ada di ~/.dotfiles/config/dwl/config.h — edit di sana dulu,
 * salin ke ~/Dokumen/dwl/config.h, lalu RECOMPILE (make && sudo make install).
 */

/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }
/* appearance — Catppuccin Frappé (samakan dgn sfwbar/fuzzel) */
static const int sloppyfocus               = 0;  /* mac = click-to-focus */
static const int bypass_surface_visibility = 0;
static const unsigned int borderpx         = 2;
static const float rootcolor[]             = COLOR(0x303446ff); /* base */
static const float bordercolor[]           = COLOR(0x51576dff); /* surface1 */
static const float focuscolor[]            = COLOR(0x81c8beff); /* teal */
static const float urgentcolor[]           = COLOR(0xe78284ff); /* red */
/* This conforms to the xdg-protocol. Set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.0f, 1.0f};

/* tagging - TAGCOUNT must be no greater than 31 */
#define TAGCOUNT (9)

/* logging */
static int log_level = WLR_ERROR;

static const Rule rules[] = {
	/* app_id             title       tags mask     isfloating   monitor */
	/* dialog kecil biar floating, tak dipaksa ke tile */
	{ "fuzzel",           NULL,       0,            1,           -1 },
	{ "lxpolkit",         NULL,       0,            1,           -1 },
	/* default/example rule: minimal satu rule harus ada */
	{ "Gimp_EXAMPLE",     NULL,       0,            1,           -1 },
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* monitors */
static const MonitorRule monrules[] = {
	{ NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	/* default monitor rule: minimal satu harus ada */
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	.options = NULL,
};

static const int repeat_rate = 25;
static const int repeat_delay = 600;

/* Trackpad — mac-like */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 1;   /* mac natural scroll */
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* MODKEY = Super = Cmd */
#define MODKEY WLR_MODIFIER_LOGO

/* Tag: Super+N = lihat tag N; Super+Shift+N = pindah window ke tag N.
 * digit & symbol shifted TIDAK di-remap xremap, jadi sampai ke dwl. */
#define TAGKEYS(KEY,SKEY,TAG) \
	{ MODKEY,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL,  KEY,            toggleview,      {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_SHIFT, SKEY,           tag,             {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT,SKEY,toggletag, {.ui = 1 << TAG} }

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *termcmd[] = { "foot", NULL };
static const char *menucmd[] = { "fuzzel", NULL };

static const Key keys[] = {
	/* modifier                     key                function          argument */

	/* --- Launcher / terminal (mirror labwc W-space / W-Return) --- */
	{ MODKEY,                       XKB_KEY_space,     spawn,            {.v = menucmd} },
	{ MODKEY,                       XKB_KEY_Return,    spawn,            {.v = termcmd} },

	/* --- Fokus antar window (mirror W-Tab / W-grave) --- */
	{ MODKEY,                       XKB_KEY_Tab,       focusstack,       {.i = +1} },
	{ MODKEY|WLR_MODIFIER_SHIFT,    XKB_KEY_ISO_Left_Tab, focusstack,    {.i = -1} },
	{ MODKEY,                       XKB_KEY_grave,     focusstack,       {.i = +1} },

	/* --- Window (mirror W-q close, W-Up maximize, W-Down) --- */
	{ MODKEY,                       XKB_KEY_q,         killclient,       {0} },
	{ MODKEY,                       XKB_KEY_Up,        togglefullscreen, {0} },
	{ MODKEY,                       XKB_KEY_Down,      togglefloating,   {0} },

	/* --- Master/size (arrow, gantikan snap labwc) --- */
	{ MODKEY,                       XKB_KEY_Left,      setmfact,         {.f = -0.05f} },
	{ MODKEY,                       XKB_KEY_Right,     setmfact,         {.f = +0.05f} },
	{ MODKEY|WLR_MODIFIER_SHIFT,    XKB_KEY_greater,   incnmaster,       {.i = +1} }, /* Super+Shift+period */
	{ MODKEY|WLR_MODIFIER_SHIFT,    XKB_KEY_less,      incnmaster,       {.i = -1} }, /* Super+Shift+comma */
	{ MODKEY|WLR_MODIFIER_SHIFT,    XKB_KEY_Return,    zoom,             {0} },

	/* --- Layout (huruf t/f di-remap xremap → pakai period/slash/m) --- */
	{ MODKEY,                       XKB_KEY_period,    setlayout,        {.v = &layouts[0]} }, /* tile  []= */
	{ MODKEY,                       XKB_KEY_slash,     setlayout,        {.v = &layouts[1]} }, /* float ><> */
	{ MODKEY,                       XKB_KEY_m,         setlayout,        {.v = &layouts[2]} }, /* mono  [M] */

	/* --- Multi-monitor (bracket) --- */
	{ MODKEY,                       XKB_KEY_bracketleft,  focusmon,      {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY,                       XKB_KEY_bracketright, focusmon,      {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|WLR_MODIFIER_SHIFT,    XKB_KEY_braceleft,    tagmon,        {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_SHIFT,    XKB_KEY_braceright,   tagmon,        {.i = WLR_DIRECTION_RIGHT} },

	/* --- Tags (mirror W-1..4, diperluas ke 1-9) --- */
	{ MODKEY,                       XKB_KEY_0,         view,             {.ui = ~0} },
	{ MODKEY|WLR_MODIFIER_SHIFT,    XKB_KEY_parenright,tag,              {.ui = ~0} },
	TAGKEYS(          XKB_KEY_1, XKB_KEY_exclam,                        0),
	TAGKEYS(          XKB_KEY_2, XKB_KEY_at,                            1),
	TAGKEYS(          XKB_KEY_3, XKB_KEY_numbersign,                    2),
	TAGKEYS(          XKB_KEY_4, XKB_KEY_dollar,                        3),
	TAGKEYS(          XKB_KEY_5, XKB_KEY_percent,                       4),
	TAGKEYS(          XKB_KEY_6, XKB_KEY_asciicircum,                   5),
	TAGKEYS(          XKB_KEY_7, XKB_KEY_ampersand,                     6),
	TAGKEYS(          XKB_KEY_8, XKB_KEY_asterisk,                      7),
	TAGKEYS(          XKB_KEY_9, XKB_KEY_parenleft,                     8),

	/* --- Screenshot (Print-based; TIDAK pakai Super+Shift+digit krn bentrok
	 *     dgn tag). Mirror labwc: Print=clipboard, +Ctrl=file. --- */
	{ 0,                            XKB_KEY_Print,     spawn, SHCMD("grim - | wl-copy -t image/png") },
	{ WLR_MODIFIER_SHIFT,           XKB_KEY_Print,     spawn, SHCMD("grim -g \"$(slurp)\" - | wl-copy -t image/png") },
	{ WLR_MODIFIER_CTRL,            XKB_KEY_Print,     spawn, SHCMD("grim ~/Pictures/shot-$(date +%s).png") },
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_Print, spawn, SHCMD("grim -g \"$(slurp)\" ~/Pictures/shot-$(date +%s).png") },

	/* --- Media keys (mirror labwc, wpctl) --- */
	{ 0, XKB_KEY_XF86AudioRaiseVolume, spawn, SHCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") },
	{ 0, XKB_KEY_XF86AudioLowerVolume, spawn, SHCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") },
	{ 0, XKB_KEY_XF86AudioMute,        spawn, SHCMD("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") },

	/* --- Quit dwl --- */
	{ MODKEY|WLR_MODIFIER_SHIFT,    XKB_KEY_q,         quit,             {0} },
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_Terminate_Server, quit, {0} },
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_XF86Switch_VT_##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};
