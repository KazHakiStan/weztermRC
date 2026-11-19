-- Settings = defaults.lua with ~/.config/kazrc/wezterm.lua merged on top.
-- The user file is created on first start (every default, commented out),
-- watched for changes, and never breaks the config: a file that fails to
-- load, or a value of the wrong type, is reported on the bar and skipped.

local wezterm = require("wezterm")

local M = {}

local function join(...)
    return (table.concat({ ... }, "/"):gsub("\\", "/"))
end

M.dir = join(wezterm.home_dir, ".config", "kazrc")
M.file = join(M.dir, "wezterm.lua")
M.defaults_file = join(wezterm.config_dir, "defaults.lua")
M.themes_file = join(M.dir, "themes.lua")

-- Shared with nvim through ~/.config/kazrc/themes.lua (neovimRC writes the
-- same template; keep these defaults in step with its kazrc.lua).
local THEME_DEFAULTS = {
    order = { "ashen", "aegis-lavender", "aegis-gold", "metaphor-light", "silent-hunter" },
    default = "ashen",
}
local THEMES_TEMPLATE = table.concat({
    "-- Themes shared by nvim and WezTerm (neovimRC + weztermRC). Below are the",
    "-- defaults, commented out: uncomment what you change. WezTerm applies it on",
    "-- save, nvim on the next start.",
    "return {",
    "--     -- LEADER t (WezTerm) and :Theme (nvim) cycle through these",
    '--     order = { "ashen", "aegis-lavender", "aegis-gold", "metaphor-light", "silent-hunter" },',
    "--     -- the theme before any is chosen",
    '--     default = "ashen",',
    "}",
    "",
}, "\n")

-- tables whose keys are yours to add (theme names, word groups)
local OPEN = { ["themes.pictures"] = true, ["status.groups"] = true }

local problems = {}
local function problem(msg)
    problems[#problems + 1] = msg
    wezterm.log_warn("kazrc: " .. msg)
end
M.add_problem = problem

local function is_list(t)
    return type(t) == "table" and (#t > 0 or next(t) == nil)
end

-- tables merge key by key, lists and plain values replace
local function merge(base, over, path)
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    for k, v in pairs(over) do
        local where = path == "" and tostring(k) or (path .. "." .. tostring(k))
        local d = base[k]
        local optional = OPEN[path] or where == "shell" -- shell defaults to nil
        if d == nil and not optional then
            problem("unknown setting `" .. where .. "`")
        elseif d ~= nil and type(v) ~= type(d) then
            problem(("`%s` should be a %s, not a %s"):format(where, type(d), type(v)))
        elseif type(v) == "table" and type(d) == "table" and not is_list(d) then
            out[k] = merge(d, v, where)
        else
            out[k] = v
        end
    end
    return out
end

local function exists(path)
    local f = io.open(path, "r")
    if f then f:close() end
    return f ~= nil
end

local function mkdir(dir)
    if pcall(wezterm.read_dir, dir) then return true end
    local argv = wezterm.target_triple:find("windows")
        and { "cmd.exe", "/c", "mkdir", (dir:gsub("/", "\\")) }
        or { "mkdir", "-p", dir }
    return wezterm.run_child_process(argv)
end

-- defaults.lua with every setting commented out, so the file documents itself
local function template()
    local f = io.open(M.defaults_file, "r")
    if not f then return nil end
    local src = f:read("*a")
    f:close()
    local body = src:match("\nreturn {\n(.*)\n}%s*$")
    if not body then return nil end
    local lines = {}
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = line == "" and "" or ("-- " .. line)
    end
    return table.concat({
        "-- Your WezTerm settings (weztermRC). Below is every default, commented out:",
        "-- uncomment what you want to change, together with the tables around it,",
        "-- e.g.   status = {   word_seconds = 60,   },",
        "-- Saving reloads WezTerm. Problems show up on the bar.",
        "-- Defaults and what each setting does: " .. M.defaults_file,
        "return {",
        table.concat(lines, "\n"),
        "}",
        "",
    }, "\n")
end

function M.ensure_dir()
    return mkdir(M.dir)
end

local function create()
    if exists(M.file) then return end
    local text = template()
    if not text or not mkdir(M.dir) then return end
    local f = io.open(M.file, "w")
    if not f then return end
    f:write(text)
    f:close()
end

local settings
function M.get()
    if settings then return settings end
    local defaults = dofile(M.defaults_file)
    pcall(create)
    local user = {}
    if exists(M.file) then
        wezterm.add_to_config_reload_watch_list(M.file)
        local ok, res = pcall(dofile, M.file)
        if not ok then
            problem((tostring(res):gsub("^.-wezterm%.lua:", "wezterm.lua:")))
        elseif type(res) ~= "table" then
            problem("wezterm.lua should `return { ... }`")
        else
            user = res
        end
    end
    settings = merge(defaults, user, "")
    return settings
end

-- { order, default } from ~/.config/kazrc/themes.lua over THEME_DEFAULTS
-- (call M.get() first: it may create the folder)
local themes
function M.themes()
    if themes then return themes end
    if not exists(M.themes_file) and mkdir(M.dir) then
        local f = io.open(M.themes_file, "w")
        if f then f:write(THEMES_TEMPLATE) f:close() end
    end
    local user = {}
    if exists(M.themes_file) then
        wezterm.add_to_config_reload_watch_list(M.themes_file)
        local ok, res = pcall(dofile, M.themes_file)
        if not ok then
            problem((tostring(res):gsub("^.-themes%.lua:", "themes.lua:")))
        elseif type(res) == "table" then
            user = res
        end
    end
    themes = merge(THEME_DEFAULTS, user, "themes")
    return themes
end

-- first problem, short enough for the bar (all of them are in the debug log)
function M.problem()
    M.get()
    if #problems == 0 then return nil end
    return problems[1] .. (#problems > 1 and ("  (+%d more)"):format(#problems - 1) or "")
end

-- `~/x` and relative-to-assets paths for user-given files
function M.expand(path)
    if path:sub(1, 2) == "~/" then return join(wezterm.home_dir, path:sub(3)) end
    return path
end

return M
