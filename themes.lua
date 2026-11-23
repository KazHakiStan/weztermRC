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
local function ashen_like(a)
    local ansi = {
        "#535353",       -- black   (g_7)
        a.accent,        -- red     (red_ember)
        a.glow,          -- green   (orange_glow)
        a.smolder,       -- yellow  (orange_smolder)
        a.blue,          -- blue
        "#a7a7a7",       -- magenta (g_4)
        "#b4b4b4",       -- cyan    (g_3)
        "#d5d5d5",       -- white   (g_2)
    }
    local brights = {
        "#949494",       -- black   (g_5)
        a.accent_bright, -- red     (red_glowing)
        a.glow,
        a.smolder,
        a.blue,
        "#a7a7a7",
        "#b4b4b4",
        "#e5e5e5",       -- white   (g_1)
    }
    return {
        pics = a.pics,
        bg_opacity = a.bg_opacity or 0.4,
        align = a.align,
        background = "#000000",
        -- tab bar / status colors (tabbar.lua)
        ui = {
            bg = "#121212",
            bg_active = "#222222",
            fg = "#d5d5d5",
            muted = "#737373",
            accent = a.accent,
            bright = a.accent_bright,
            glow = a.glow,
            shimmer = a.shimmer, -- { base, highlight }
        },
        colors = {
            foreground = "#ffffff",
            background = "#121212",

            cursor_fg = "#000000",
            cursor_bg = a.cursor,
            cursor_border = a.cursor,

            selection_fg = "#ffffff",
            selection_bg = a.selection,

            scrollbar_thumb = "#535353",
            split = a.split,

            ansi = ansi,
            brights = brights,

            tab_bar = {
                background = "#121212",
                active_tab = { bg_color = "#222222", fg_color = a.active_tab },
                inactive_tab = { bg_color = "#121212", fg_color = a.accent },
                inactive_tab_hover = { bg_color = "#222222", fg_color = a.accent },
                new_tab = { bg_color = "#121212", fg_color = a.accent },
                new_tab_hover = { bg_color = "#222222", fg_color = a.accent },
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
    -- chartreuse glow of his eyes (assets/demifiend-glass.png, assets/src/demifiend.py)
    ["demifiend"] = ashen_like({
        pics          = "demifiend-glass", -- or "demifiend": not blurred (kazrc: themes.pictures)
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
    }),
    -- Atomic Heart (the Twins): Soviet red, gold, chrome over violet-black
    -- (assets/atomic-heart-glass.png, assets/src/atomic_heart.py)
    ["atomic-heart"] = ashen_like({
        pics          = "atomic-heart-glass", -- or "atomic-heart": not blurred (kazrc: themes.pictures)
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
    }),
    -- The Illusive Man before his star (Mass Effect 2): Paragon blue, ice,
    -- the ember of his cigarette (assets/illusive-man-glass.png,
    -- assets/src/illusive_man.py)
    ["illusive-man"] = ashen_like({
        pics          = "illusive-man-glass", -- or "illusive-man": not blurred (kazrc: themes.pictures)
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

-- background pictures of a theme: the setting, else the theme's own glob
function M.pictures(theme_name)
    return settings.pictures[theme_name] or M.get(theme_name).pics
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
