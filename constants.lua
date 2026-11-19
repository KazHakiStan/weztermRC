local wezterm = require("wezterm")

local M = {}

-- WezTerm cross-platform:
-- wezterm.home_dir     -> user's home dir
-- wezterm.config_dir   -> directory where wezterm.lua lives

-- Always "/": Windows accepts it everywhere wezterm uses paths, while "\"
-- would act as an escape character in wezterm.glob patterns.
local function join(...)
    local parts = {}
    for i, p in ipairs({...}) do
        parts[i] = (p:gsub("\\", "/"))
    end
    return table.concat(parts, "/")
end

M.join = join

local is_windows =  wezterm.target_triple:find("windows") ~= nil
local is_macos =    wezterm.target_triple:find("apple") ~= nil
local is_linux =    wezterm.target_triple:find("linux") ~= nil

M.platform = {
    is_windows  = is_windows,
    is_linux    = is_linux,
    is_macos    = is_macos,
    target_triple = wezterm.target_triple,
}

M.paths = {
    assets_dir   = join(wezterm.config_dir, "assets"),
    -- bg_image    = join(wezterm.config_dir, "assets", "picD3.jpeg"),
}

-- shared with nvim: {"theme":"<name>"}; nvim lives elsewhere on Windows,
-- but both resolve ~ to the same home dir
M.paths.theme_file = join(wezterm.home_dir, ".config", "kazrc", "theme.json")
M.paths.legacy_theme_file = join(wezterm.home_dir, ".config", "theme.json") -- before kazrc

local function extract_num(path)
    -- trailing number before extension: picD4.png -> 4, aegis-lavender.png -> 0
    local n = path:match("(%d+)%.%w+$")
    return tonumber(n) or 0
end

local function sort_pics(pics)
    table.sort(pics, function(a, b)
        local na, nb = extract_num(a), extract_num(b)
        if na == nb then
            return a < b
        end
        return na < nb
    end)
    return pics
end

-- a glob in assets/ ("picD*" -> picD*.*), or a path of your own:
-- "~/Pictures/walls/*.jpg", "/abs/path/*.png", "C:/walls/*"
function M.list_pics(glob)
    if not glob or glob == "" then return {} end
    local pattern
    if glob:sub(1, 2) == "~/" then
        pattern = join(wezterm.home_dir, glob:sub(3))
    elseif glob:sub(1, 1) == "/" or glob:match("^%a:[/\\]") then
        pattern = glob
    else
        pattern = join(M.paths.assets_dir, glob .. ".*")
    end
    local ok, pics = pcall(wezterm.glob, pattern)
    return sort_pics(ok and pics or {})
end

local shell = require("kazrc").get().shell
if shell then
    M.default_prog = shell
elseif is_windows then
    M.default_prog = { "pwsh.exe", "-NoLogo" }
elseif is_macos then
    M.default_prog = { "/bin/zsh", "-l" }
else
    M.default_prog = { "/usr/bin/zsh", "-l" }
end

return M
