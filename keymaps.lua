local wezterm = require("wezterm")

local state_store = require("state")
local pinned = require("pinned")

local M = {}

-- Key specs: { mods, key, action, desc, section? }
-- `desc` puts the binding into the cheat sheet (help.lua, LEADER i).

-- state lives in files; the config is rebuilt from them on reload
-- (nvim writes the same theme file, which also triggers a reload)

-- every theme in a fuzzy list: "* demifiend (mint)  · blur", like nvim's :T
local function choose_theme(window, pane)
    local themes = require("themes")
    local aliases = require("kazrc").themes().aliases
    local s = state_store.current()
    local choices = {}
    for _, n in ipairs(themes.order) do
        local glass = state_store.glass_on(s, n)
        choices[#choices + 1] = {
            id = n,
            label = (n == s.theme and "* " or "  ") .. n .. (aliases[n] and (" (" .. aliases[n] .. ")") or "")
                .. (glass == nil and "" or (glass and "  · blur" or "  · blur off")),
        }
    end
    window:perform_action(wezterm.action.InputSelector({
        title = "Theme",
        fuzzy = true,
        fuzzy_description = "Theme (type a name or colour, Enter = set, Esc = close): ",
        choices = choices,
        action = wezterm.action_callback(function(_win, _p, id)
            if id then
                state_store.set_theme(id)
                wezterm.reload_configuration()
            end
        end),
    }), pane)
end

-- through the themes of the current colour group (blue: illusive-man, smtvv-taito)
local function cycle_group(window, delta)
    if state_store.cycle_group(delta) then
        wezterm.reload_configuration()
    else
        local _, alias, current = state_store.group()
        window:toast_notification("WezTerm", alias and ("no other " .. alias .. " theme")
            or (current .. " has no colour group"), nil, 3000)
    end
end

local function toggle_glass(window)
    if state_store.toggle_glass() then
        wezterm.reload_configuration()
    else
        window:toast_notification("WezTerm", "this theme has no blurred picture", nil, 3000)
    end
end

-- nvim through your login shell, so its PATH (Homebrew, Scoop) is there
function M.editor_argv(file)
    if wezterm.target_triple:find("windows") then
        return { "pwsh.exe", "-NoLogo", "-Command", "nvim", file }
    end
    return { os.getenv("SHELL") or "/bin/zsh", "-lc", 'exec nvim "$1"', "nvim", file }
end

function M.keys()
    return {
        {
            mods = "LEADER",
            key = "t",
            desc = "Choose a theme (type a name or colour), synced with nvim",
            action = wezterm.action_callback(choose_theme),
        },
        {
            mods = "LEADER",
            key = "g",
            desc = "Blur the background picture on/off (themes that have one), synced with nvim",
            action = wezterm.action_callback(function(window, _pane)
                toggle_glass(window)
            end),
        },
        {
            mods = "LEADER",
            key = "]",
            desc = "Next theme of the same colour (blue: illusive-man → smtvv-taito)",
            action = wezterm.action_callback(function(window, _pane) cycle_group(window, 1) end),
        },
        {
            mods = "LEADER",
            key = "[",
            desc = "Previous theme of the same colour",
            action = wezterm.action_callback(function(window, _pane) cycle_group(window, -1) end),
        },
    }
end

-- Ctrl-h/j/k/l: one set of keys for nvim splits and WezTerm panes. nvim
-- tells WezTerm it is running (user var IS_NVIM, neovimRC) and gets the key,
-- moving to the pane beyond itself at its edge; a shell pane gets it too when
-- there is no pane that way (Ctrl-l still clears, Ctrl-k still kills)
local function navigate(key, dir)
    local act = wezterm.action
    return wezterm.action_callback(function(window, pane)
        local tab = pane:tab()
        if pane:get_user_vars().IS_NVIM == "true" or not (tab and tab:get_pane_direction(dir)) then
            window:perform_action(act.SendKey({ key = key, mods = "CTRL" }), pane)
        else
            window:perform_action(act.ActivatePaneDirection(dir), pane)
        end
    end)
end

function M.remaps()
    local act = wezterm.action
    return {
        { mods = "LEADER", key = "c", section = "Tabs", desc = "New tab",
          action = act.SpawnTab("CurrentPaneDomain") },
        -- through pinned.lua: switching and moving skip the pinned tab
        { mods = "LEADER", key = "b", section = "Tabs", desc = "Previous tab",
          action = pinned.relative(-1) },
        { mods = "LEADER", key = "n", section = "Tabs", desc = "Next tab",
          action = pinned.relative(1) },
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
        { mods = "LEADER", key = "LeftArrow", section = "Panes", desc = "Resize: move edge left",
          action = act.AdjustPaneSize({ "Left", 2 }) },
        { mods = "LEADER", key = "RightArrow", section = "Panes", desc = "Resize: move edge right",
          action = act.AdjustPaneSize({ "Right", 2 }) },
        { mods = "LEADER", key = "DownArrow", section = "Panes", desc = "Resize: move edge down",
          action = act.AdjustPaneSize({ "Down", 2 }) },
        { mods = "LEADER", key = "UpArrow", section = "Panes", desc = "Resize: move edge up",
          action = act.AdjustPaneSize({ "Up", 2 }) },
        { mods = "CTRL", key = "h", section = "Panes", desc = "Left: nvim split or pane, one set of keys",
          action = navigate("h", "Left") },
        { mods = "CTRL", key = "j", section = "Panes", desc = "Down: nvim split or pane",
          action = navigate("j", "Down") },
        { mods = "CTRL", key = "k", section = "Panes", desc = "Up: nvim split or pane",
          action = navigate("k", "Up") },
        { mods = "CTRL", key = "l", section = "Panes", desc = "Right: nvim split or pane",
          action = navigate("l", "Right") },
    }
end

-- modes entered from a LEADER binding (shown on the bar while active)
function M.key_tables()
    local act = wezterm.action
    local move = {
        { key = "b", action = pinned.move_relative(-1) },
        { key = "n", action = pinned.move_relative(1) },
        { key = "Escape", action = "PopKeyTable" },
        { key = "Enter", action = "PopKeyTable" },
    }
    for i = 0, 9 do
        table.insert(move, { key = tostring(i), action = pinned.move_to(i) })
    end
    return require("extensions").key_tables({ move_tab = move })
end

return M
