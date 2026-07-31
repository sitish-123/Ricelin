#!/bin/sh
name="$1"
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/${name}-watchdog.lock"
flock -n 9 || exit 0

# Bring up a fresh instance, then wait for it to actually answer IPC before
# handing back to the liveness loop. quickshell does not guard against a second
# instance of the same config, so a slow cold start under boot load must not be
# read as a dead shell and respawned, or the duplicates stack up and fight over
# the layer surface and keyboard focus. The wait is capped so a launch that
# never comes up still falls back to the normal retry cadence.
launch() {
    qs -c "$name" -d 9>&- 2>/dev/null
    pid=""
    i=0
    while [ "$i" -lt 30 ]; do
        qs -c "$name" ipc show >/dev/null 2>&1 && return
        sleep 1
        i=$((i + 1))
    done
}

# Cheap liveness. `kill -0` is a shell builtin, so a healthy shell costs this
# loop no forks at all; pgrep runs only when the cached pid has gone stale. The
# old check ran `qs ... ipc show` every 5s instead -- around 48ms of CPU a pop,
# which across the two watchdogs burned roughly 2% of a core around the clock.
#
# Existence, not readiness, is deliberately the respawn trigger now. IPC
# readiness reads "dead" for the whole of a cold start, so anything else that
# launched the shell (the updater's restart, a hand-run `qs -c pill -d`) raced
# this loop into spawning a second copy. A process that exists is never
# respawned, so that race is gone; a wedged one is caught by the slow check
# below instead.
#
# The pattern is anchored to the start of the command line rather than being a
# bare substring: `pgrep -f "qs -c pill"` also matches any shell that merely
# mentions it, so a terminal sitting on `qs -c pill log` would read as a healthy
# shell and suppress a needed respawn. Optional leading path covers an absolute
# argv[0].
pid=""
alive() {
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && return 0
    pid=$(pgrep -f "^(|.*/)qs -c $name( |\$)" 2>/dev/null | head -n1)
    [ -n "$pid" ]
}

# A shell can be alive and still not answering, so verify properly once a
# minute. IPC is the authoritative signal: if it fails, the shell is not serving
# whatever the process table says, so kill it and go through the normal spawn
# path rather than trusting `alive` to notice on the next pass. That also keeps
# recovery working if the cheap check is ever fooled into a false positive.
ticks=0
while true; do
    if alive; then
        ticks=$((ticks + 1))
        if [ "$ticks" -ge 12 ]; then
            ticks=0
            if ! qs -c "$name" ipc show >/dev/null 2>&1; then
                qs -c "$name" kill >/dev/null 2>&1
                pid=""
                launch
            fi
        fi
    else
        ticks=0
        launch
    fi
    sleep 5
done
