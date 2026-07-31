#!/usr/bin/env python3
"""Emit the internal backlight level, as a percent, whenever it changes.

Prints one integer per line on stdout: the current level immediately, then a new
line on every change. Exits 0 and silently on machines with no backlight, so the
caller can treat "no output, clean exit" as "no internal display to track".

This replaces a `while true; cat brightness; sleep 1; done` shell loop, which
cost three forks a second forever (the subshell, the cat, the sleep) and left
the brightness OSD up to a second behind the key that triggered it.

The trick is that sysfs supports poll(2) on backlight attributes -- but on
`actual_brightness`, not `brightness`. The kernel's sysfs store path calls
sysfs_notify() for actual_brightness only, so poll() on `brightness` never wakes
(verified on intel_backlight: it sat through a change and timed out). Watching
the right attribute makes this fully event-driven: no forks, no wakeups, and the
OSD appears on the same frame as the change.

POLLPRI is the sysfs change signal. It stays raised until the file is read to
EOF, which is why every loop seeks back to 0 and re-reads before polling again --
skip that and poll() returns instantly forever.

A generous timeout is kept as a backstop so a driver that exposes the attribute
but never notifies still converges, instead of the level freezing permanently.
It doubles as the liveness tick for the parent check below.

Exiting when reparented matters more here than it looks. The shell that owns
this does not always take its children down with it -- a crash, or the updater's
restart, leaves the watcher running under init -- and every restart then strands
another copy. That was survivable when this was a `sh` loop; at ~14MB of Python
apiece it is not.
"""

import glob
import os
import select
import sys

# Long enough to be irrelevant on a driver that notifies properly, short enough
# that one which does not still tracks roughly.
FALLBACK_TIMEOUT_MS = 5000


def read_int(path):
    try:
        with open(path) as f:
            return int(f.read().strip())
    except (OSError, ValueError):
        return None


def main():
    devices = sorted(glob.glob("/sys/class/backlight/*"))
    if not devices:
        return 0
    device = devices[0]

    maximum = read_int(os.path.join(device, "max_brightness"))
    if not maximum or maximum <= 0:
        return 0

    # actual_brightness is the one the kernel notifies on; brightness is the
    # write-side attribute and is only a fallback for drivers lacking it.
    path = os.path.join(device, "actual_brightness")
    if not os.path.exists(path):
        path = os.path.join(device, "brightness")

    try:
        handle = open(path)
    except OSError:
        return 0

    poller = select.poll()
    poller.register(handle.fileno(), select.POLLPRI | select.POLLERR)

    parent = os.getppid()
    last = None
    while True:
        # Reparented to init: the shell that wanted these readings is gone.
        if os.getppid() != parent:
            return 0

        handle.seek(0)
        try:
            value = int(handle.read().strip())
        except (OSError, ValueError):
            value = None

        if value is not None:
            percent = max(0, min(100, value * 100 // maximum))
            if percent != last:
                last = percent
                print(percent, flush=True)

        poller.poll(FALLBACK_TIMEOUT_MS)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
    except BrokenPipeError:
        # The shell went away; nothing to report to.
        sys.exit(0)
