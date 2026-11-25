-- Extensions: Lua files of your own that add keys, modes and bar items,
-- listed in ~/.config/kazrc/wezterm.lua:
--   extensions = { "~/.config/kazrc/music.lua" },
-- Each file returns a table; every field is optional:
--   section     cheat sheet section of its keys (default: the file name)
--   keys        function(ctx) -> key specs like keymaps.lua's
--               ({ mods, key, action, desc }; `desc` puts one in the cheat sheet)
--   key_tables  function(ctx) -> { name = { key assignments } }
--   modes       { name = "badge" }: on the bar while key table `name` is active
--   status      function(window, pane, ctx) -> FormatItems, drawn on the right
--               of the bar before the directory; nil or {} draws nothing
-- ctx: { wezterm, nf = function(nerd font name) -> glyph, ui = theme colours
-- (bg, bg_active, fg, muted, bright, accent, glow) }.
-- A file that fails to load or to run is reported on the bar and skipped.

local wezterm = require("wezterm")
local kazrc = require("kazrc")

local M = {}

local ctx = {
    wezterm = wezterm,
    nf = function(name)
        local ok, glyph = pcall(function() return wezterm.nerdfonts[name] end)
        return ok and glyph or ""
    end,
    ui = {},
}

local list
local failed = {} -- extension name -> already reported a runtime error

local function name_of(path)
    return (path:match("([^/\\]+)$") or path):gsub("%.lua$", "")
end

local function load()
    if list then return list end
    list = {}
    for _, path in ipairs(kazrc.get().extensions) do
        local file = kazrc.expand(path)
        local name = name_of(file)
        pcall(wezterm.add_to_config_reload_watch_list, file)
        local ok, ext = pcall(dofile, file)
        if not ok then
            kazrc.add_problem(name .. ": " .. tostring(ext):gsub("^.-([^/\\]+%.lua:)", "%1"))
        elseif type(ext) ~= "table" then
            kazrc.add_problem(name .. ": should `return { ... }`")
        else
            ext.name = name
            list[#list + 1] = ext
        end
    end
    return list
end

-- calls ext[field](...) if it is there; an error is reported once, then the
-- field stays quiet
local function call(ext, field, ...)
    local f = ext[field]
    if type(f) ~= "function" or failed[ext.name .. "." .. field] then return nil end
    local ok, res = pcall(f, ...)
    if ok then return res end
    failed[ext.name .. "." .. field] = true
    kazrc.add_problem(ext.name .. "." .. field .. ": " .. tostring(res):gsub("^.-([^/\\]+%.lua:)", "%1"))
    return nil
end

function M.set_ui(ui)
    ctx.ui = ui
end

-- { section, specs } per extension, for help.add
function M.keys()
    local out = {}
    for _, ext in ipairs(load()) do
        local specs = call(ext, "keys", ctx)
        if type(specs) == "table" then
            out[#out + 1] = { section = ext.section or ext.name, specs = specs }
        end
    end
    return out
end

-- merges the extensions' key tables into `tables`
function M.key_tables(tables)
    for _, ext in ipairs(load()) do
        local t = call(ext, "key_tables", ctx)
        if type(t) == "table" then
            for name, keys in pairs(t) do tables[name] = keys end
        end
    end
    return tables
end

-- badge for the active key table, if an extension owns it
function M.mode(name)
    if not name then return nil end
    for _, ext in ipairs(load()) do
        local badge = type(ext.modes) == "table" and ext.modes[name]
        if badge then return badge end
    end
    return nil
end

-- FormatItems from every extension's status
function M.status(window, pane)
    local out = {}
    for _, ext in ipairs(load()) do
        local items = call(ext, "status", window, pane, ctx)
        if type(items) == "table" then
            for _, it in ipairs(items) do out[#out + 1] = it end
        end
    end
    return out
end

return M
