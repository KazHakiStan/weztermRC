local wezterm = require("wezterm")
local constants = require("constants")
local config = wezterm.config_builder()

config.default_prog = constants.default_prog

config.leader = {
	key = "q",
	mods = "CTRL",
	timeout_milliseconds = 2000,
}

--- font
config.font_size = 12
config.font = wezterm.font("JetBrains Mono")
config.line_height = 1.2

--- colors
config.colors = {
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
}

--- appearance
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true
config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "ALT",
		action = "StartWindowDrag",
		mouse_reporting = true,
	},
}
config.keys = {
    {
        mods = "LEADER",
        key = "c",
        action = wezterm.action.SpawnTab "CurrentPaneDomain",
    },
    {
        mods = "LEADER",
        key = "x",
        action = wezterm.action.CloseCurrentPane { confirm = true },
    },
    {
        mods = "LEADER",
        key = "b",
        action = wezterm.action.ActivateTabRelative(-1),
    },
    {
        mods = "LEADER",
        key = "n",
        action = wezterm.action.ActivateTabRelative(1),
    },
    {
        mods = "LEADER",
        key = "/",
        action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" },
    },
    {
        mods = "LEADER",
        key = "-",
        action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" },
    },
    {
        mods = "LEADER",
        key = "h",
        action = wezterm.action.ActivatePaneDirection "Left",
    },
    {
        mods = "LEADER",
        key = "j",
        action = wezterm.action.ActivatePaneDirection "Down",
    },
    {
        mods = "LEADER",
        key = "k",
        action = wezterm.action.ActivatePaneDirection "Up",
    },
    {
        mods = "LEADER",
        key = "l",
        action = wezterm.action.ActivatePaneDirection "Right",
    },
    {
        mods = "LEADER",
        key = "LeftArrow",
        action = wezterm.action.AdjustPaneSize { "Left", 2 },
    },
    {
        mods = "LEADER",
        key = "RightArrow",
        action = wezterm.action.AdjustPaneSize { "Right", 2 },
    },
    {
        mods = "LEADER",
        key = "DownArrow",
        action = wezterm.action.AdjustPaneSize { "Down", 2 },
    },
    {
        mods = "LEADER",
        key = "UpArrow",
        action = wezterm.action.AdjustPaneSize { "Up", 2 },
    },
}
config.background = {
    {
        source = {
            Color = '#000000',
        },
        opacity = 1,
        height = '100%',
        width = '100%',
    },
    {
        source = {
            File = constants.paths.bg_image,
        },
        opacity = 0.4,
    },
}

for i = 0, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = wezterm.action.ActivateTab(i),
    })
end

return config
