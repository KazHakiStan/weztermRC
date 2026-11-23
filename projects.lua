-- LEADER p: nvim's recent projects (the same list as <leader>pp, kept by
-- neovimRC in nvim's data folder); the one you pick opens in a new tab named
-- after it, with nvim in its folder and your shell under it when nvim exits.
local wezterm = require("wezterm")

local M = {}

local is_windows = wezterm.target_triple:find("windows") ~= nil

local function history_file()
    if is_windows then
        local base = os.getenv("LOCALAPPDATA") or (wezterm.home_dir .. "/AppData/Local")
        return base .. "/nvim-data/projects.json"
    end
    local base = os.getenv("XDG_DATA_HOME") or (wezterm.home_dir .. "/.local/share")
    return base .. "/nvim/projects.json"
end

-- most recent first; folders that are gone are left out
function M.list()
    local f = io.open(history_file(), "r")
    if not f then return {} end
    local ok, data = pcall(wezterm.json_parse, f:read("*a"))
    f:close()
    if not ok or type(data) ~= "table" then return {} end
    local list = {}
    for _, p in ipairs(data) do
        if type(p) == "string" and #wezterm.glob(p) > 0 then list[#list + 1] = p end
    end
    return list
end

local function basename(p)
    return p:gsub("[/\\]+$", ""):match("([^/\\]+)$") or p
end

local function home_relative(p)
    local home = wezterm.home_dir:gsub("\\", "/")
    p = p:gsub("\\", "/")
    if p:sub(1, #home) == home then return "~" .. p:sub(#home + 1) end
    return p
end

-- nvim through the login shell (its PATH), the shell staying after it
local function argv()
    if is_windows then
        return { "pwsh.exe", "-NoLogo", "-NoExit", "-Command", "nvim" }
    end
    local shell = os.getenv("SHELL") or "/bin/zsh"
    return { shell, "-lc", 'nvim; exec "$0" -l', shell }
end

function M.open(window, root)
    local tab = window:mux_window():spawn_tab({ cwd = root, args = argv() })
    if tab then tab:set_title(basename(root)) end
end

function M.choose(window, pane)
    local choices = {}
    for _, p in ipairs(M.list()) do
        choices[#choices + 1] = { id = p, label = ("%-24s %s"):format(basename(p), home_relative(p)) }
    end
    if #choices == 0 then
        return window:toast_notification("WezTerm", "no projects yet: open files in nvim first", nil, 3000)
    end
    window:perform_action(wezterm.action.InputSelector({
        title = "Projects",
        fuzzy = true,
        fuzzy_description = "Project (type to search, Enter = new tab with nvim, Esc = close): ",
        choices = choices,
        action = wezterm.action_callback(function(win, _p, id)
            if id then M.open(win, id) end
        end),
    }), pane)
end

function M.keys()
    return { {
        mods = "LEADER",
        key = "p",
        desc = "Open a recent project (nvim's <leader>pp list) in a new tab with nvim",
        action = wezterm.action_callback(M.choose),
    } }
end

return M
