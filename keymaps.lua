local wezterm = require("wezterm")

local state_store = require("state")

local M = {}

-- Key specs: { mods, key, action, desc, section? }
-- `desc` puts the binding into the cheat sheet (help.lua, LEADER i).

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
        {
            mods = "LEADER",
            key = "t",
            desc = "Cycle theme (ashen → aegis-lavender → light), synced with nvim",
            action = wezterm.action_callback(function(window, _pane)
                toggle_theme(window)
            end),
        },
        {
            mods = "LEADER",
            key = "]",
            desc = "Next background picture",
            action = wezterm.action_callback(function(window, _pane)
                cycle_pic(window, 1)
            end),
        },
        {
            mods = "LEADER",
            key = "[",
            desc = "Previous background picture",
            action = wezterm.action_callback(function(window, _pane)
                cycle_pic(window, -1)
            end),
        },
    }
end

function M.remaps()
    local act = wezterm.action
    return {
        { mods = "LEADER", key = "c", section = "Tabs", desc = "New tab",
          action = act.SpawnTab("CurrentPaneDomain") },
        { mods = "LEADER", key = "b", section = "Tabs", desc = "Previous tab",
          action = act.ActivateTabRelative(-1) },
        { mods = "LEADER", key = "n", section = "Tabs", desc = "Next tab",
          action = act.ActivateTabRelative(1) },
        { mods = "LEADER", key = "m", section = "Tabs",
          desc = "Move mode: b / n move tab, 0-9 put it at N, Esc / Enter / any other key exits",
          action = act.ActivateKeyTable({
              name = "move_tab",
              one_shot = false,     -- stay in the mode for repeated moves
              until_unknown = true, -- any unmapped key leaves it
          }) },

        { mods = "LEADER", key = "x", section = "Panes", desc = "Close pane",
          action = act.CloseCurrentPane({ confirm = true }) },
        { mods = "LEADER", key = "/", section = "Panes", desc = "Split right",
          action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
        { mods = "LEADER", key = "-", section = "Panes", desc = "Split down",
          action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
        { mods = "LEADER", key = "h", section = "Panes", desc = "Focus left",
          action = act.ActivatePaneDirection("Left") },
        { mods = "LEADER", key = "j", section = "Panes", desc = "Focus down",
          action = act.ActivatePaneDirection("Down") },
        { mods = "LEADER", key = "k", section = "Panes", desc = "Focus up",
          action = act.ActivatePaneDirection("Up") },
        { mods = "LEADER", key = "l", section = "Panes", desc = "Focus right",
          action = act.ActivatePaneDirection("Right") },
        { mods = "LEADER", key = "LeftArrow", section = "Panes", desc = "Resize: move edge left",
          action = act.AdjustPaneSize({ "Left", 2 }) },
        { mods = "LEADER", key = "RightArrow", section = "Panes", desc = "Resize: move edge right",
          action = act.AdjustPaneSize({ "Right", 2 }) },
        { mods = "LEADER", key = "DownArrow", section = "Panes", desc = "Resize: move edge down",
          action = act.AdjustPaneSize({ "Down", 2 }) },
        { mods = "LEADER", key = "UpArrow", section = "Panes", desc = "Resize: move edge up",
          action = act.AdjustPaneSize({ "Up", 2 }) },
    }
end

-- modes entered from a LEADER binding (shown on the bar while active)
function M.key_tables()
    local act = wezterm.action
    local move = {
        { key = "b", action = act.MoveTabRelative(-1) },
        { key = "n", action = act.MoveTabRelative(1) },
        { key = "Escape", action = "PopKeyTable" },
        { key = "Enter", action = "PopKeyTable" },
    }
    for i = 0, 9 do
        table.insert(move, { key = tostring(i), action = act.MoveTab(i) })
    end
    return { move_tab = move }
end

return M
