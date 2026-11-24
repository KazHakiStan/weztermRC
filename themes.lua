local M = {}

-- order for LEADER t and the default: ~/.config/kazrc/themes.lua, shared with
-- nvim (names match its lua/kazhakistan/theme.lua); pictures: settings
-- (defaults.lua / ~/.config/kazrc/wezterm.lua)
local kazrc = require("kazrc")
local settings = kazrc.get().themes
M.order = kazrc.themes().order
M.default = kazrc.themes().default

-- Dark themes built on the ashen layout: grayscale base + accent set.
-- ANSI slots follow ashen.nvim's terminal map (ashen/variants/default/ansi.lua),
-- except black, which ashen sets to the background (invisible); g_7 is used instead.
-- ashen.nvim's grayscale; a theme can pass its own (a.grays) tinted toward its accent
local ashen_grays = {
    g_1 = "#e5e5e5", g_2 = "#d5d5d5", g_3 = "#b4b4b4", g_4 = "#a7a7a7", g_5 = "#949494",
    g_6 = "#737373", g_7 = "#535353", bg = "#121212", bg_active = "#222222", line_nr = "#aaaaaa",
}

local function ashen_like(a)
    local g = setmetatable(a.grays or {}, { __index = ashen_grays })
    local ansi = {
        g.g_7,           -- black   (g_7)
        a.accent,        -- red     (red_ember)
        a.glow,          -- green   (orange_glow)
        a.smolder,       -- yellow  (orange_smolder)
        a.blue,          -- blue
        g.g_4,           -- magenta (g_4)
        g.g_3,           -- cyan    (g_3)
        g.g_2,           -- white   (g_2)
    }
    local brights = {
        g.g_6,           -- black   (g_6; ashen has g_5, too light under white text,
                         -- e.g. Claude Code dark-ansi prompt background)
        a.accent_bright, -- red     (red_glowing)
        a.glow,
        a.smolder,
        a.blue,
        g.g_4,
        g.g_3,
        g.g_1,           -- white   (g_1)
    }
    return {
        pics = a.pics,
        bg_opacity = a.bg_opacity or 0.4,
        align = a.align,
        background = "#000000",
        -- tab bar / status colors (tabbar.lua)
        ui = {
            bg = g.bg,
            bg_active = g.bg_active,
            fg = g.g_2,
            muted = g.g_6,
            accent = a.accent,
            bright = a.accent_bright,
            glow = a.glow,
            shimmer = a.shimmer, -- { base, highlight }
        },
        colors = {
            foreground = "#ffffff",
            background = g.bg,

            cursor_fg = "#000000",
            cursor_bg = a.cursor,
            cursor_border = a.cursor,

            selection_fg = "#ffffff",
            selection_bg = a.selection,

            scrollbar_thumb = g.g_7,
            split = a.split,

            ansi = ansi,
            brights = brights,

            tab_bar = {
                background = g.bg,
                active_tab = { bg_color = g.bg_active, fg_color = a.active_tab },
                inactive_tab = { bg_color = g.bg, fg_color = a.accent },
                inactive_tab_hover = { bg_color = g.bg_active, fg_color = a.accent },
                new_tab = { bg_color = g.bg, fg_color = a.accent },
                new_tab_hover = { bg_color = g.bg_active, fg_color = a.accent },
            },
        },
    }
end

