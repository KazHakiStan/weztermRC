local wezterm = require("wezterm")

local M = {}

-- WezTerm cross-platform:
-- wezterm.home_dir     -> user's home dir
-- wezterm.config_dir   -> directory where wezterm.lua lives

local function join(...)
    local sep = package.config:sub(1, 1) -- "\" on Windows, "/" on unix
    return table.concat({...}, sep)
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

local function extract_num(path)
    -- expects .../picD1.png or .../picL1.png
    local n = path:match("pic[DL](%d+)")
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

function M.list_theme_pics(theme)
    local prefix = (theme == "light") and "picL" or "picD"
    local pattern = join(M.paths.assets_dir, prefix .. "*.*")
    local pics = wezterm.glob(pattern) or {}
    return sort_pics(pics)
end

if is_windows then
    M.default_prog = { "pwsh.exe", "-NoLogo" }
elseif is_macos then
    M.default_prog = { "/bin/zsh", "-l" }
else
    M.default_prog = { "/usr/bin/zsh", "-l" }
end

return M
