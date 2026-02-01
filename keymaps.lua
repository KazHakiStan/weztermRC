local wezterm = require("wezterm")
local constants = require("constants")
local themes = require("themes")

local state_store = require("state")

local M = {}

local function ensure_state()
    wezterm.GLOBAL.theme_state = wezterm.GLOBAL.theme_state or {
        theme = "dark",
        idx = { dark = 1, light = 1 },
        pics = {
            dark = constants.list_theme_pics("dark"),
            light = constants.list_theme_pics("light"),
        },
    }
    return wezterm.GLOBAL.theme_state
end

local function clamp_idx(idx, count)
    if count <= 0 then return 1 end
    if idx < 1 then return count end
    if idx > count then return 1 end
    return idx
end

local function get_current_bg(state)
    local theme = state.theme
    local pics = state.pics[theme] or {}
    if #pics == 0 then
        return ""
    end
    local i = clamp_idx(state.idx[theme] or 1, #pics)
    state.idx[theme] = i
    return pics[i]
end

local function apply_current(window)
    local state = ensure_state()
    local bg = get_current_bg(state)
    local overrides = themes.build_overrides(state.theme, bg)
    window:set_config_overrides(overrides)
end

local function toggle_theme(window)
    local state = ensure_state()
    state.theme = (state.theme == "dark") and "light" or "dark"
    state_store.save({ theme = state.theme, idx = state.idx })
    apply_current(window)
end

local function cycle_pic(window, delta)
    local state = ensure_state()
    local theme = state.theme
    local pics = state.pics[theme] or {}
    if #pics == 0 then
        apply_current(window)
        return
    end

    local new_idx = (state.idx[theme] or 1) + delta
    state.idx[theme] = clamp_idx(new_idx, #pics)
    state_store.save({ theme = state.theme, idx = state.idx })
    apply_current(window)
end

function M.keys()
    return {
        -- toggle theme
        {
            mods = "LEADER",
            key = "t",
            action = wezterm.action_callback(function(window, _pane)
                toggle_theme(window)
            end),
        },

        -- next/prev pic in current theme
        {
            mods = "LEADER",
            key = "]",
            action = wezterm.action_callback(function(window, _pane)
                cycle_pic(window, 1)
            end),
        },
        {
            mods = "LEADER",
            key = "[",
            action = wezterm.action_callback(function(window, _pane)
                cycle_pic(window, 1)
            end),
        }
    }
end

function M.remaps()
    return {
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
end

return M
