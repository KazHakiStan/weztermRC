local wezterm = require("wezterm")
local config = wezterm.config_builder()

local constants = require("constants")
local themes = require("themes")
local keymaps = require("keymaps")

local state_store = require("state")

config.default_prog = constants.default_prog

-- leader
config.leader = {
    key = "q",
    mods = "CTRL",
    timeout_milliseconds = 2000,
}

-- font
config.font_size = 12
config.font = wezterm.font("JetBrains Mono")
config.line_height = 1.2

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

config.keys = keymaps.remaps()

for i = 0, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = wezterm.action.ActivateTab(i),
    })
end

for _, k in ipairs(keymaps.keys()) do
    table.insert(config.keys, k)
end

local function ensure_state()
    if wezterm.GLOBAL.theme_state then
        return wezterm.GLOBAL.theme_state
    end

    local persisted = state_store.load() or {}

    wezterm.GLOBAL.theme_state = {
        theme = persisted.theme or "dark",
        idx = persisted.idx or { dark = 1, light = 1 },
        pics = {
            dark = constants.list_theme_pics("dark"),
            light = constants.list_theme_pics("light"),
        },
    }
    return wezterm.GLOBAL.theme_state
end

local function current_bg_for_state(state)
    local pics = state.pics[state.theme] or {}
    local i = state.idx[state.theme] or 1
    return pics[i] or ""
end

local function apply_overrides(window)
    local state = ensure_state()
    local bg = current_bg_for_state(state)
    local overrides = themes.build_overrides(state.theme, bg)
    window:set_config_overrides(overrides)
end

wezterm.on("gui-startup", function(cmd)
    local _tab, _pane, window = wezterm.mux.spawn_window(cmd or {})
    apply_overrides(window)
end)

wezterm.on("window-created", function(window, _pane)
    apply_overrides(window)
end)

do
    local state = ensure_state()
    local bg = current_bg_for_state(state)
    local base = themes.build_overrides(state.theme, bg)

    config.colors = base.colors
    config.background = base.background
end

return config
