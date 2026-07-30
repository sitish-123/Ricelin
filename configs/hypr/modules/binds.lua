-- ═══════════════════════════════════════════════════════════════════════════
-- Keybinds
-- ═══════════════════════════════════════════════════════════════════════════
-- Ricelin's bind set merged with the keybinds carried over from the previous
-- (illogical-impulse / ii) setup. Where the two collided the ported bind won,
-- because muscle memory is the reason for carrying them at all; the Ricelin
-- action it displaced moved to a neighbouring key rather than being dropped.
--
-- Binds that drove the old ii shell (sidebars, cheatsheet, OCR, region search,
-- workspace-number overlay) are gone with it. Where the old entry already had a
-- non-shell fallback baked into its command, that fallback is what is bound here.
--
-- App launches go through scripts/launch-first.sh so a bind still works on a
-- box that has firefox instead of chromium, micro instead of code, and so on.
-- ═══════════════════════════════════════════════════════════════════════════

local mod  = "SUPER"
local HOME = os.getenv("HOME")

local function script(name) return HOME .. "/.config/hypr/scripts/" .. name end
local function launch(...)
    local parts = { ... }
    for i, p in ipairs(parts) do parts[i] = "'" .. p .. "'" end
    return script("launch-first.sh") .. " " .. table.concat(parts, " ")
end

-- Cursor zoom, clamped to 1.0-3.0. hl.dsp has no zoom dispatcher, so this reads
-- and rewrites cursor:zoom_factor directly, the way the old setup did.
local function zoom(step)
    return function()
        local z = hl.get_config("cursor:zoom_factor") + step
        if z > 3.0 then z = 3.0 elseif z < 1.0 then z = 1.0 end
        hl.config({ cursor = { zoom_factor = z } })
    end
end

