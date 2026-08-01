<div align="center">

# Ricelin

**My Hyprland setup on CachyOS. The whole shell is hand-written Quickshell.**

![Ricelin desktop](assets/hero.png)

</div>

> This is my personal fork of [**Gakuseei/Ricelin**](https://github.com/Gakuseei/Ricelin).
> Ricelin — the shell, the pill, the whole design — is Gakuseei's work; go star the
> [upstream repo](https://github.com/Gakuseei/Ricelin) and [buy them a coffee](https://ko-fi.com/gakuseei).
> This fork just adapts it to my machine: I migrated my keybinds and workflow over
> from an earlier *illogical-impulse* (ii) setup, swapped a few defaults, and wired in a
> forked overview plugin. If you want the real thing, install from upstream, not here.

## The shell

Everything you see is hand-written Quickshell. One pill bar that morphs into whatever surface I need.

![The pill surfaces](assets/shell.png)

The pill becomes media and now playing, a calendar, the wallpaper picker, clipboard history, an audio and brightness mixer, and network and bluetooth controls. There is also an app launcher, a lock screen, and [rishot](https://github.com/Gakuseei/rishot), Gakuseei's screenshot and annotation tool, which lives in its own repo so you can read all of it there.

## Stack

- WM: Hyprland, configured in Lua
- Shell UI: custom Quickshell
- Terminal: kitty
- Browser: Zen
- Shell: fish
- Font: JetBrains Mono Nerd
- Colors: matugen, palette pulled from the wallpaper
- Overview: [scrolloverview](https://github.com/sitish-kumar/hyprland-scroll-overview) — my fork of [yayuuu/hyprland-scroll-overview](https://github.com/yayuuu/hyprland-scroll-overview), adding a continuous `navigate` swipe gesture

matugen pulls a palette from each wallpaper and recolors the pill, terminal, window borders and fastfetch. The shell itself runs a warm vermilion theme tuned by hand.

<div align="center">

![the palette is pulled from the wallpaper](assets/wallust.gif)

![Wallpaper retheme](assets/retheme.gif)

</div>

## What this fork changes

Upstream Ricelin is the whole rice. On top of it, this fork:

- **Ports my ii keybinds** — `modules/binds.lua` merges Ricelin's binds with the ones
  carried over from my old *illogical-impulse* setup; where they collided the ported bind won.
- **Positional workspaces** — `SUPER+N` goes to the *Nth workspace that exists*, so the keys,
  the trackpad swipe and the overview carousel all agree instead of stepping into numeric gaps.
- **Forked overview plugin** — the installer builds
  [sitish-kumar/hyprland-scroll-overview](https://github.com/sitish-kumar/hyprland-scroll-overview)
  (a fork of yayuuu's) through hyprpm, and `modules/plugins.lua` registers its extra gesture.
- **Default apps** — kitty as the terminal, Zen as the browser (with fallbacks so a bind still
  works on a box that has something else installed).
- **Trackpad gestures** — 4-finger workspace swipe, 3-finger window move, tuned friction.
- **Assorted fixes** — lock before the lid suspends, quieter idle loops, cheaper pill redraws.

## Install

> [!WARNING]
> This is a personal fork wired to my hardware and habits. The installer neutralises the
> obvious hardware-specific bits, but read `install.sh` first and keep backups. For the
> maintained, general-purpose version, install from
> [upstream](https://github.com/Gakuseei/Ricelin) instead.

One line, straight through the pipe:

```sh
curl -fsSL https://raw.githubusercontent.com/sitish-kumar/Ricelin/main/install.sh | bash
```

`install.sh` is a thin bootstrap: it detects your distro (Arch, Debian, Fedora or
openSUSE), makes sure git and python3 are there, clones the rice into
`~/.local/share/ricelin`, then hands off to the guided Python installer. That part
walks you through a short wizard, picks the right package names for your distro,
pulls the deps and copies the configs into `~/.config`, backing up anything it
replaces. It also builds the forked overview plugin through hyprpm. The monitor
layout and GPU env are swapped for portable defaults so it boots on any hardware;
my own layout is kept next to it as `monitors.lua.example`. Then start `Hyprland`
from a TTY.

Skip the wizard with flags, passed straight through the pipe:

```sh
curl -fsSL https://raw.githubusercontent.com/sitish-kumar/Ricelin/main/install.sh | bash -s -- --quickstart
```

```
--quickstart  core defaults, no questions
--full        also install the daily apps (dolphin, keepassxc, zathura, imv, rnote)
--sddm        also install the torii SDDM login theme
--no-deps     skip the package step, just deploy the configs
--dry-run     walk the whole flow and change nothing
```

Once installed, update in place with `ricelin update` (or Settings > Updates in the
pill) — it pulls this fork and keeps your protected files. Re-run the one-liner with
`--reinstall` to force the wizard again.

Ricelin is a Hyprland shell. On Niri, Sway or anything else only rishot (the
screenshot tool) makes sense; grab it from [rishot](https://github.com/Gakuseei/rishot)'s own installer.

### Migrating from another Hyprland setup

The installer backs up anything it replaces: `~/.config/hypr`, `quickshell`, `kitty`
and friends move to `<name>.bak` before Ricelin's copies go in. Symlinked configs are
moved aside as-is, not written through, so an existing symlinked dotfiles repo is left
untouched. Your own state — pill settings, wallpaper, calendar, screen vibrance — lives
in `~/.local/state/ricelin/`, which the installer never touches.

- **Conflicting overview plugins are turned off for you.** Ricelin enables its own
  overview plugin through hyprpm and disables known conflicts a previous setup left on
  (e.g. `hyprtasking` from an ii setup), so you don't end up loading two at once. Nothing
  is removed — re-enable one any time with `hyprpm enable <name> && hyprpm reload -n`.
- **Configs Ricelin doesn't manage are left as they were** — a leftover `~/.config/matugen`
  or `~/.config/illogical-impulse` from an ii setup, for instance. Ricelin drives matugen
  through the CLI and ignores those directories, so they're harmless, but you can delete
  them once everything looks right.

Roll back at any time with `ricelin uninstall`, which restores the `.bak` originals.

## Keybinds

`SUPER` is the mod. App launches fall back through a list, so a bind still works on a
box with different apps installed.

| Key | Action |
|---|---|
| `Super` + `Return` / `T` | terminal (kitty) |
| `Super` + `Space` | app launcher |
| `Super` + `W` | browser (Zen) |
| `Super` + `E` | file manager |
| `Super` + `C` | code editor |
| `Super` + `X` | text editor |
| `Super` + `V` | clipboard history |
| `Super` + `B` | shuffle wallpaper and retheme |
| `Ctrl` + `Super` + `T` | wallpaper picker |
| `Super` + `Q` | close window |
| `Super` + `F` / `D` | fullscreen / maximize |
| `Super` + `Alt` + `Space` | toggle floating |
| `Super` + `1`–`0` | Nth existing workspace (positional) |
| `Super` + `N` | new workspace at the end |
| `Ctrl` + `Super` + `O` | toggle overview (or 4-finger swipe up) |
| `Super` + `S` | stash (scratchpad) |
| `Super` + `L` | lock |
| `Super` + `Shift` + `S` | region snip to clipboard |
| `Print` | screenshot active output to clipboard |

## Notes

These started as Gakuseei's dotfiles; I forked them and bent the hardware-specific bits
and keybinds around my own machine. Some paths and choices still lean on how I run things,
so read before you borrow.

## Credits

Ricelin is created and maintained by **[Gakuseei](https://github.com/Gakuseei)** — this
is a fork of their [Ricelin](https://github.com/Gakuseei/Ricelin). If it made your setup
nicer, [buy Gakuseei a coffee on Ko-fi](https://ko-fi.com/gakuseei).

The lock screen, the SDDM background and the wallpapers are not mine or Gakuseei's — see
[CREDITS](configs/sddm/themes/torii/CREDITS.md). The overview plugin is my fork of
[yayuuu/hyprland-scroll-overview](https://github.com/yayuuu/hyprland-scroll-overview).
</content>
</invoke>
