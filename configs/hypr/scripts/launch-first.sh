#!/bin/sh
# Launch the first candidate on the list that is actually installed.
#
# App binds should not break just because a machine has firefox instead of
# chromium, or micro instead of code. Each argument is a full command line;
# the first whose binary resolves is exec'd and the rest are ignored.
#
#   launch-first.sh 'code' 'micro' 'ghostty -e micro'
#
# Falls back to a notification rather than failing silently, so a dead bind
# is visible instead of looking like the key did nothing.

for cmd in "$@"; do
    [ -n "$cmd" ] || continue
    # The binary is the first word; the rest are its arguments.
    bin=${cmd%% *}
    if command -v "$bin" >/dev/null 2>&1; then
        exec sh -c "$cmd"
    fi
done

notify-send "No application found" "None of these are installed:
$(printf '  %s\n' "$@")" -a Hyprland -u critical
exit 1
