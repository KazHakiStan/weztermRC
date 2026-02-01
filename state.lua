local wezterm = require("wezterm")
local constants = require("constants")

local M = {}

local state_path = constants.join(wezterm.config_dir, "state.json")

function M.load()
    local f = io.open(state_path, "r")
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

function M.save(data)
    local f = io.open(state_path, "w")
    if not f then
        wezterm.log_error("Failed to write " .. state_path)
        return
    end
    f:write(wezterm.json_encode(data))
    f:close()
end

return M
