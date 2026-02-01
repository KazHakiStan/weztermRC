local M = {}

M.themes = {
    dark = {
        colors = {
            foreground = "#ffffff",
            background = "#121212",

            cursor_fg = "#000000",
            cursor_bg = "#aaaaaa",
            cursor_border = "#aaaaaa",

            selection_fg = "#000000",
            selection_bg = "#aaaaaa",

            scrollbar_thumb = "#ffffff",

            split = "#ffffff",

            ansi = {
                "#928374",  -- black
                "#b14242",  -- red
                "#b8bb26",  -- green
                "#fabd2f",  -- yellow
                "#83a598",  -- blue
                "#d3869b",  -- magenta
                "#8ec07c",  -- cyan
                "#ffffff"   -- white
            },

            brights = {
                "#928374",  -- black
                "#b14242",  -- red
                "#b8bb26",  -- green
                "#fabd2f",  -- yellow
                "#83a598",  -- blue
                "#d3869b",  -- magenta
                "#8ec07c",  -- cyan
                "#ffffff"   -- white
            },

            -- Optional: Tab bar colors
            tab_bar = {
                background = "#121212",
                active_tab = {
                    bg_color = "#222222",
                    fg_color = "#aaaaaa",
                },
                inactive_tab = {
                    bg_color = "#121212",
                    fg_color = "#b14242",
                },
                inactive_tab_hover = {
                    bg_color = "#222222",
                    fg_color = "#b14242",
                },
                new_tab = {
                    bg_color = "#121212",
                    fg_color = "#b14242",
                },
                new_tab_hover = {
                    bg_color = "#222222",
                    fg_color = "#b14242",
                },
            },
        },
        bg_opacity = 0.4,
        background = "#000000",
    },
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
    },
}

function M.build_overrides(theme_name, bg_file)
    local t = M.themes[theme_name] or M.themes.dark
    return {
        colors = t.colors,
        background = {
            {
                source = { Color = t.background },
                opacity = 1,
                height = "100%",
                width = "100%",
            },
            {
                source = { File = bg_file },
                opacity = t.bg_opacity or 0.4,
            },
        },
    }
end

return M
