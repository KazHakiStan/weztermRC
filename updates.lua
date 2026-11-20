-- Updates of this config (weztermRC). Releases are tags (v1.2.0) on master;
-- this clone stays on master and moves forward to them, so a plain `git pull`
-- still works. Once in a while (updates.check_hours) WezTerm fetches in the
-- background and shows the new version on the bar; LEADER u takes it (the
-- config reloads by itself).
--   updates.follow = "release"  tagged versions (default)
--                    "latest"   every commit on master
--                    "off"      no checks
-- Your own changes live in ~/.config/kazrc; changes made in this repo stop an
-- update (it names the files) rather than being overwritten.
local wezterm = require("wezterm")
local kazrc = require("kazrc")

local M = {}

M.dir = wezterm.config_dir
M.name = "weztermRC"

local FOLLOW = { release = true, latest = true, off = true }

local function settings()
    local s = kazrc.get().updates
    if not FOLLOW[s.follow] then return { follow = "release", check_hours = s.check_hours } end
    return s
end

if not FOLLOW[kazrc.get().updates.follow] then
    kazrc.add_problem('`updates.follow` should be "release", "latest" or "off"')
end

-- git in M.dir: ok, stdout, stderr (trimmed); callbacks only (it's async)
local function git(args)
    local argv = { "git", "-C", M.dir }
    for _, a in ipairs(args) do argv[#argv + 1] = a end
    local ran, ok, out, err = pcall(wezterm.run_child_process, argv)
    if not ran then return false, "", tostring(ok) end
    local function trim(s) return ((s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
    return ok, trim(out), trim(err)
end

-- the repos are public: fetch a GitHub SSH origin over HTTPS, so a key with a
-- passphrase (or none at all) doesn't matter
local function fetch_url(origin)
    local path = origin:match("^git@github%.com:(.+)$") or origin:match("^ssh://git@github%.com/(.+)$")
    return path and ("https://github.com/" .. path) or origin
end

local function fetch(branch)
    local ok, origin = git({ "remote", "get-url", "origin" })
    if not ok then return false end
    return (git({ "-c", "core.sshCommand=ssh -o BatchMode=yes", "fetch", "--quiet", "--tags", "--force",
        fetch_url(origin), ("+refs/heads/%s:refs/remotes/origin/%s"):format(branch, branch) }))
end

-- What an update would bring: { target, label, current, count }, or nil and
-- why not (nil, nil = up to date).
local function status(do_fetch)
    local on_branch, branch = git({ "symbolic-ref", "--quiet", "--short", "HEAD" })
    if not on_branch then return nil, "the repo isn't on a branch" end
    if do_fetch and not fetch(branch) then return nil, "couldn't reach the repo" end
    local _, current = git({ "describe", "--tags", "--abbrev=0", "--match", "v*" })
    local s = { current = current ~= "" and current or nil }
    local target
    if settings().follow == "latest" then
        target = "origin/" .. branch
    else
        local _, tags = git({ "tag", "--list", "v*", "--sort=-v:refname" })
        target = tags:match("^[^\n]+")
        if not target then return nil, "no releases yet" end
        s.label = target
    end
    local _, count = git({ "rev-list", "--count", "HEAD.." .. target })
    count = tonumber(count) or 0
    if count == 0 then return nil end -- up to date, or ahead of it
    if not git({ "merge-base", "--is-ancestor", "HEAD", target }) then
        return nil, "this clone has commits of its own"
    end
    s.target, s.count = target, count
    s.label = s.label or (count == 1 and "1 new commit" or (count .. " new commits"))
    return s
end

-- wezterm.GLOBAL survives config reloads: the result of the last check, and
-- a short message after LEADER u
local G = wezterm.GLOBAL

-- From the status bar's refresh: start a check when it's time. Runs a moment
-- later (call_after), so the bar never waits for git.
function M.tick()
    local s = settings()
    if s.follow == "off" then
        G.update = nil
        return
    end
    local now = os.time()
    if (G.update_busy or 0) > now - 120 then return end
    if G.update_at and now - G.update_at < s.check_hours * 3600 then return end
    G.update_busy = now
    wezterm.time.call_after(1, function()
        local ok, res = pcall(status, true)
        G.update = ok and res and { label = res.label, current = res.current } or nil
        G.update_at = os.time()
        G.update_busy = nil
    end)
end

-- on the bar: the new version while there is one
function M.available()
    return G.update and G.update.label or nil
end

-- a message for the bar's badge, for a few seconds
local function note(text, seconds)
    G.update_note = { text = text, till = os.time() + (seconds or 8) }
    wezterm.log_info(M.name .. ": " .. text)
end

function M.note()
    local n = G.update_note
    if n and os.time() < n.till then return n.text end
    return nil
end

function M.update()
    note("checking for updates…", 60)
    local s, why = status(true)
    G.update_at = os.time()
    if not s then
        G.update = nil
        if why then return note("not updated: " .. why) end
        local _, current = git({ "describe", "--tags", "--match", "v*" })
        return note(M.name .. " is up to date" .. (current ~= "" and (" (" .. current .. ")") or ""))
    end
    local _, changed = git({ "diff", "--name-only", "HEAD" })
    if changed ~= "" then
        return note("not updated: changed here: " .. changed:gsub("\n", ", ")
            .. " (move it to ~/.config/kazrc, then git checkout .)", 15)
    end
    local ok, _, err = git({ "merge", "--ff-only", "--quiet", s.target })
    if not ok then return note("not updated: " .. err, 15) end
    G.update = nil
    note(M.name .. " updated to " .. s.label, 10)
    wezterm.reload_configuration()
end

function M.keys()
    return {
        {
            mods = "LEADER",
            key = "u",
            desc = "Update weztermRC to its new version (the bar shows when there is one)",
            action = wezterm.action_callback(function() M.update() end),
        },
    }
end

return M
