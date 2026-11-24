local wezterm = require("wezterm")
local constants = require("constants")

local M = {}

-- local (per-machine) state: picture index per theme
local state_path = constants.join(wezterm.config_dir, "state.json")
-- shared with nvim: current theme name, and blur switched per theme
M.theme_file = constants.paths.theme_file

-- old theme names -> current ones (state files written by earlier versions)
local legacy = { dark = "ashen", light = "metaphor-light" }

local function read_json(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()

    local ok, data = pcall(wezterm.json_parse, content)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

local function write_json(path, data)
    local f = io.open(path, "w")
    if not f then
        wezterm.log_error("Failed to write " .. path)
        return
    end
    f:write(wezterm.json_encode(data))
    f:close()
end

function M.load()
    local data = read_json(state_path) or {}
    local idx = {}
    for k, v in pairs(data.idx or {}) do
        idx[legacy[k] or k] = v
    end
    local shared = read_json(M.theme_file)
    if not shared then
        -- moved into ~/.config/kazrc: carry the old file over once
        shared = read_json(constants.paths.legacy_theme_file)
        if shared and require("kazrc").ensure_dir() then write_json(M.theme_file, shared) end
    end
    shared = shared or {}
    local theme = shared.theme or data.theme
    return {
        theme = legacy[theme] or theme,
        glass = type(shared.glass) == "table" and shared.glass or {},
        idx = idx,
        animate = data.animate ~= false, -- on by default
        activity = data.activity or "full",
    }
end

function M.save(state)
    write_json(state_path, { idx = state.idx, animate = state.animate, activity = state.activity })
    -- keep what nvim keeps there too (clean = its clean mode)
    local shared = read_json(M.theme_file) or {}
    shared.theme, shared.glass = state.theme, state.glass
    write_json(M.theme_file, shared)
end

function M.toggle_animate()
    local s = M.load()
    s.animate = not s.animate
    M.save(s)
end

-- activity element: full (word + session time) -> compact (word) -> off
M.ACTIVITY_MODES = { "full", "compact", "off" }

function M.cycle_activity()
    local s = M.load()
    local pos = 1
    for i, m in ipairs(M.ACTIVITY_MODES) do
        if m == s.activity then pos = i end
    end
    s.activity = M.ACTIVITY_MODES[pos % #M.ACTIVITY_MODES + 1]
    M.save(s)
end

local function wrap(i, count)
    if count <= 0 then return 1 end
    return (i - 1) % count + 1
end

-- blur for a theme: nil if it has no blurred picture (themes.lua glass),
-- else what was switched (theme.json) or its default
function M.glass_on(s, theme)
    local default = require("kazrc").themes().glass[theme]
    if default == nil then return nil end
    if s.glass[theme] ~= nil then return s.glass[theme] end
    return default
end

-- resolved view: valid theme name, its pictures and the selected one
function M.current()
    local themes = require("themes")
    local s = M.load()
    if not themes.themes[s.theme] then
        s.theme = themes.default
    end
    local pics = constants.list_pics(themes.pictures(s.theme, M.glass_on(s, s.theme)))
    local i = wrap(s.idx[s.theme] or 1, #pics)
    s.idx[s.theme] = i
    s.pics = pics
    s.bg = pics[i] or ""
    return s
end

function M.set_theme(name)
    local s = M.current()
    s.theme = name
    M.save(s)
end

-- the themes that share the current theme's alias (kazrc themes.lua aliases),
-- in theme order: { names }, alias
function M.group()
    local themes = require("themes")
    local s = M.current()
    local alias = require("kazrc").themes().aliases[s.theme]
    local names = {}
    for _, n in ipairs(themes.order) do
        if alias and require("kazrc").themes().aliases[n] == alias then names[#names + 1] = n end
    end
    return names, alias, s.theme
end

-- next / previous theme of the current theme's group; false if it is alone
function M.cycle_group(delta)
    local names, _, current = M.group()
    if #names < 2 then return false end
    local pos = 1
    for i, n in ipairs(names) do
        if n == current then pos = i end
    end
    M.set_theme(names[wrap(pos + delta, #names)])
    return true
end

-- blur on/off for the current theme; false when it has no blurred picture
function M.toggle_glass()
    local s = M.current()
    local on = M.glass_on(s, s.theme)
    if on == nil then return false end
    s.glass[s.theme] = not on
    M.save(s)
    return true
end


return M