M.themes = {
    -- ashen.nvim default palette (red), over the red Aegis
    ["ashen"] = ashen_like({
        pics          = "aegis-red*",
        accent        = "#b14242", -- red_ember
        accent_bright = "#df6464", -- red_glowing
        glow          = "#d87c4a", -- orange_glow
        smolder       = "#e49a44", -- orange_smolder
        blue          = "#4a8b8b",
        cursor        = "#aaaaaa",
        selection     = "#6f2929", -- red_ashen
        split         = "#6f2929",
        active_tab    = "#aaaaaa",
        shimmer       = { "#b14242", "#e5e5e5" }, -- same as proto-agent
    }),
    -- ashen layout recolored from assets/aegis-lavender.png
    ["aegis-lavender"] = ashen_like({
        pics          = "aegis-lavender*",
        accent        = "#b98af0", -- lavender
        accent_bright = "#e4a8fc", -- light lavender
        glow          = "#3cf0f0", -- neon cyan
        smolder       = "#e08cd8", -- pink
        blue          = "#2fb8c0",
        cursor        = "#e4a8fc",
        selection     = "#543c6c", -- deep violet
        split         = "#6c3c84",
        active_tab    = "#3cf0f0",
        shimmer       = { "#b98af0", "#3cf0f0" }, -- lavender swept by cyan
    }),
    -- Metaphor-like: black, amber gold and parchment (assets/aegis-gold.png)
    ["aegis-gold"] = ashen_like({
        pics          = "aegis-gold*",
        accent        = "#d4a13f", -- amber gold
        accent_bright = "#f0d58a", -- light gold
        glow          = "#f2e6c4", -- parchment
        smolder       = "#e0a040", -- amber
        blue          = "#5f9e8f", -- jade, the one cool contrast
        cursor        = "#f0d58a",
        selection     = "#5a4520", -- dark bronze
        split         = "#7a5a24",
        active_tab    = "#f2e6c4",
        shimmer       = { "#d4a13f", "#fff3d0" }, -- gold catching the light
    }),
    -- Demi-fiend (SMT V: Vengeance): night-green city, jade markings, the
    -- chartreuse glow of his eyes (assets/demifiend.png, assets/src/demifiend.py)
    ["demifiend"] = ashen_like({
        pics          = "demifiend", -- blurred: demifiend-glass (kazrc themes.lua glass)
        bg_opacity    = 0.65,     -- a dark picture, pre-toned for text
        align         = "Center", -- he stands in the middle
        accent        = "#35b88a", -- jade markings
        accent_bright = "#9ef0cc", -- their mint glow
        glow          = "#d8e070", -- the eyes
        smolder       = "#e6c85a", -- gold-yellow
        blue          = "#5a9fd4", -- Pixie's blue
        cursor        = "#d8e070",
        selection     = "#174a35", -- deep jade
        split         = "#1f5a42",
        active_tab    = "#9ef0cc",
        shimmer       = { "#35b88a", "#d8e070" }, -- jade lit by the eyes
        -- ashen's grays tinted toward the jade (same OKLab lightness, chroma 0.02);
        -- shared with nvim's demifiend palette (g_*)
        grays = {
            g_1 = "#dee8e3", g_2 = "#cdd8d3", g_3 = "#aab8b1", g_4 = "#9caba4", g_5 = "#899891",
            g_6 = "#697770", g_7 = "#495750", bg = "#0e1411", bg_active = "#1c2420", line_nr = "#9faea7",
        },
    }),
    -- Atomic Heart (the Twins): Soviet red, gold, chrome over violet-black
    -- (assets/atomic-heart.png, assets/src/atomic_heart.py)
    ["atomic-heart"] = ashen_like({
        pics          = "atomic-heart", -- blurred: atomic-heart-glass (kazrc themes.lua glass)
        bg_opacity    = 0.45,
        accent        = "#c8283c", -- the red star
        accent_bright = "#ec5464",
        glow          = "#e0b562", -- gold jacket
        smolder       = "#c8924a", -- brass
        blue          = "#8fa3b8", -- steel
        cursor        = "#e0b562",
        selection     = "#5a1a24", -- deep crimson
        split         = "#6b1f2a",
        active_tab    = "#dcdbda", -- chrome
        shimmer       = { "#c8283c", "#e0b562" }, -- red catching gold
        -- ashen's grays tinted toward the red star (same OKLab lightness, chroma 0.02);
        -- shared with nvim's palette (g_*)
        grays = {
            g_1 = "#eee2e1", g_2 = "#dfd2d1", g_3 = "#c0b0af", g_4 = "#b4a3a2", g_5 = "#a0908f",
            g_6 = "#7f6f6e", g_7 = "#5e4f4e", bg = "#161010", bg_active = "#291f1f", line_nr = "#b7a6a5",
        },
    }),
    -- The Illusive Man before his star (Mass Effect 2): Paragon blue, ice,
    -- the ember of his cigarette (assets/illusive-man.png,
    -- assets/src/illusive_man.py)
    ["illusive-man"] = ashen_like({
        pics          = "illusive-man", -- blurred: illusive-man-glass (kazrc themes.lua glass)
        bg_opacity    = 0.5,
        align         = "Center", -- he sits in the middle of the star
        accent        = "#4a9fe0", -- Paragon blue
        accent_bright = "#a4cef9", -- the star's ice
        glow          = "#7fd8f0", -- cyan corona
        smolder       = "#e8a050", -- cigarette ember
        blue          = "#7a8ce0", -- indigo
        cursor        = "#a4cef9",
        selection     = "#1f3152", -- deep space blue
        split         = "#2e476c",
        active_tab    = "#cbdbfe",
        shimmer       = { "#4a9fe0", "#cbdbfe" }, -- blue flaring white
        -- ashen's grays tinted toward Paragon blue (same OKLab lightness, chroma 0.02);
        -- shared with nvim's palette (g_*)
        grays = {
            g_1 = "#dee6ee", g_2 = "#cdd7df", g_3 = "#aab6c0", g_4 = "#9da9b3", g_5 = "#8a96a0",
            g_6 = "#6a757e", g_7 = "#4a555e", bg = "#0e1316", bg_active = "#1c2329", line_nr = "#a0acb6",
        },
    }),
    -- SMT V: Vengeance, Taito: ultramarine and shafts of cyan light
    -- (assets/smtvv-taito.png, assets/src/picture.py)
    ["smtvv-taito"] = ashen_like({
        pics          = "smtvv-taito", -- blurred: smtvv-taito-glass (kazrc themes.lua glass)
        bg_opacity    = 0.5,
        accent        = "#6f8cff", -- ultramarine
        accent_bright = "#b0c4ff",
        glow          = "#7fe0f0", -- the light shafts
        smolder       = "#e8d8a0", -- pale sand
        blue          = "#4fb0e0",
        cursor        = "#a0d7ed",
        selection     = "#232a6e", -- deep ultramarine
        split         = "#3a4fb6",
        active_tab    = "#e0f6f9",
        shimmer       = { "#6f8cff", "#e0f6f9" }, -- blue lit white
        -- ashen's grays tinted toward the ultramarine (same OKLab lightness, chroma 0.02);
        -- shared with nvim's palette (g_*)
        grays = {
            g_1 = "#e2e5ee", g_2 = "#d1d5df", g_3 = "#afb4c1", g_4 = "#a2a7b4", g_5 = "#8f94a1",
            g_6 = "#6f737f", g_7 = "#4f535f", bg = "#101217", bg_active = "#1f2229", line_nr = "#a5aab7",
        },
    }),
    -- Persona 4, the Midnight Channel studio: TV yellow, stage amber
    -- (assets/persona4-tv.png, assets/src/picture.py)
    ["persona4-tv"] = ashen_like({
        pics          = "persona4-tv", -- blurred: persona4-tv-glass (kazrc themes.lua glass)
        bg_opacity    = 0.35,     -- a very bright picture
        align         = "Center",
        accent        = "#f4c430", -- Persona 4 yellow
        accent_bright = "#fbf250", -- the screens
        glow          = "#ffe89a", -- stage light
        smolder       = "#e8873a", -- amber
        blue          = "#5aa0d8", -- the screens' blue
        cursor        = "#fbf250",
        selection     = "#5a4515", -- dark gold
        split         = "#76561d",
        active_tab    = "#fbf250",
        shimmer       = { "#d6a92c", "#fbf250" }, -- gold flaring yellow
        -- ashen's grays tinted toward Persona 4 yellow (same OKLab lightness, chroma 0.02);
        -- shared with nvim's palette (g_*)
        grays = {
            g_1 = "#e9e5dc", g_2 = "#d9d5ca", g_3 = "#b9b4a7", g_4 = "#aca799", g_5 = "#999487",
            g_6 = "#787366", g_7 = "#575347", bg = "#14120d", bg_active = "#25221a", line_nr = "#afaa9c",
        },
    }),
    -- Cyberpunk 2077: Phantom Liberty, Songbird before the red sphere: neon
    -- red, netrunner cyan (assets/cyberpunk-songbird.png, assets/src/picture.py)
    ["cyberpunk-songbird"] = ashen_like({
        pics          = "cyberpunk-songbird", -- blurred: cyberpunk-songbird-glass (kazrc themes.lua glass)
        bg_opacity    = 0.8,      -- a very dark picture
        align         = "Center", -- she stands before the sphere
        accent        = "#e62e4b", -- neon red
        accent_bright = "#ff6a7e",
        glow          = "#5fc8d8", -- netrunner cyan
        smolder       = "#e8d44a", -- Cyberpunk yellow
        blue          = "#3f8fa8", -- cable teal
        cursor        = "#5fc8d8",
        selection     = "#562b2e", -- dark red
        split         = "#982129",
        active_tab    = "#5fc8d8",
        shimmer       = { "#e62e4b", "#5fc8d8" }, -- red glitching to cyan
        -- ashen's grays tinted toward the neon red (same OKLab lightness, chroma 0.02);
        -- shared with nvim's palette (g_*)
        grays = {
            g_1 = "#eee2e2", g_2 = "#dfd1d1", g_3 = "#c0b0af", g_4 = "#b4a2a2", g_5 = "#a0908f",
            g_6 = "#7f6f6e", g_7 = "#5e4f4f", bg = "#161010", bg_active = "#291f1f", line_nr = "#b7a5a5",
        },
    }),
    -- LEGACY: gruvbox dark over a Silent Hunter 5 screenshot. To move into kazRC
    -- as a user theme (the test case for custom themes) and leave the defaults.
    ["silent-hunter"] = {
        pics = "silent-hunter*",
        -- tab bar / status colors (tabbar.lua)
        ui = {
            bg = "#282828",
            bg_active = "#504945",
            fg = "#ebdbb2",
            muted = "#a89984",
            accent = "#d79921",
            bright = "#fabd2f",
            glow = "#458588",
            shimmer = { "#d79921", "#fbf1c7" },
        },
        colors = {
            foreground = "#ebdbb2",
            background = "#282828",

            cursor_bg = "#ebdbb2",
            cursor_fg = "#282828",
            cursor_border = "#ebdbb2",

            selection_fg = "#282828",
            selection_bg = "#d79921",

            scrollbar_thumb = "#665c54",

            split = "#665c54",

            ansi = {
                "#282828",  -- black
                "#cc241d",  -- red
                "#98971a",  -- green
                "#d79921",  -- yellow
                "#458588",  -- blue
                "#b16286",  -- magenta
                "#689d6a",  -- cyan
                "#a89984"   -- white
            },

            brights = {
                "#928374",  -- black
                "#fb4934",  -- red
                "#b8bb26",  -- green
                "#fabd2f",  -- yellow
                "#83a598",  -- blue
                "#d3869b",  -- magenta
                "#8ec07c",  -- cyan
                "#ebdbb2"   -- white
            },

            -- Optional: Tab bar colors
            tab_bar = {
                background = "#282828",
                active_tab = {
                    bg_color = "#504945",
                    fg_color = "#ebdbb2",
                },
                inactive_tab = {
                    bg_color = "#3c3836",
                    fg_color = "#a89984",
                },
                inactive_tab_hover = {
                    bg_color = "#504945",
                    fg_color = "#ebdbb2",
                },
                new_tab = {
                    bg_color = "#282828",
                    fg_color = "#a89984",
                },
                new_tab_hover = {
                    bg_color = "#504945",
                    fg_color = "#ebdbb2",
                },
            },
        },
        bg_opacity = 0.4,
        background = "#000000",
    },
    ["metaphor-light"] = {
        -- Metaphor palette (same as nvim's light override): ink, crimson, laurel,
        -- antique gold, royal blue, plum, jade; ~4:1 contrast over the print
        colors = {
            foreground = "#3b2a1a",
            background = "#fbf1c7",

            cursor_bg = "#7a5806",
            cursor_fg = "#fbf1c7",
            cursor_border = "#7a5806",

            selection_fg = "#2c1f12",
            selection_bg = "#f0d38c", -- gold leaf

            scrollbar_thumb = "#bdae93",

            split = "#b57614",

            ansi = {
                "#fbf1c7", -- black (gruvbox light convention: the background)
                "#a30d1f", -- red: crimson
                "#4f5e1e", -- green: laurel
                "#7a5806", -- yellow: antique gold
                "#2b5585", -- blue: royal blue
                "#7a3c6c", -- magenta: plum
                "#24605a", -- cyan: jade
                "#62523c", -- white: dark sepia
            },

            brights = {
                "#74624a", -- black: sepia (comments, autosuggestions)
                "#a30d1f",
                "#4f5e1e",
                "#7a5806",
                "#2b5585",
                "#7a3c6c",
                "#24605a",
                "#2c1f12", -- white: ink
            },

            -- parchment bar with gold accents (matches the Metaphor print)
            tab_bar = {
                background = "#ebdbb2",
                active_tab = { bg_color = "#d5c4a1", fg_color = "#b57614" },
                inactive_tab = { bg_color = "#ebdbb2", fg_color = "#7c6f64" },
                inactive_tab_hover = { bg_color = "#d5c4a1", fg_color = "#b57614" },
                new_tab = { bg_color = "#ebdbb2", fg_color = "#b57614" },
                new_tab_hover = { bg_color = "#d5c4a1", fg_color = "#af3a03" },
            },
        },
        -- assets/metaphor-light{1,2}.png are pre-toned prints on parchment
        -- (assets/src/light_from_art.py + light_ornate.py), shown as they are
        bg_opacity = 1.0,
        background = "#fbf1c7",
        pics = "metaphor-light*",
        -- the window is rarely 16:9: crop the print evenly, and draw the frame as
        -- its own layer stretched to the window so it always sits at the edges
        align = "Center",
        overlay = "frame-metaphor-light.png",
        ui = {
            bg = "#ebdbb2",        -- gruvbox bg1
            bg_active = "#d5c4a1", -- bg2
            fg = "#3c3836",
            muted = "#7c6f64",
            accent = "#b57614",    -- gold (gruvbox yellow, dark)
            bright = "#b57614",
            glow = "#076678",      -- blue: MOVE badge stands apart from LEADER
            shimmer = { "#b57614", "#d65d0e" }, -- gold catching orange light
        },
    },
}

-- names in themes.lua that WezTerm has no theme for: skipped, reported on the bar
do
    local known = {}
    for _, n in ipairs(M.order) do
        if M.themes[n] then known[#known + 1] = n else kazrc.add_problem("themes.lua: no theme `" .. tostring(n) .. "`") end
    end
    M.order = #known > 0 and known or { "ashen" }
    if not M.themes[M.default] then
        kazrc.add_problem("themes.lua: default `" .. tostring(M.default) .. "` isn't a theme")
        M.default = M.order[1]
    end
end

function M.get(theme_name)
    return M.themes[theme_name] or M.themes[M.default] or M.themes.ashen
end

-- background pictures of a theme: the setting, else the theme's own glob;
-- with glass, its blurred version (<glob>-glass) when there is one
function M.pictures(theme_name, glass)
    local glob = settings.pictures[theme_name] or M.get(theme_name).pics
    if glass and #require("constants").list_pics(glob .. "-glass") > 0 then
        return glob .. "-glass"
    end
    return glob
end

function M.build(theme_name, bg_file)
    local t = M.get(theme_name)
    local layers = {
        {
            source = { Color = t.background },
            opacity = 1,
            height = "100%",
            width = "100%",
        },
    }
    if bg_file and bg_file ~= "" then
        -- Cover keeps aspect ratio; by default pinned right, where the Aegis art is
        table.insert(layers, {
            source = { File = bg_file },
            opacity = t.bg_opacity or 0.4,
            width = "Cover",
            height = "Cover",
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
            horizontal_align = t.align or "Right",
            vertical_align = "Middle",
        })
    end
    if t.overlay then
        -- transparent PNG stretched to the window (e.g. a frame)
        local constants = require("constants")
        table.insert(layers, {
            source = { File = constants.join(constants.paths.assets_dir, t.overlay) },
            opacity = 1.0,
            width = "100%",
            height = "100%",
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
        })
    end
    return { colors = t.colors, background = layers }
end

return M
