local wezterm = require("wezterm")

local state_store = require("state")

local M = {}

-- state lives in files; the config is rebuilt from them on reload
-- (nvim writes the same theme file, which also triggers a reload)
local function toggle_theme(_window)
    state_store.cycle_theme(1)
    wezterm.reload_configuration()
end

local function cycle_pic(_window, delta)
    state_store.cycle_pic(delta)
    wezterm.reload_configuration()
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
                cycle_pic(window, -1)
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
