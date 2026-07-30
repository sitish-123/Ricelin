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
        gesture_distance = 300,  -- travel that counts as a full gesture
        scale            = 0.5,  -- preferred overview scale
        workspace_gap    = 100,
        layout           = "vertical",
        wallpaper        = 0,    -- 0: global only, 1: per-workspace, 2: both
        blur             = false,

        shadow = {
            enabled       = false,
            range         = 50,
            render_power  = 3,
            color         = 0xee1a1a1a,
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
