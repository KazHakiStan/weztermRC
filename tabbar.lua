-- Bottom bar: custom tab titles, activity line (left), cwd + clock (right).
--   LEADER ,   rename tab (empty input = automatic name)
--   LEADER s   activity element: full -> compact (no time) -> off
--   LEADER w   next activity word now (restarts its timer, status.word_seconds)
--   LEADER a   toggle animations (persisted in state.json)
-- Activity line follows proto-agent's ui/activity.py: glyph, shimmering word, elapsed time.

local wezterm = require("wezterm")

local M = {}

-- settings: defaults.lua, overridden by ~/.config/kazrc/wezterm.lua
local kazrc = require("kazrc")
local S = kazrc.get()

local SHIMMER_WIDTH = S.animation.shimmer_width -- half-width of the band in characters

local function nf(name)
    local ok, glyph = pcall(function() return wezterm.nerdfonts[name] end)
    return ok and glyph or ""
end

-- KazGlyphs (fonts/KazGlyphs.ttf): spinning tarot card, U+100000..U+10000B
local CARD = {}
for i = 0, 11 do CARD[#CARD + 1] = utf8.char(0x100000 + i) end

-- "nf:<name>" -> Nerd Font glyph, "card" -> the tarot card, anything else as is
local function glyph(g)
    if g == "card" then return CARD[1] end
    if type(g) == "string" and g:sub(1, 3) == "nf:" then return nf(g:sub(4)) end
    return tostring(g or "")
end

local function frames(f)
    if f == "card" then return CARD end
    local out = {}
    for i, g in ipairs(type(f) == "table" and f or {}) do out[i] = glyph(g) end
    if #out == 0 then out[1] = "·" end
    return out
end

-- Spinner phrases (status.groups), grouped so each group gets a glyph that
-- fits it. frames: animation; hold: ticks per frame; rest: the glyph shown
-- when animations are off.
local FEATURED = S.status.featured
local FEATURED_ODDS = math.max(1, math.floor(S.status.featured_odds))
local GROUPS = {}
local names = {}
for name in pairs(S.status.groups) do names[#names + 1] = name end
table.sort(names) -- stable word order across reloads

-- flat word list (featured excluded: it has its own odds) and word -> group
local WORDS, GROUP_OF = {}, {}
for _, name in ipairs(names) do
    local g = S.status.groups[name]
    local group = {
        frames = frames(g.frames),
        hold = math.max(1, math.floor(tonumber(g.hold) or 1)),
        rest = glyph(g.rest or (type(g.frames) == "table" and g.frames[1]) or g.frames),
    }
    GROUPS[name] = group
    for _, w in ipairs(g.words or {}) do
        GROUP_OF[w] = group
        if w ~= FEATURED then WORDS[#WORDS + 1] = w end
    end
end
local FALLBACK_GROUP = GROUP_OF[FEATURED] or GROUPS.proto or { frames = { "✻" }, hold = 1, rest = "✻" }
if #WORDS == 0 then WORDS[1] = FEATURED end

local WORD_SECONDS = math.max(1, S.status.word_seconds) -- a new word this often

-- All animation advances in ticks of FAST_MS: one spinner frame, one shimmer
-- character and one marquee character per tick, so nothing skips or jumps.
local FAST_MS = S.animation.tick_ms -- status refresh with animations
local SLOW_MS = S.animation.idle_ms -- without: enough for the clock and cwd
local DIR_MAX = S.status.dir_max    -- visible characters of the directory
local MARQUEE_PAUSE = math.ceil(1500 / FAST_MS) -- ticks to rest at each end

---------------------------------------------------------------- helpers

-- tick counter from wall time (os.clock is CPU time, not wall time), so the
-- phase is consistent across windows and survives config reloads
local function tick()
    local t = tonumber(wezterm.time.now():format("%s%.3f")) or os.time()
    return math.floor(t * 1000 / FAST_MS)
end

local function chars(s)
    local out = {}
    for _, c in utf8.codes(s) do
        out[#out + 1] = utf8.char(c)
    end
    return out
end

local function rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function mix(a, b, t)
    t = math.max(0, math.min(1, t))
    local r1, g1, b1 = rgb(a)
    local r2, g2, b2 = rgb(b)
    return string.format("#%02x%02x%02x",
        math.floor(r1 + (r2 - r1) * t + 0.5),
        math.floor(g1 + (g2 - g1) * t + 0.5),
        math.floor(b1 + (b2 - b1) * t + 0.5))
end

-- proto-agent shimmer: a soft light band travels across the text and a bit beyond
-- (one character per tick: a 15-char word takes ~4.4s at 200ms)
local function shimmer(text, base, hi, k, animate)
    local cs = chars(text)
    if not animate then
        return { { Foreground = { Color = base } }, { Text = text } }
    end
    local n = #cs
    local span = math.ceil(n + 2 * SHIMMER_WIDTH)
    local center = (k % span) - SHIMMER_WIDTH
    local items = {}
    for i, ch in ipairs(cs) do
        local d = math.min(1, math.abs((i - 1) - center) / SHIMMER_WIDTH)
        items[#items + 1] = { Foreground = { Color = mix(base, hi, 0.5 * (1 + math.cos(math.pi * d))) } }
        items[#items + 1] = { Text = ch }
    end
    return items
end

local function format_elapsed(s)
    s = math.max(0, math.floor(s))
    if s < 60 then return s .. "с" end
    local m = s // 60
    s = s % 60
    if m < 60 then return string.format("%dм %02dс", m, s) end
    return string.format("%dч %02dм", m // 60, m % 60)
end

local function hash(seed, period)
    local x = seed ~ (period * 2654435761)
    x = ((x ~ (x >> 16)) * 0x45d9f3b) & 0xffffffff
    x = ((x ~ (x >> 16)) * 0x45d9f3b) & 0xffffffff
    return x ~ (x >> 16)
end

-- stable pseudo-random word per period (survives config reloads):
-- featured word ~1 in 5 periods, never the same word twice in a row
local function raw_word(seed, period)
    local x = hash(seed, period)
    if x % FEATURED_ODDS == 0 then
        return FEATURED
    end
    return WORDS[(x // FEATURED_ODDS) % #WORDS + 1]
end

local function pick_word(seed, period)
    local w = raw_word(seed, period)
    if period > 0 and w == raw_word(seed, period - 1) then
        local x = hash(seed, period)
        w = WORDS[(x // 7) % #WORDS + 1]
    end
    return w
end

-- fit into `width` cells, marking the cut with an ellipsis
-- current word period; LEADER w jumps to the next one and restarts its timer
-- (GLOBAL survives config reloads)
local function word_period(now)
    local G = wezterm.GLOBAL
    local since = G.word_since or G.session_start
    return (G.word_base or 0) + (now - since) // WORD_SECONDS
end

local function next_word()
    local now = os.time()
    wezterm.GLOBAL.word_base = word_period(now) + 1
    wezterm.GLOBAL.word_since = now
end

local function fit(text, width)
    if wezterm.column_width(text) <= width then return text end
    return wezterm.truncate_right(text, math.max(0, width - 1)) .. "…"
end

local SHELLS = { zsh = true, bash = true, fish = true, pwsh = true, powershell = true, cmd = true }

local function basename(path)
    if not path or path == "" then return "" end
    path = path:gsub("[/\\]+$", "")
    return path:match("([^/\\]+)$") or path
end

local function process_name(pane)
    local name = basename(pane.foreground_process_name or "")
    return (name:gsub("%.exe$", ""))
end

local function url_path(u)
    if not u then return nil end
    local p = (type(u) == "userdata" and u.file_path) or tostring(u):gsub("^file://[^/]*", "")
    return (p:gsub("^/(%a:)", "%1")) -- "/C:/Users" -> "C:/Users"
end

---------------------------------------------------------------- directory

local function home_relative(p)
    local home = wezterm.home_dir:gsub("\\", "/")
    p = p:gsub("\\", "/")
    if p:sub(1, #home):lower() == home:lower() then
        p = "~" .. p:sub(#home + 1)
    end
    return p
end

-- ~/projects/quest-blocks/projects/apple -> ~/p/q/projects/apple
local function shorten(p, max)
    if utf8.len(p) <= max then return p end
    local parts = {}
    for part in p:gmatch("[^/]+") do parts[#parts + 1] = part end
    local lead = p:sub(1, 1) == "/" and "/" or ""
    for i = 1, #parts - 2 do
        if parts[i] ~= "~" then
            local dot = parts[i]:sub(1, 1) == "." and 2 or 1
            parts[i] = chars(parts[i])[1] .. (dot == 2 and (chars(parts[i])[2] or "") or "")
        end
    end
    return lead .. table.concat(parts, "/")
end

-- still too long: scroll back and forth with a pause at each end
local function marquee(p, max, k, animate)
    local cs = chars(p)
    if #cs <= max then return p end
    local overflow = #cs - max
    local offset = overflow -- static: show the tail (current dir is most useful)
    if animate then
        -- one character per tick, pausing at each end
        local cycle = 2 * (overflow + MARQUEE_PAUSE)
        local x = k % cycle
        if x < MARQUEE_PAUSE then
            offset = 0
        elseif x < MARQUEE_PAUSE + overflow then
            offset = x - MARQUEE_PAUSE
        elseif x < 2 * MARQUEE_PAUSE + overflow then
            offset = overflow
        else
            offset = overflow - (x - 2 * MARQUEE_PAUSE - overflow)
        end
    end
    return table.concat(cs, "", offset + 1, offset + max)
end

-- cwd lookup can hit the OS, so cache it per pane for a second
local cwd_cache = {}
local function pane_dir(pane)
    local id = pane:pane_id()
    local t = os.time()
    local c = cwd_cache[id]
    if c and c.t == t then return c.dir end
    local p = url_path(pane:get_current_working_dir())
    local dir = p and shorten(home_relative(p), DIR_MAX) or ""
    cwd_cache[id] = { t = t, dir = dir }
    return dir
end

---------------------------------------------------------------- setup

function M.apply(config, theme, state)
    local ui = theme.ui
    local animate = state.animate
    wezterm.GLOBAL.session_start = wezterm.GLOBAL.session_start or os.time()

    config.status_update_interval = animate and FAST_MS or SLOW_MS
    config.tab_max_width = S.window.tab_max_width

    -- tabs: "▌0 name " (2 cells of decoration around the label)
    wezterm.on("format-tab-title", function(tab, _tabs, _panes, _cfg, hover, max_width)
        local pane = tab.active_pane
        local proc = process_name(pane)
        local auto = proc
        if SHELLS[proc] or proc == "" then
            auto = basename(url_path(pane.current_working_dir) or pane.title)
        end
        local name = (tab.tab_title and tab.tab_title ~= "") and tab.tab_title or auto
        local label = fit(string.format("%d %s", tab.tab_index, name), max_width - 2)

        if tab.is_active then
            -- the active tab shimmers like the activity word
            local items = {
                { Background = { Color = ui.bg_active } },
                { Foreground = { Color = ui.accent } }, { Text = "▌" },
                { Attribute = { Intensity = "Bold" } },
            }
            for _, it in ipairs(shimmer(label, ui.bright, ui.shimmer[2], tick(), animate)) do
                items[#items + 1] = it
            end
            items[#items + 1] = { Text = " " }
            return items
        end
        return {
            { Background = { Color = hover and ui.bg_active or ui.bg } },
            { Foreground = { Color = hover and ui.accent or ui.muted } },
            { Text = " " .. label .. " " },
        }
    end)

    wezterm.on("update-status", function(window, pane)
        local k = tick()

        -- left: activity line / leader indicator
        local left = { { Background = { Color = ui.bg } } }
        -- mode badges: LEADER pending, or a key table mode (LEADER m -> MOVE)
        local badge, badge_bg
        if window:leader_is_active() then
            badge, badge_bg = "LEADER", ui.accent
        elseif window:active_key_table() == "move_tab" then
            badge, badge_bg = "MOVE  b n 0-9", ui.glow
        end
        -- a broken or mistyped ~/.config/kazrc/wezterm.lua says so here
        local trouble = kazrc.problem()
        if not badge and trouble then
            badge, badge_bg = "kazrc: " .. trouble .. "  (LEADER e)", ui.accent
        end
        if badge then
            table.insert(left, { Background = { Color = badge_bg } })
            table.insert(left, { Foreground = { Color = ui.bg } })
            table.insert(left, { Attribute = { Intensity = "Bold" } })
            table.insert(left, { Text = " " .. badge .. " " })
            table.insert(left, "ResetAttributes")
            table.insert(left, { Background = { Color = ui.bg } })
            table.insert(left, { Text = " " })
        elseif state.activity ~= "off" then
            local elapsed = os.time() - wezterm.GLOBAL.session_start
            local word = pick_word(wezterm.GLOBAL.session_start, word_period(os.time()))
            local g = GROUP_OF[word] or FALLBACK_GROUP
            local frame = animate and g.frames[(k // g.hold) % #g.frames + 1] or g.rest
            table.insert(left, { Foreground = { Color = ui.shimmer[1] } })
            table.insert(left, { Text = " " .. frame .. " " })
            for _, it in ipairs(shimmer(word .. "…", ui.shimmer[1], ui.shimmer[2], k, animate)) do
                table.insert(left, it)
            end
            table.insert(left, { Foreground = { Color = ui.muted } })
            if state.activity == "compact" then
                table.insert(left, { Text = "  " })
            else
                table.insert(left, { Text = " (" .. format_elapsed(elapsed) .. ")  " })
            end
        end
        window:set_left_status(wezterm.format(left))

        -- right: directory, then clock in the corner
        local dir = marquee(pane_dir(pane), DIR_MAX, k, animate)
        local right = {
            { Background = { Color = ui.bg } },
            { Foreground = { Color = ui.muted } }, { Text = nf("md_folder_outline") .. " " },
            { Foreground = { Color = ui.fg } }, { Text = dir .. "  " },
        }
        if S.status.clock ~= "" then
            for _, it in ipairs({
                { Background = { Color = ui.bg_active } },
                { Foreground = { Color = ui.accent } }, { Text = "▌" },
                { Foreground = { Color = ui.bright } }, { Attribute = { Intensity = "Bold" } },
                { Text = wezterm.strftime(S.status.clock) .. " " },
            }) do right[#right + 1] = it end
        end
        window:set_right_status(wezterm.format(right))
    end)
end

function M.keys()
    local state_store = require("state")
    return {
        {
            mods = "LEADER",
            key = ",",
            section = "Tabs",
            desc = "Rename tab (empty = automatic name)",
            action = wezterm.action.PromptInputLine({
                description = "Tab name (empty = automatic)",
                action = wezterm.action_callback(function(window, _pane, line)
                    if line ~= nil then -- nil = Esc
                        window:active_tab():set_title(line)
                    end
                end),
            }),
        },
        {
            mods = "LEADER",
            key = "s",
            section = "Bar",
            desc = "Activity element: full → compact (no time) → off",
            action = wezterm.action_callback(function(_window, _pane)
                state_store.cycle_activity()
                wezterm.reload_configuration()
            end),
        },
        {
            mods = "LEADER",
            key = "w",
            section = "Bar",
            desc = "Next activity word now",
            action = wezterm.action_callback(function(_window, _pane)
                next_word()
            end),
        },
        {
            mods = "LEADER",
            key = "a",
            section = "Bar",
            desc = "Animations on / off",
            action = wezterm.action_callback(function(_window, _pane)
                state_store.toggle_animate()
                wezterm.reload_configuration()
            end),
        },
    }
end

return M
