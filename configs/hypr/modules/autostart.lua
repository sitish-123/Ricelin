hl.on("hyprland.start", function()
    -- Load hyprpm-managed plugins. This MUST happen out here, after the
    -- compositor is up -- never via hl.plugin.load() inside the config, which
    -- re-enters the parse (reload -> handlePluginLoads -> postConfigReload ->
    -- reload) and hard-crashes Hyprland into an unbootable SDDM loop. See
    -- modules/plugins.lua for the full story.
    hl.exec_cmd("hyprpm reload -n")

    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/cliphist-watch.sh")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper.sh init")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/watchdog.sh pill")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/watchdog.sh lock")
    hl.exec_cmd("systemctl --user restart hypridle")
    -- warm the page cache so a user's first fastfetch run doesn't stall on cold pacman db reads
    hl.exec_cmd("fastfetch")
end)
