local home = os.getenv("HOME")
local ok, wc = pcall(dofile, home .. "/.cache/ricelin/hypr-colors.lua")
if not ok then wc = nil end

local function border(hex, fallback)
    if type(hex) ~= "string" then hex = fallback end
    return "rgb(" .. hex:gsub("#", "") .. ")"
end

local active   = border(wc and wc.active, "#e0563b")
local inactive = border(wc and wc.inactive, "#313a4d")

--[[
    Splash rendering SEGVs Hyprland (pango free in renderSplash) when a monitor
    gets reconfigured while the splash would draw, e.g. a display apply from the
    pill. Logo and splash off closes that crash surface.
]]
hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        -- Follow xdg-activation focus requests (notification clicks, "open in
        -- running app", browser link handoffs): switch to the window's
        -- workspace and focus it instead of just marking it urgent.
        focus_on_activate        = true,
    },
    general = {
        gaps_in     = 6,
        gaps_out    = 12,
        border_size = 2,
        layout      = "dwindle",
        resize_on_border = true,
        ["col.active_border"]   = active,
        ["col.inactive_border"] = inactive,
    },
    decoration = {
        rounding         = 12,
        rounding_power   = 4,
        active_opacity   = 1.00,
        inactive_opacity = 1.00,
        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = 0xaa14110f,
        },
        blur = {
            enabled           = true,
            size              = 6,
            passes            = 2,
            vibrancy          = 0.17,
            noise             = 0.01,
            new_optimizations = true,
        },
    },
})

--[[
    Damage tracking off, deliberately.

    Hyprland only re-renders the damaged rect. The pill is one fullscreen
    layer surface that commits partial damage as it morphs, so the blur
    behind it gets composited from stale framebuffer content: the panel
    opens flat and opaque, then snaps to blurred+translucent one frame
    later, ~350ms in. Measured at 144fps -- a single-frame step, not an
    animation. Disabling the pill's blur removes the step; forcing
    layer.enabled or stretching Motion.morph does not, so it is the
    compositor, not the shell.

    LEFT AT 2, Hyprland's default -- meaning the step above is NOT fixed, it
    is an accepted artifact. 1 (whole-monitor, redraws only on change) fixes
    it for a modest cost and 0 (full redraw every frame) fixes it for a large
    one; both were tried and neither was worth it. Set to 1 if it ever is.

    Unrelated, do not conflate: this laptop's Samsung ATNA40CU09-0 OLED also
    shifts brightness between a moving and a static screen. That one is the
    panel (PSR / ASBL), not the compositor -- a framebuffer capture shows
    byte-identical frames across it. damage_tracking = 0 masks it only by
    never letting the screen go static, which is a bad trade.

    xray would be the cheap fix and must stay off: it samples only the
    cached wallpaper, which is exactly what stops the pill reading as glass.
]]
hl.config({ debug = { damage_tracking = 2 } })
