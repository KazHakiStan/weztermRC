local M = {}

-- order for LEADER t; names must match nvim's lua/kazhakistan/theme.lua
M.order = { "ashen", "aegis-lavender", "light" }
M.default = "ashen"

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
        bg_opacity = 0.4,
        background = "#000000",
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
    -- ashen.nvim default palette (red)
    ["ashen"] = ashen_like({
        pics          = "picD*",
        accent        = "#b14242", -- red_ember
        accent_bright = "#df6464", -- red_glowing
        glow          = "#d87c4a", -- orange_glow
        smolder       = "#e49a44", -- orange_smolder
        blue          = "#4a8b8b",
        cursor        = "#aaaaaa",
        selection     = "#6f2929", -- red_ashen
        split         = "#6f2929",
        active_tab    = "#aaaaaa",
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
    }),
    dark2 = {
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
    light = {
        colors = {
            foreground = "#3c3836",
            background = "#fbf1c7",

            cursor_bg = "#3c3836",
            cursor_fg = "#fbf1c7",
            cursor_border = "#3c3836",

            selection_fg = "#fbf1c7",
            selection_bg = "#b57614",

            scrollbar_thumb = "#bdae93",

            split = "#bdae93",

            ansi = {
                "#fbf1c7",
                "#cc241d",
                "#98971a",
                "#d79921",
                "#458588",
                "#b16286",
                "#689d6a",
                "#7c6f64"
            },

            brights = {
                "#928374",
                "#9d0006",
                "#79740e",
                "#b57614",
                "#076678",
                "#8f3f71",
                "#427b58",
                "#3c3836"
            },

            -- Optional: Tab bar colors
            tab_bar = {
                background = "#fbf1c7",
                active_tab = {
                    bg_color = "#ebdbb2",
                    fg_color = "#3c3836",
                },
                inactive_tab = {
                    bg_color = "#f2e5bc",
                    fg_color = "#7c6f64",
                },
                inactive_tab_hover = {
                    bg_color = "#ebdbb2",
                    fg_color = "#3c3836",
                },
                new_tab = {
                    bg_color = "#fbf1c7",
                    fg_color = "#7c6f64",
                },
                new_tab_hover = {
                    bg_color = "#ebdbb2",
                    fg_color = "#3c3836",
                },
            },
        },
        bg_opacity = 0.2,
        background = "#FFFFFF",
        pics = "picL*",
    },
}

function M.get(theme_name)
    return M.themes[theme_name] or M.themes[M.default]
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
        -- Cover keeps aspect ratio; art sits on the right of every picture
        table.insert(layers, {
            source = { File = bg_file },
            opacity = t.bg_opacity or 0.4,
            width = "Cover",
            height = "Cover",
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
            horizontal_align = "Right",
            vertical_align = "Middle",
        })
    end
    return { colors = t.colors, background = layers }
end

return M
