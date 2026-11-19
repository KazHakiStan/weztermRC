local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- settings: defaults.lua + ~/.config/kazrc/wezterm.lua (LEADER e). Loaded
-- first, here and not inside another module's require: creating the file on
-- first start uses wezterm's async file functions, which can't run in require.
local kazrc = require("kazrc")
local settings = kazrc.get()

local constants = require("constants")
local themes = require("themes")
local keymaps = require("keymaps")

local state_store = require("state")

config.default_prog = constants.default_prog
config.exit_behavior = "Close"
config.enable_kitty_graphics = true

-- leader
config.leader = {
    key = settings.leader.key,
    mods = settings.leader.mods,
    timeout_milliseconds = settings.leader.timeout_ms,
}

-- font
config.font_size = settings.font.size
-- KazGlyphs (fonts/, built by fonts/src/build_glyphs.py): custom status glyphs
config.font_dirs = { constants.join(wezterm.config_dir, "fonts") }
config.font = wezterm.font_with_fallback({ settings.font.family, "JetBrains Mono", "KazGlyphs" })
config.line_height = settings.font.line_height

--- appearance
config.window_decorations = settings.window.decorations
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = settings.window.tab_bar_at_bottom
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

-- every binding goes through help.add, so its `desc` lands in the cheat sheet
local help = require("help")
config.keys = {}
local function bind(section, specs)
    for _, k in ipairs(help.add(section, specs)) do
        table.insert(config.keys, k)
    end
end

bind("Tabs", keymaps.remaps())

for i = 0, 9 do
    bind("Tabs", { {
        key = tostring(i),
        mods = "LEADER",
        action = wezterm.action.ActivateTab(i),
    } })
end
help.note("Tabs", "LEADER 0-9", "Go to tab N")

bind("Theme", keymaps.keys())
bind("Settings", { {
    mods = "LEADER",
    key = "e",
    desc = "Edit your settings (~/.config/kazrc/wezterm.lua) in nvim; saving applies them",
    action = wezterm.action.SpawnCommandInNewTab({ args = keymaps.editor_argv(kazrc.file) }),
} })
config.key_tables = keymaps.key_tables()

-- theme: rebuilt from state files on every config load.
-- The shared theme file is watched, so `:Theme x` in nvim re-themes wezterm.
do
    local state = state_store.current()
    local t = themes.build(state.theme, state.bg)
    config.colors = t.colors
    config.background = t.background
    wezterm.add_to_config_reload_watch_list(state_store.theme_file)

    -- bottom bar: tab names, activity line, cwd + clock
    local tabbar = require("tabbar")
    tabbar.apply(config, themes.get(state.theme), state)
    bind("Bar", tabbar.keys())
end

-- cheat sheet: LEADER i, plus entries in the command palette (Ctrl+Shift+P)
bind("Help", help.keys())
help.apply()

return config
