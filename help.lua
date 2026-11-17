-- Cheat sheet built from the key bindings themselves.
--   LEADER i                 searchable list (type to filter); Enter runs the entry
--   Ctrl+Shift+P (palette)   the same entries appear as palette commands
--
-- Give a key spec a `desc` (and optionally `section`, `label`) and it shows up
-- here automatically; `help.add` strips those fields before wezterm sees them.

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local entries = {}
local KEY_NAMES = {
    LeftArrow = "←", RightArrow = "→", UpArrow = "↑", DownArrow = "↓",
}

local function key_label(spec)
    if spec.label then return spec.label end
    local key = KEY_NAMES[spec.key] or spec.key
    if spec.mods and spec.mods ~= "" and spec.mods ~= "NONE" then
        return spec.mods:gsub("|", "+") .. " " .. key
    end
    return key
end

local function note(section, keys, desc, action, builtin)
    entries[#entries + 1] = {
        section = section, keys = keys, desc = desc, action = action, builtin = builtin,
    }
end

-- register specs; returns plain key assignments for config.keys
function M.add(section, specs)
    local keys = {}
    for _, s in ipairs(specs) do
        if s.desc then
            note(s.section or section, key_label(s), s.desc, s.action)
        end
        keys[#keys + 1] = { key = s.key, mods = s.mods, action = s.action }
    end
    return keys
end

-- an entry that is not a single binding (e.g. "LEADER 0-9")
function M.note(section, keys, desc, action)
    note(section, keys, desc, action)
end

-- wezterm defaults worth remembering (Ctrl+Shift variants work on mac and Windows)
local function builtins()
    local s = "WezTerm"
    note(s, "Ctrl+Shift P", "Command palette", act.ActivateCommandPalette, true)
    note(s, "Ctrl+Shift F", "Search scrollback", act.Search("CurrentSelectionOrEmptyString"), true)
    note(s, "Ctrl+Shift X", "Copy mode (vim-like selection)", act.ActivateCopyMode, true)
    note(s, "Ctrl+Shift Space", "Quick select (hashes, paths, urls)", act.QuickSelect, true)
    note(s, "Ctrl+Shift U", "Character / emoji picker", act.CharSelect, true)
    note(s, "Ctrl+Shift K", "Clear scrollback", act.ClearScrollback("ScrollbackOnly"), true)
    note(s, "Ctrl+Shift C / V", "Copy / paste", nil, true)
    note(s, "Ctrl + / - / 0", "Font size bigger / smaller / reset", nil, true)
    note(s, "Ctrl+Shift N", "New window", act.SpawnWindow, true)
    note(s, "Ctrl+Shift R", "Reload config", act.ReloadConfiguration, true)
    note(s, "Ctrl+Shift L", "Debug overlay (Lua REPL, logs)", act.ShowDebugOverlay, true)
    note(s, "Alt+Enter", "Toggle fullscreen", act.ToggleFullScreen, true)
    note(s, "Alt+drag", "Move window", nil, true)
end

local function choices()
    local width = 0
    for _, e in ipairs(entries) do
        width = math.max(width, wezterm.column_width(e.keys))
    end
    -- group by section (in order of first appearance), keep order inside a section
    local rank, order = {}, {}
    for i, e in ipairs(entries) do
        rank[e.section] = rank[e.section] or i
        order[i] = i
    end
    table.sort(order, function(a, b)
        local ra, rb = rank[entries[a].section], rank[entries[b].section]
        if ra ~= rb then return ra < rb end
        return a < b
    end)
    local out = {}
    for _, i in ipairs(order) do
        local e = entries[i]
        local pad = string.rep(" ", width - wezterm.column_width(e.keys) + 3)
        out[#out + 1] = {
            id = tostring(i),
            label = e.keys .. pad .. e.section .. ": " .. e.desc,
        }
    end
    return out
end

function M.keys()
    return {
        {
            mods = "LEADER",
            key = "i",
            desc = "This cheat sheet",
            section = "Help",
            action = wezterm.action_callback(function(window, pane)
                window:perform_action(act.InputSelector({
                    title = "Cheat sheet",
                    fuzzy = true, -- typing filters immediately
                    fuzzy_description = "Cheat sheet (type to search, Enter = run, Esc = close): ",
                    choices = choices(),
                    action = wezterm.action_callback(function(win, p, id, _label)
                        local e = id and entries[tonumber(id)]
                        if e and e.action then
                            win:perform_action(e.action, p)
                        end
                    end),
                }), pane)
            end),
        },
    }
end

-- call once after all bindings are registered
function M.apply()
    builtins()
    wezterm.on("augment-command-palette", function(_window, _pane)
        local items = {}
        for _, e in ipairs(entries) do
            -- builtins are already in the palette under their own names
            if e.action and not e.builtin then
                items[#items + 1] = {
                    brief = e.section .. ": " .. e.desc .. "  (" .. e.keys .. ")",
                    action = e.action,
                }
            end
        end
        return items
    end)
end

return M
