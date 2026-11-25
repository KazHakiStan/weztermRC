-- Pinned tab: one tab kept out of the tab row and shown on the right of the
-- bar, next to the directory and clock (tabbar.lua draws it).
--   LEADER ;   go to the pinned tab, and back from it; pins this tab if none is
--   LEADER :   pin this tab / unpin it
-- Tab switching skips it (Ctrl+Tab, Cmd+Shift+[ ], LEADER n / b / 0-9, move
-- mode), and tab numbers on the bar count only the other tabs.
-- Which tab is pinned lives in wezterm.GLOBAL: it survives config reloads,
-- not a WezTerm restart.

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local G = wezterm.GLOBAL

local function get_tab(id)
    if not id then return nil end
    local ok, tab = pcall(wezterm.mux.get_tab, id)
    return ok and tab or nil
end

-- the pinned tab (MuxTab) or nil; forgets one that was closed
function M.tab()
    local tab = get_tab(G.pinned_tab)
    if not tab then G.pinned_tab = nil end
    return tab
end

function M.is_pinned(tab_id)
    return tab_id ~= nil and tab_id == G.pinned_tab
end

-- tab number shown on the bar: format-tab-title's tab and tabs, without the pinned one
function M.display_index(tab, tabs)
    local n = tab.tab_index
    for _, t in ipairs(tabs) do
        if t.tab_index < tab.tab_index and M.is_pinned(t.tab_id) then return n - 1 end
    end
    return n
end

-- the window's tabs, pinned one left out: { index, is_active, tab }
local function regular(window)
    local out = {}
    for _, info in ipairs(window:mux_window():tabs_with_info()) do
        if not M.is_pinned(info.tab:tab_id()) then out[#out + 1] = info end
    end
    return out
end

local function active_position(list)
    for i, info in ipairs(list) do
        if info.is_active then return i end
    end
    return nil
end

local function focus(tab)
    tab:activate()
    -- in another window: bring that window forward too
    pcall(function()
        local gui = tab:window():gui_window()
        if gui then gui:focus() end
    end)
end

-- the tab to come back to from the pinned one
local function back(window)
    local tab = get_tab(G.pinned_back)
    if tab and not M.is_pinned(tab:tab_id()) then return focus(tab) end
    local list = regular(window)
    if #list > 0 then list[1].tab:activate() end
end

---------------------------------------------------------------- switching

-- delta tabs to the right (negative: left), wrapping, past the pinned tab
function M.relative(delta)
    return wezterm.action_callback(function(window, _pane)
        local list = regular(window)
        if #list == 0 then return end
        local pos = active_position(list)
        if not pos then return back(window) end -- on the pinned tab
        list[(pos - 1 + delta) % #list + 1].tab:activate()
    end)
end

-- tab N as the bar numbers it
function M.activate(n)
    return wezterm.action_callback(function(window, _pane)
        local info = regular(window)[n + 1]
        if info then info.tab:activate() end
    end)
end

-- move mode: put this tab at N / delta places over, as the bar counts
function M.move_to(n)
    return wezterm.action_callback(function(window, pane)
        local list = regular(window)
        local target = list[math.min(n + 1, #list)]
        if target and active_position(list) then
            window:perform_action(act.MoveTab(target.index), pane)
        end
    end)
end

function M.move_relative(delta)
    return wezterm.action_callback(function(window, pane)
        local list = regular(window)
        local pos = active_position(list)
        if not pos or #list < 2 then return end
        local target = list[(pos - 1 + delta) % #list + 1]
        window:perform_action(act.MoveTab(target.index), pane)
    end)
end

---------------------------------------------------------------- pinning

local function pin(window)
    G.pinned_tab = window:active_tab():tab_id()
end

local function jump(window, _pane)
    local tab = M.tab()
    if not tab then return pin(window) end
    local active = window:active_tab()
    if active:tab_id() == tab:tab_id() then return back(window) end
    G.pinned_back = active:tab_id()
    focus(tab)
end

local function toggle(window, _pane)
    if M.is_pinned(window:active_tab():tab_id()) then
        G.pinned_tab = nil
    else
        pin(window)
    end
end

function M.keys()
    return {
        { mods = "LEADER", key = ";", section = "Tabs",
          desc = "Pinned tab and back (pins this tab if none is pinned)",
          action = wezterm.action_callback(jump) },
        { mods = "LEADER|SHIFT", key = ";", label = "LEADER :", section = "Tabs",
          desc = "Pin this tab / unpin it (one pinned tab, shown on the right of the bar)",
          action = wezterm.action_callback(toggle) },
        -- WezTerm's own tab switching keys, past the pinned tab
        { mods = "CTRL", key = "Tab", action = M.relative(1) },
        { mods = "CTRL|SHIFT", key = "Tab", action = M.relative(-1) },
        { mods = "SUPER|SHIFT", key = "]", action = M.relative(1) },
        { mods = "SUPER|SHIFT", key = "[", action = M.relative(-1) },
    }
end

return M
