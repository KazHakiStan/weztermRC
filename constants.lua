local wezterm = require("wezterm")

local M = {}

-- WezTerm cross-platform:
-- wezterm.home_dir     -> user's home dir
-- wezterm.config_dir   -> directory where wezterm.lua lives

local function join(...)
    local sep = package.config:sub(1, 1) -- "\" on Windows, "/" on unix
    return table.concat({...}, sep)
end

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
    asset_dir   = join(wezterm.config_dir, "assets"),
    bg_image    = join(wezterm.config_dir, "assets", "pic.jpg"),
}

if is_windows then
    M.default_prog = { "pwsh.exe", "-NoLogo" }
elseif is_macos then
    M.default_prog = { "/bin/zsh", "-1" }
else
    M.default_prog = { "/usr/bin/zsh", "-1" }
end

return M
