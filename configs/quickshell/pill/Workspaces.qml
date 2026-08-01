pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "Singletons"

/**
 * Workspace dots for one monitor. No numbers, no icons. Active one is a larger
 * filled vermillion dot; the rest are small and dim, brightening on hover.
 * Clicking a dot focuses that workspace via the Hyprland-lua dispatcher. Active
 * marker tracks the monitor's live active workspace name from the Hyprland
 * model.
 *
 * The dot range unions this monitor's workspace rules ([[Workspacerules]]) with
 * the workspaces Hyprland currently has on it, so a rule-driven setup (e.g.
 * monitors.lua splitting 1-5 / 6-10 across two screens) always shows every
 * assigned dot while a workspace outside the rules (r+1 past the last ruled
 * one) still appears instead of vanishing from the strip.
 *
 * The strip itself is a fixed-width viewport (see `scrollX`): dots slide and
 * the active one centres, so the host pill keeps a constant width no matter how
 * many workspaces currently exist.
 */
Item {
    id: workspaces

    property string screenName: ""
    property real s: 1
    property real stickW: 17 * s
    property real dotW: 5 * s
    property real gap: 4 * s

    /**
     * The ids the strip draws, recomputed whenever the rules, this monitor's
     * workspaces or the active one change -- but only *published* to `range` when
     * the ids actually differ. A Repeater backed by a JS array resets its whole
     * model on any reassignment, and `activeName` is an input here, so binding
     * `range` directly rebuilt every dot delegate on every single workspace
     * switch: hover state was lost, and the active dot's width Behavior never
     * ran because a freshly built delegate starts life already at its target
     * width, so the stick snapped wide instead of growing into place.
     */
    readonly property var rangeCandidate: {
        var out = [];
        var seen = ({});
        var ruled = Workspacerules.byMonitor[screenName];
        if (ruled && ruled.length) {
            for (var r = 0; r < ruled.length; r++) {
                if (!seen[ruled[r]]) {
                    seen[ruled[r]] = true;
                    out.push(ruled[r]);
                }
            }
        }

        var wss = Hyprland.workspaces.values;
        for (var i = 0; i < wss.length; i++) {
            var w = wss[i];
            if (w.id >= 1 && w.monitor && w.monitor.name === screenName && !seen[w.id]) {
                seen[w.id] = true;
                out.push(w.id);
            }
        }
        var a = parseInt(activeName);
        if (a >= 1 && !seen[a])
            out.push(a);
        out.sort(function (x, y) { return x - y; });
        return out;
    }

    property var range: []

    function publishRange() {
        var a = rangeCandidate;
        var b = range;
        if (a.length !== b.length) {
            range = a;
            return;
        }
        for (var i = 0; i < a.length; i++) {
            if (a[i] !== b[i]) {
                range = a;
                return;
            }
        }
    }

    onRangeCandidateChanged: publishRange()
    Component.onCompleted: publishRange()

    readonly property string activeName: {
        var mons = Hyprland.monitors.values;
        for (var i = 0; i < mons.length; i++)
            if (mons[i].name === screenName)
                return mons[i].activeWorkspace ? mons[i].activeWorkspace.name : "";
        return "";
    }

    property int hoverIndex: -1

    readonly property int activeIndex: range.indexOf(parseInt(activeName))

    /**
     * How many slots the fixed viewport is cut to hold: one active stick plus
     * `visibleSlots - 1` dots. Six covers the usual spread with headroom, so the
     * strip only actually scrolls on a genuinely busy session.
     */
    property int visibleSlots: 6
    readonly property real slotPitch: dotW + gap
    readonly property real viewportW: stickW + (visibleSlots - 1) * slotPitch

    /** Row width at target layout values -- (n-1) dots and gaps plus the stick. */
    readonly property real contentW: {
        const n = range.length;
        return n <= 0 ? 0 : (n - 1) * slotPitch + (activeIndex >= 0 ? stickW : dotW);
    }

    /**
     * Centre x of a dot slot in *content* space, from target layout widths (the
     * active stick is wider). Uses the animation end values, so a focus marker
     * aimed here lands where the dot settles and doesn't chase the width
     * Behavior. Kept separate from slotCenterX because scrollX is derived from
     * it -- going through the offset version would bind scrollX to itself.
     */
    function contentCenterX(idx) {
        let x = 0;
        for (let i = 0; i < idx; i++)
            x += (i === activeIndex ? stickW : dotW) + gap;
        return x + (idx === activeIndex ? stickW : dotW) / 2;
    }

    /**
     * The strip is a fixed-width viewport that the dots slide inside, rather
     * than a row the pill sizes itself around. Hyprland garbage-collects an
     * empty workspace the moment you leave it, so a content-width strip made
     * the whole pill breathe by a slot (dotW + gap) every time you swiped off
     * a scratch workspace onto a real one -- the width jitter was tracking
     * workspace *existence*, not anything the user did.
     *
     * Under the viewport width the whole row is centred and nothing moves. Over
     * it the active dot is pulled to the centre and the row is clamped so it
     * never scrolls past either end into dead space.
     */
    readonly property real scrollTarget: {
        void workspaces.range;
        void workspaces.activeIndex;
        void workspaces.stickW;
        void workspaces.dotW;
        void workspaces.gap;
        const vw = viewportW;
        if (contentW <= vw)
            return (vw - contentW) / 2;
        const centred = vw / 2 - contentCenterX(Math.max(0, activeIndex));
        return Math.min(0, Math.max(vw - contentW, centred));
    }

    /** Bound, not readonly: `Behavior on` cannot attach to a readonly property. */
    property real scrollX: scrollTarget

    Behavior on scrollX {
        NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard }
    }

    /** Slot centre in this item's own coords, i.e. after the scroll offset. */
    function slotCenterX(idx) {
        return scrollX + contentCenterX(idx);
    }

    readonly property point activeDotPoint: {
        void workspaces.activeName;
        void workspaces.width;
        void workspaces.scrollX;
        return Qt.point(slotCenterX(Math.max(0, activeIndex)), height / 2);
    }

    implicitWidth: viewportW
    implicitHeight: row.implicitHeight

    /**
     * Clips horizontally only. Qt honours clipping when it routes input too, so
     * a viewport flush with the strip would have cropped each slot's MouseArea
     * back to the 22px dot row and thrown away the generous vertical hit area
     * those negative margins buy. Bleeding the clip 8px past top and bottom
     * keeps the targets while still cutting the dots off at the sides.
     */
    Item {
        id: viewport
        anchors.fill: parent
        anchors.topMargin: -8 * workspaces.s
        anchors.bottomMargin: -8 * workspaces.s
        clip: true

        RowLayout {
            id: row
            x: workspaces.scrollX
            anchors.verticalCenter: parent.verticalCenter
            spacing: workspaces.gap

            Repeater {
                model: workspaces.range

                delegate: Item {
                    id: slot

                    required property var modelData
                    required property int index

                    readonly property string wsName: String(modelData)
                    readonly property bool isActive: workspaces.activeName === wsName

                    Layout.preferredWidth: slot.isActive ? workspaces.stickW : workspaces.dotW
                    Layout.preferredHeight: 22 * workspaces.s
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: workspaces.dotW
                        radius: height / 2
                        color: slot.isActive ? Theme.vermLit : Theme.cream
                        opacity: slot.isActive ? 1.0 : (area.containsMouse ? 0.7 : 0.3)
                        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        anchors.leftMargin: -workspaces.gap / 2
                        anchors.rightMargin: -workspaces.gap / 2
                        anchors.topMargin: -8 * workspaces.s
                        anchors.bottomMargin: -8 * workspaces.s
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch('hl.dsp.focus({workspace="' + slot.wsName + '"})')
                        onContainsMouseChanged: {
                            if (containsMouse)
                                workspaces.hoverIndex = slot.index;
                            else if (workspaces.hoverIndex === slot.index)
                                workspaces.hoverIndex = -1;
                        }
                    }
                }
            }
        }
    }
}