-- ── Apps ───────────────────────────────────────────────────────────────────
hl.bind(mod .. " + Return",     hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + T",          hl.dsp.exec_cmd("kitty"))
hl.bind("CTRL + ALT + T",       hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E",          hl.dsp.exec_cmd(launch("dolphin", "nautilus", "nemo", "thunar", "kitty -e yazi")))
hl.bind(mod .. " + W",          hl.dsp.exec_cmd(launch("zen", "zen-browser", "helium-browser", "chromium", "brave", "firefox")))
hl.bind(mod .. " + C",          hl.dsp.exec_cmd(launch("windsurf", "code", "codium", "cursor", "zed", "kate", "kitty -e micro")))
hl.bind(mod .. " + X",          hl.dsp.exec_cmd(launch("kate", "gnome-text-editor", "kitty -e micro")))
hl.bind("CTRL + " .. mod .. " + V",   hl.dsp.exec_cmd(launch("pavucontrol-qt", "pavucontrol")))
hl.bind("CTRL + SHIFT + Escape",      hl.dsp.exec_cmd(launch("plasma-systemmonitor", "gnome-system-monitor", "kitty -e btop")))

-- ── Windows ────────────────────────────────────────────────────────────────
hl.bind(mod .. " + Q",               hl.dsp.window.close())
hl.bind("CTRL + SHIFT + W",          hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mod .. " + F",               hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + D",               hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))
hl.bind(mod .. " + ALT + F",         hl.dsp.window.fullscreen_state({ internal = 0, client = 3, action = "toggle" }))
hl.bind(mod .. " + P",               hl.dsp.window.pin())
hl.bind(mod .. " + ALT + Space",     hl.dsp.window.float({ action = "toggle" }))

hl.bind(mod .. " + Left",           hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + Right",          hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + Up",             hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + Down",           hl.dsp.focus({ direction = "d" }))
hl.bind(mod .. " + BracketLeft",    hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + BracketRight",   hl.dsp.focus({ direction = "r" }))

hl.bind(mod .. " + SHIFT + Left",   hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + Right",  hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + Up",     hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + Down",   hl.dsp.window.move({ direction = "d" }))

hl.bind(mod .. " + Semicolon",      hl.dsp.layout("splitratio -0.1"), { repeating = true })
hl.bind(mod .. " + Apostrophe",     hl.dsp.layout("splitratio +0.1"), { repeating = true })

hl.bind(mod .. " + mouse:272",      hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273",      hl.dsp.window.resize(), { mouse = true })

hl.bind("ALT + F4", hl.dsp.exec_cmd(
    "notify-send 'Wrong close keybind' 'SUPER+Q to close. Alt+F4 is for Windows VMs.' -a Hyprland"),
    { non_consuming = true })

-- ── Workspaces ─────────────────────────────────────────────────────────────
-- SHIFT and ALT both send a window to a workspace: SHIFT is Ricelin's, ALT is
-- what the old setup used. Keeping both costs nothing and neither is displaced.
for i = 1, 10 do
    local key = (i == 10) and "0" or tostring(i)
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
    hl.bind(mod .. " + ALT + " .. key,   hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind("CTRL + " .. mod .. " + Left",   hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + " .. mod .. " + Right",  hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mod .. " + Page_Up",             hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + Page_Down",           hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mod .. " + mouse_up",            hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + mouse_down",          hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mod .. " + SHIFT + Page_Up",     hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mod .. " + SHIFT + Page_Down",   hl.dsp.window.move({ workspace = "r+1" }))

-- ── Special workspaces ─────────────────────────────────────────────────────
-- SUPER+S keeps its old "scratchpad" feel; Ricelin calls the same idea "stash".
hl.bind(mod .. " + S",                  hl.dsp.workspace.toggle_special("stash"))
hl.bind(mod .. " + ALT + S",            hl.dsp.window.move({ workspace = "special:stash", follow = false }))
hl.bind("CTRL + " .. mod .. " + S",     hl.dsp.exec_cmd(script("special-toggle.sh") .. " stash"))
hl.bind(mod .. " + ALT + P",            hl.dsp.workspace.toggle_special("private"))
hl.bind("CTRL + " .. mod .. " + P",     hl.dsp.exec_cmd(script("special-toggle.sh") .. " private"))
hl.bind(mod .. " + M",                  hl.dsp.exec_cmd(script("minimize-toggle.sh")))
hl.bind("CTRL + " .. mod .. " + M",     hl.dsp.workspace.toggle_special("minimized"))

-- ── Screen ─────────────────────────────────────────────────────────────────
hl.bind(mod .. " + Minus",   zoom(-0.3), { repeating = true })
hl.bind(mod .. " + Equal",   zoom( 0.3), { repeating = true })
hl.bind(mod .. " + ALT + T", hl.dsp.exec_cmd(HOME .. "/.local/bin/toggle-touchscreen"))

-- ── Utilities ──────────────────────────────────────────────────────────────
hl.bind(mod .. " + Space",       hl.dsp.exec_cmd(script("open-surface.sh") .. " launcher"))
hl.bind(mod .. " + V",           hl.dsp.exec_cmd(script("open-surface.sh") .. " clipboard"))
hl.bind(mod .. " + SHIFT + C",   hl.dsp.exec_cmd("hyprpicker -a"))

-- Region snip to clipboard. hyprshot when present, otherwise grim+slurp, which
-- is what the old bind fell back to once the ii shell was not answering.
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(
    "pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent "
    .. "|| grim -g \"$(slurp)\" - | wl-copy"))

hl.bind("Print", hl.dsp.exec_cmd(
    "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" - | wl-copy"),
    { locked = true })

hl.bind("CTRL + Print", hl.dsp.exec_cmd(
    "mkdir -p \"$(xdg-user-dir PICTURES)/Screenshots\" && "
    .. "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" "
    .. "\"$(xdg-user-dir PICTURES)/Screenshots/Screenshot_$(date '+%Y-%m-%d_%H.%M.%S').png\""),
    { locked = true, non_consuming = true })

hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd(script("record.sh")), { locked = true })
hl.bind(mod .. " + ALT + R",   hl.dsp.exec_cmd(script("record.sh")), { locked = true })
hl.bind(mod .. " + G",         hl.dsp.exec_cmd(script("open-surface.sh") .. " gameMode"))

-- ── Wallpaper ──────────────────────────────────────────────────────────────
hl.bind(mod .. " + B",              hl.dsp.exec_cmd(script("wallpaper.sh")))
hl.bind("CTRL + " .. mod .. " + T", hl.dsp.exec_cmd(script("open-surface.sh") .. " wallpaper"))

-- ── Session ────────────────────────────────────────────────────────────────
hl.bind(mod .. " + L",         hl.dsp.exec_cmd(script("lock.sh")))
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("CTRL + SHIFT + ALT + " .. mod .. " + Delete", hl.dsp.exec_cmd("systemctl poweroff"))

-- ── Media ──────────────────────────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),         { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",        hl.dsp.global("quickshell:mediaToggle"), { locked = true })
hl.bind("XF86AudioNext",        hl.dsp.global("quickshell:mediaNext"),   { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.global("quickshell:mediaPrev"),   { locked = true })

hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind(mod .. " + ALT + M",   hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),     { locked = true })
