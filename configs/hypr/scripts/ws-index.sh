#!/usr/bin/env bash
# Positional workspace navigation: SUPER+N means "the Nth workspace that exists",
# not "the workspace whose id is N".
#
# Why: with absolute ids, workspaces are destroyed when they empty, so the set goes
# sparse (4, 7, 8) and the three navigation models disagree -- SUPER+5 would create and
# enter an empty ws 5, `r+1` would walk into the gaps, while the trackpad swipe and the
# scrolloverview carousel only ever see open workspaces. Indexing by position makes the
# keys agree with the swipe and the carousel, and nothing can land on emptiness unless
# it was asked for explicitly (`new`).
#
#   ws-index.sh focus N        focus the Nth open workspace (no-op if there are fewer)
#   ws-index.sh move N         send the active window to the Nth open workspace, no follow
#   ws-index.sh new            create + focus a fresh workspace after the last one
#   ws-index.sh movenew        send the active window to a fresh workspace after the last one
#   ws-index.sh insert left|right
#                              send the active window to a NEW workspace slotted immediately
#                              before/after the current one, so it appears next to it in the
#                              carousel rather than at the end
#
# `insert` is limited by Hyprland ordering workspaces by numeric id: slotting between two
# neighbours needs a free number between them. Between 4 and 7 there is room (5, 6); between
# 7 and 8 there is none, and the only way to make room would be renumbering every following
# workspace, which means bulk-moving windows. So a full gap falls back to appending at the
# end (right) or doing nothing but saying so (left).
#
# To keep that from biting, fresh workspaces are allocated on a step of 10 (10, 20, 30 ...)
# rather than max+1, so there is always room to insert beside them. The ids are invisible now
# that navigation is positional and the bar draws dots. The scrolloverview fork
# (~/Projects/scroll-overview) uses the same step and the same midpoint rule for its
# drag-to-insert drops, so keys and drags agree on where a new workspace lands.
#
# Note this config is parsed by Hyprland's Lua parser, so `hyprctl dispatch` takes a Lua
# expression, not the hyprlang dispatcher name -- `hyprctl dispatch workspace 4` is a
# parse error here. See modules/binds.lua for the bindings.
set -uo pipefail

# ids of open, non-special workspaces on the focused monitor, ascending.
# special workspaces have negative ids and are addressed by name, so they are excluded.
open_ids() {
    local monitor
    monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
    hyprctl -j workspaces | jq -r --arg m "$monitor" \
        '[.[] | select(.id > 0) | select(.monitor == $m)] | sort_by(.id) | .[].id'
}

nth_id() {
    local n=$1
    [[ $n -ge 1 ]] || return 1
    open_ids | sed -n "${n}p"
}

# Next free id on a step of 1000 above the highest in use, so a fresh workspace lands at the end of
# the carousel (not backfilling a gap, which is what `workspace empty` would do) and leaves a wide
# numeric gap either side. Every insert takes the midpoint of a gap, so the gap halves each time:
# a step of 10 gave only ~3 inserts in one spot before refusing, 1000 gives ~10 and each of those
# subgaps still supports more. Ids are invisible -- navigation is positional and the bar draws dots.
next_id() {
    hyprctl -j workspaces | jq -r '[.[] | select(.id > 0) | .id] | (max // 0) | (. - (. % 1000)) + 1000'
}

