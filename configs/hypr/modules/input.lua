hl.config({
    input = {
        kb_layout          = "us",
        follow_mouse       = 1,
        sensitivity        = 0,
        accel_profile      = "adaptive",
        repeat_rate        = 40,
        repeat_delay       = 400,
        numlock_by_default = false,
        touchpad = {
            natural_scroll = true,
            -- 1 = drag-lock with timeout. Without it (0) lifting a finger ends the drag,
            -- which makes dragging a window between scrolloverview cards nearly impossible:
            -- that is ~870px of cursor travel at scale 0.35, more than one stroke on this
            -- touchpad, so the drag dies as soon as you reposition. With the timeout variant
            -- a lift keeps the button held briefly instead of dropping the window, and still
            -- releases on its own -- no sticky state to get stuck in (2 would be sticky).
            drag_lock      = 1,
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
-- 4-finger horizontal is NOT registered here. It is registered by scrolloverview in
-- modules/plugins.lua as action = "navigate", which falls back to this exact native
-- workspace swipe when no overview is open, and drives the overview's continuous
-- carousel when one is. Registering both is impossible: Hyprland's gesture manager
-- rejects a second gesture on the same finger count + axis, and with the native one
-- winning, a swipe inside the overview did a hard +1/-1 workspace switch (which also
-- closed the overview) instead of following the finger.
hl.gesture({ fingers = 3, direction = "swipe", action = "move" })
