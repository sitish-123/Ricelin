hl.config({
    input = {
        kb_layout          = "us",
        follow_mouse       = 1,
        sensitivity        = 0,
        accel_profile      = "flat",
        repeat_rate        = 40,
        repeat_delay       = 400,
        numlock_by_default = false,
        touchpad = {
            natural_scroll = true,
        },
    },
    cursor = {
        no_hardware_cursors = true,
    },
    binds = {
        scroll_event_delay = 40,
    },
    gestures = {
        -- Take the friction out of the workspace swipe. At the stock
        -- cancel_ratio of 0.5 a swipe has to cover half the full distance
        -- before it commits, and anything short of that springs back to where
        -- it started -- that snap-back is the "sticky" feel.
        workspace_swipe_cancel_ratio      = 0.15, -- commit early instead of snapping back
        workspace_swipe_distance          = 150,  -- full swipe travel (was 300)
        workspace_swipe_min_speed_to_force = 5,   -- a quick flick always commits (was 30)
    },
})

-- ── Trackpad gestures ──────────────────────────────────────────────────────
-- Native Hyprland gestures (the scrolloverview 4-finger-up lives in
-- modules/plugins.lua, on a different axis, so the two do not shadow).
--
-- "horizontal" is bidirectional and shadows separate "left"/"right" entries,
-- so it is the one to register rather than a pair.
--
-- Valid directions: horizontal, vertical, up, down, left, right, pinch, swipe.
-- Valid actions:    workspace, move, resize, close, fullscreen, special, float.
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "swipe",      action = "move" })