# Renumber the open workspaces to 1000, 2000, 3000 ... preserving their order, so every gap has nine
# free numbers and an insert between any two cards is always possible. Runs in two phases via a
# scratch range so a target id can never collide with a workspace that has not moved yet.
# Windows are moved in their existing order, which preserves the tiling layout.
respace() {
    local ids=() id i target
    while read -r id; do ids+=("$id"); done < <(open_ids)
    [[ ${#ids[@]} -gt 0 ]] || return 0

    local restore
    restore=$(hyprctl -j activeworkspace | jq -r .id)

    # phase 1: park everything above any id we might want to use
    for i in "${!ids[@]}"; do
        move_workspace_windows "${ids[$i]}" $((900 + i))
    done

    # phase 2: down onto the spaced ids
    for i in "${!ids[@]}"; do
        target=$(( (i + 1) * 1000 ))
        move_workspace_windows $((900 + i)) "$target"
        [[ ${ids[$i]} == "$restore" ]] && restore=$target
    done

    hyprctl dispatch "hl.dsp.focus({ workspace = $restore })" >/dev/null
}

# Move every window of $1 onto $2 without following. Ordered by on-screen position, because a
# tiling layout appends each arriving window: feeding them in hyprctl's arbitrary order swaps
# left/right neighbours (observed on a two-window workspace during the first respace).
move_workspace_windows() {
    local from=$1 to=$2 addr
    [[ $from == "$to" ]] && return 0

    while read -r addr; do
        [[ -n $addr ]] || continue
        hyprctl dispatch "hl.dsp.window.move({ window = \"address:$addr\", workspace = $to, follow = false })" >/dev/null
    done < <(hyprctl -j clients | jq -r --argjson w "$from" \
        '[.[] | select(.workspace.id == $w)] | sort_by(.at[0], .at[1]) | .[].address')
}

case "${1:-}" in
    respace)
        respace
        ;;

    focus)
        id=$(nth_id "${2:-0}") || exit 0
        [[ -n $id ]] || exit 0
        hyprctl dispatch "hl.dsp.focus({ workspace = $id })" >/dev/null
        ;;

    move)
        id=$(nth_id "${2:-0}") || exit 0
        [[ -n $id ]] || exit 0
        hyprctl dispatch "hl.dsp.window.move({ workspace = $id, follow = false })" >/dev/null
        ;;

    new)
        hyprctl dispatch "hl.dsp.focus({ workspace = $(next_id) })" >/dev/null
        ;;

    movenew)
        # follow = true: a window alone on a brand new workspace is invisible otherwise
        hyprctl dispatch "hl.dsp.window.move({ workspace = $(next_id), follow = true })" >/dev/null
        ;;

    insert)
        cur=$(hyprctl -j activeworkspace | jq -r .id)
        [[ $cur -ge 1 ]] || exit 0

        case "${2:-right}" in
            right)
                # first free id after the current workspace, stopping at the next one in use
                neighbour=$(open_ids | awk -v c="$cur" '$1 > c { print $1; exit }')
                if [[ -n $neighbour ]]; then
                    target=$(( cur + (neighbour - cur) / 2 ))   # midpoint, leaves room both sides
                else
                    target=$(next_id)
                fi
                if [[ -n $neighbour && $target -le $cur ]]; then
                    target=$(next_id)
                    notify-send -t 3000 "No room to insert" \
                        "Workspaces $cur and $neighbour are numerically adjacent; the window went to a new workspace at the end instead." \
                        -a Hyprland 2>/dev/null || true
                fi
                ;;
            left)
                neighbour=$(open_ids | awk -v c="$cur" '$1 < c { n = $1 } END { if (n) print n }')
                if [[ -n $neighbour ]]; then
                    target=$(( neighbour + (cur - neighbour) / 2 ))
                else
                    target=$(( cur > 1000 ? cur - 1000 : cur - 1 ))
                fi
                if [[ $target -lt 1 || $target -ge $cur || ( -n $neighbour && $target -le $neighbour ) ]]; then
                    notify-send -t 3000 "No room to insert" \
                        "There is no free workspace number before $cur, so nothing moved." \
                        -a Hyprland 2>/dev/null || true
                    exit 0
                fi
                ;;
            *)
                echo "usage: ws-index.sh insert {left|right}" >&2
                exit 1
                ;;
        esac

        hyprctl dispatch "hl.dsp.window.move({ workspace = $target, follow = true })" >/dev/null
        ;;

    *)
        echo "usage: ws-index.sh {focus N|move N|new|movenew|insert left|insert right}" >&2
        exit 1
        ;;
esac
