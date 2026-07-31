pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * One shared watcher for the internal laptop backlight. Every pill carries an
 * Osd, so watching /sys here keeps it a single process instead of one per
 * monitor. `changed` fires on a new reading after the initial populate, so login
 * doesn't flash the OSD; the watcher exits at once on machines without a
 * backlight.
 *
 * The helper blocks in poll(2) on the sysfs attribute rather than re-reading it
 * on a timer, so a brightness key now flashes the OSD immediately instead of up
 * to a second later, and the shell stops paying three forks a second for it.
 */
Singleton {
    id: root

    property bool present: false
    property real brightness: 0
    property int lastPct: -1

    signal changed()

    Process {
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/backlight-watch.py"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var pct = parseInt(line.trim(), 10);
                if (isNaN(pct))
                    return;
                var seen = root.lastPct >= 0;
                root.present = true;
                root.brightness = Math.max(0, Math.min(100, pct)) / 100.0;
                root.lastPct = pct;
                if (seen)
                    root.changed();
            }
        }
    }
}
