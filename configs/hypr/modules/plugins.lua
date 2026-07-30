-- ═══════════════════════════════════════════════════════════════════════════
-- Hyprland plugins
-- ═══════════════════════════════════════════════════════════════════════════
-- Everything here is optional and pcall-guarded: a machine without the plugin
-- built (or one where hyprpm has not rebuilt it after a Hyprland bump) still
-- gets a working config instead of a parse error and emergency mode.
--
-- Note this config is parsed by Hyprland's LUA parser, not hyprlang. The
-- plugin's documented `scrolloverview-gesture = 4, up, overview` keyword is
-- legacy-parser-only and does nothing here; the Lua-side equivalent is the
-- hl.plugin.scrolloverview.* table the plugin registers once loaded.
-- ═══════════════════════════════════════════════════════════════════════════

-- hyprpm builds into /var/cache/hyprpm/<user>/<repo>/<plugin>.so. Nothing in
-- the session loads it for us, so without this the plugin is gone after a
-- reboot even though `hyprpm list` still reports it enabled.
local function plugin_path(repo, name)
    local user = os.getenv("USER") or os.getenv("LOGNAME")
    return "/var/cache/hyprpm/" .. tostring(user) .. "/" .. repo .. "/" .. name .. ".so"
end

-- ── scrolloverview ─────────────────────────────────────────────────────────
-- https://github.com/yayuuu/hyprland-scroll-overview
pcall(function()
    if not (hl.plugin and hl.plugin.scrolloverview) then
        pcall(hl.plugin.load, plugin_path("hyprland-scroll-overview", "scrolloverview"))
    end

    local so = hl.plugin and hl.plugin.scrolloverview
    if not so then return end -- not built for this Hyprland version; skip quietly

    so.configure({
        -- Travel that counts as a full gesture. Matches the native
        -- workspace_swipe_distance in modules/input.lua so the overview swipe
        -- and the workspace swipe need the same amount of finger movement.
        gesture_distance = 150,
        scale            = 0.35,   -- preferred overview scale (valid 0.1 - 0.9)
        workspace_gap    = 60,     -- px between cards; tightened to suit scale 0.35
        layout           = "horizontal",
        wallpaper        = 0,      -- 0: global only, 1: per-workspace, 2: both
        blur             = false,

        shadow = {
            enabled       = false,
            range         = 50,
            render_power  = 3,
            color         = 0xee1a1a1a,
        },

        input = {
            -- 0: layout-aware, 1: inverted, 2: vert=workspace/horiz=columns,
            -- 3: vert=columns/horiz=workspace
            scrolling_mode         = 0,
            -- 0: main button drags windows, middle pans; 1: the reverse
            drag_mode              = 0,
            -- 0: normal, 1: swap left/right mouse buttons inside the overview.
            -- Was live at 2, which the plugin does not define; pinned to 0.
            left_handed            = 0,
            touchpad_scroll_factor = 1.5, -- less finger travel per workspace
            drag_threshold         = 4,   -- px before a press counts as a drag
            scroll_event_delay     = 120, -- ms debounce between scroll events
        },
    })

    -- Four fingers up opens the overview. If this ever starts SEGVing Hyprland
    -- on a multi-finger pinch, this is the line to comment out -- an older
    -- Hyprland (0.55.4) crashed that way whenever a swipe-direction trackpad
    -- gesture was registered.
    so.gesture({ fingers = 4, direction = "up" })

    -- Keyboard fallback, so the overview is still reachable with the gesture
    -- commented out or on an external keyboard with no touchpad.
    hl.bind("CTRL + SUPER + O", so.overview("toggle"))
end)
