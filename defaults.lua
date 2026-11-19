-- Default settings. Don't edit them here: ~/.config/kazrc/wezterm.lua
-- (created on first start, LEADER e opens it) overrides any of them, and this
-- repo stays clean for updates. Tables merge key by key; lists replace whole.
return {
    -- program in new tabs; nil = zsh -l on macOS/Linux, pwsh on Windows
    shell = nil, -- e.g. { "/opt/homebrew/bin/fish", "-l" }

    font = {
        family = "JetBrains Mono", -- built into WezTerm
        size = 12,
        line_height = 1.2,
    },

    leader = { key = "q", mods = "CTRL", timeout_ms = 2000 },

    window = {
        decorations = "RESIZE", -- "TITLE | RESIZE", "NONE", ...
        tab_bar_at_bottom = true,
        tab_max_width = 40,
    },

    themes = {
        -- order and default: ~/.config/kazrc/themes.lua, shared with nvim
        -- background picture per theme: a glob in assets/ or a path of your
        -- own, e.g. ashen = "~/Pictures/walls/red.jpg"
        pictures = {
            ["ashen"] = "aegis-red*",
            ["aegis-lavender"] = "aegis-lavender*",
            ["aegis-gold"] = "aegis-gold*",
            ["metaphor-light"] = "metaphor-light*",
            ["silent-hunter"] = "silent-hunter*",
        },
    },

    status = {
        -- the activity word changes this often (LEADER w skips to the next)
        word_seconds = 120,
        -- shown about one period in `featured_odds`
        featured = "Prototyping",
        featured_odds = 5,
        -- Word groups: each has its own glyph. frames: animation ("nf:<name>" is a
        -- Nerd Font icon, "card" the tarot card from KazGlyphs); hold: ticks per
        -- frame; rest: glyph with animations off. Add groups, or set words = {}
        -- to drop one.
        groups = {
            proto = { -- proto-agent's own spinner; holds the featured word
                frames = { "·", "✢", "✳", "✶", "✻", "✽", "✻", "✶", "✳", "✢" }, hold = 1, rest = "✻",
                words = { "Prototyping" },
            },
            p3 = { -- Dark Hour: the moon waxes to full and wanes
                frames = { "nf:md_moon_new", "nf:md_moon_waxing_crescent", "nf:md_moon_first_quarter",
                    "nf:md_moon_waxing_gibbous", "nf:md_moon_full", "nf:md_moon_waning_gibbous",
                    "nf:md_moon_last_quarter", "nf:md_moon_waning_crescent" },
                hold = 2, rest = "nf:md_moon_full",
                words = { "Evoking", "Tartarus-climbing", "Dark-Houring" },
            },
            p4 = { -- Midnight Channel: a flickering TV
                frames = { "nf:md_television_classic", "nf:md_television_classic_off" },
                hold = 3, rest = "nf:md_television_classic",
                words = { "TV-diving", "Midnight-channeling" },
            },
            p5 = { -- calling card
                frames = "card", hold = 1, rest = "card",
                words = { "Infiltrating palaces", "Calling-carding", "Baton-passing", "All-out-attacking",
                    "Showtiming" },
            },
            persona = { -- Philemon's butterfly
                frames = { "nf:md_butterfly_outline", "nf:md_butterfly" }, hold = 3, rest = "nf:md_butterfly",
                words = { "Social-linking", "Fusing personas" },
            },
            smt = { -- Magatsuhi flare
                frames = { "nf:md_star_four_points_outline", "nf:md_star_four_points" },
                hold = 3, rest = "nf:md_star_four_points",
                words = { "Press-turning", "Magatsuhi-surging", "Smirking", "Demon-negotiating",
                    "Essence-fusing", "Nahobino-merging", "Miman-hunting", "Da'at-wandering" },
            },
            mass_effect = { -- mass relay rings
                frames = { "◐", "◓", "◑", "◒" }, hold = 2, rest = "◐",
                words = { "Calibrating", "Relay-jumping", "Omni-tooling", "Biotic-charging", "Planet-probing",
                    "Paragoning", "Renegading", "Indoctrinating" },
            },
            cyberpunk = { -- glitching pixel
                frames = { "▖", "▘", "▝", "▗" }, hold = 1, rest = "▘",
                words = { "Netrunning", "Jacking in", "Quickhacking", "Breaching protocol", "Braindancing",
                    "Overclocking", "Sandevistaning", "Chroming up" },
            },
            expanse = { -- Epstein drive burn
                frames = { "nf:md_rocket_launch_outline", "nf:md_rocket_launch" },
                hold = 3, rest = "nf:md_rocket_launch",
                words = { "Burning hard", "Juicing", "Protomoleculizing" },
            },
            atomic_heart = { -- polymer drop
                frames = { "nf:md_water_outline", "nf:md_water" }, hold = 3, rest = "nf:md_water",
                words = { "Polymerizing", "Kollektiv-syncing", "Neuro-linking" },
            },
        },
        dir_max = 30, -- visible characters of the directory on the right
        clock = "%H:%M", -- strftime format; "" hides the clock
    },

    animation = {
        tick_ms = 200, -- refresh with animations on (120 ms ~ +4.7% of a core, 200 ~ +2.2%)
        idle_ms = 1000, -- refresh with animations off
        shimmer_width = 3.5, -- half-width of the light band, in characters
    },
}
