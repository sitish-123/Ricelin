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

-- ═══════════════════════════════════════════════════════════════════════════
-- DO NOT call hl.plugin.load() from this file.
--
-- 2026-07-31: this file used to load scrolloverview by hardcoded .so path.
-- Loading a plugin mid-parse makes Hyprland re-parse the config, which reaches
-- the load call again: reload -> handlePluginLoads -> postConfigReload ->
-- reload -> ... until the process dies. Confirmed in three coredumps
-- (SIGSEGV on stack exhaustion, and once SIGSEGV in luaL_alloc on heap
-- exhaustion). SDDM surfaced it as `ERROR_INTERNAL "Process crashed"`, so it
-- looked like a login failure -- it was the compositor dying on startup, and
-- the machine could not be booted into Hyprland at all.
--
-- The `pcall` below does not protect against this: the recursion is in
-- Hyprland's C++ config manager, not a catchable Lua error.
--
-- Plugins are loaded by `hyprpm reload -n` from modules/autostart.lua, out of
-- band once the compositor is up. hyprpm also resolves the real build path and
-- refuses an .so built against a different Hyprland ABI, neither of which a
-- hardcoded path does.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── scrolloverview ─────────────────────────────────────────────────────────
-- https://github.com/yayuuu/hyprland-scroll-overview
--
-- On the first parse of a fresh session the plugin is not loaded yet, so this
-- block no-ops. hyprpm's load then triggers one config reload, and on that
-- second pass hl.plugin.scrolloverview exists and the settings below apply.
-- That reload terminates because nothing here loads a plugin.
pcall(function()
    local so = hl.plugin and hl.plugin.scrolloverview
    if not so then return end -- not loaded (or not built for this Hyprland); skip quietly

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

    -- Four fingers horizontal navigates the carousel continuously (1:1 with the finger,
    -- snapping to the nearest card on release). Outside the overview this gesture forwards
    -- to a native workspace swipe, so it replaces the `hl.gesture({fingers = 4, direction =
    -- "horizontal", action = "workspace"})` that used to live in modules/input.lua -- both
    -- cannot be registered at once.
    --
    -- Fork-only action (~/Projects/scroll-overview). Stock scrolloverview raises on it, so
    -- this goes LAST in the block: the pcall swallows the error and everything above has
    -- already been applied. On a stock build the 4-finger horizontal swipe simply does
    -- nothing until the line in modules/input.lua is restored.
    so.gesture({ fingers = 4, direction = "horizontal", action = "navigate" })
end)
