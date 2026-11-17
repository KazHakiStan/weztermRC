local wezterm = require("wezterm")
local constants = require("constants")

local M = {}

-- local (per-machine) state: picture index per theme
local state_path = constants.join(wezterm.config_dir, "state.json")
-- shared with nvim: current theme name
M.theme_file = constants.paths.theme_file

-- names used before the shared theme file existed
local legacy = { dark = "ashen" }

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
    local shared = read_json(M.theme_file) or {}
    local theme = shared.theme or data.theme
    return { theme = legacy[theme] or theme, idx = idx }
end

function M.save(state)
    write_json(state_path, { idx = state.idx })
    write_json(M.theme_file, { theme = state.theme })
end

local function wrap(i, count)
    if count <= 0 then return 1 end
    return (i - 1) % count + 1
end

-- resolved view: valid theme name, its pictures and the selected one
function M.current()
    local themes = require("themes")
    local s = M.load()
    if not themes.themes[s.theme] then
        s.theme = themes.default
    end
    local pics = constants.list_pics(themes.get(s.theme).pics)
    local i = wrap(s.idx[s.theme] or 1, #pics)
    s.idx[s.theme] = i
    s.pics = pics
    s.bg = pics[i] or ""
    return s
end

function M.cycle_theme(delta)
    local themes = require("themes")
    local s = M.current()
    local pos = 1
    for i, name in ipairs(themes.order) do
        if name == s.theme then pos = i end
    end
    s.theme = themes.order[wrap(pos + delta, #themes.order)]
    M.save(s)
end

function M.cycle_pic(delta)
    local s = M.current()
    if #s.pics == 0 then return end
    s.idx[s.theme] = wrap(s.idx[s.theme] + delta, #s.pics)
    M.save(s)
end

return M
