pragma ComponentBehavior: Bound
import qs
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: actionsGrid.implicitHeight + 16
    readonly property bool compactMode: Config.options?.controlPanel?.compactMode ?? true
    
    readonly property bool baEverywhere: Appearance.baEverywhere
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere

    radius: Appearance.angelEverywhere ? Appearance.angel.roundingNormal
        : baEverywhere ? Appearance.ba.roundingNormal : Appearance.rounding.normal
    color: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
         : baEverywhere ? Appearance.ba.colLayer1
         : auroraEverywhere ? Appearance.aurora.colSubSurface
         : Appearance.colors.colLayer1
    border.width: Appearance.angelEverywhere ? 0 : (baEverywhere ? 1 : 0)
    border.color: Appearance.angelEverywhere ? "transparent"
        : baEverywhere ? Appearance.ba.colBorder : "transparent"

    AngelPartialBorder { targetRadius: parent.radius; coverage: 0.45 }

    GridLayout {
        id: actionsGrid
        anchors.fill: parent
        anchors.margins: root.compactMode ? 6 : 8
        columns: 4
        rowSpacing: root.compactMode ? 4 : 6
        columnSpacing: root.compactMode ? 4 : 6

        // Row 1: Audio
        ActionTile {
            icon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
            active: !(Audio.sink?.audio?.muted ?? false)
            onClicked: Audio.toggleMute()
        }

        ActionTile {
            icon: Audio.micMuted ? "mic_off" : "mic"
            active: !Audio.micMuted
            onClicked: Audio.toggleMicMute()
        }

        ActionTile {
            icon: "notifications"
            active: !Notifications.silent
            onClicked: Notifications.silent = !Notifications.silent
        }

        ActionTile {
            icon: "dark_mode"
            active: Appearance.m3colors.darkmode
            onClicked: Appearance.toggleDarkMode()
        }

        // Row 2: Connectivity & System
        ActionTile {
            icon: Network.wifiEnabled ? "wifi" : "wifi_off"
            active: Network.wifiEnabled
            onClicked: Network.toggleWifi()
        }

        ActionTile {
            visible: BluetoothStatus.available
            icon: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            active: BluetoothStatus.enabled
            onClicked: BluetoothStatus.toggle()
        }

        ActionTile {
            icon: "coffee"
            active: Idle.inhibit
            onClicked: Idle.toggleInhibit()
        }

        ActionTile {
            icon: "sports_esports"
            active: GameMode.active
            onClicked: GameMode.toggle()
        }

        // Row 3: Tools
        ActionTile {
            icon: "screenshot_monitor"
            onClicked: {
                GlobalStates.controlPanelOpen = false
                GlobalStates.regionSelectorOpen = true
            }
        }

        ActionTile {
            icon: "settings"
            onClicked: {
                GlobalStates.controlPanelOpen = false
                Quickshell.execDetached([Quickshell.shellPath("scripts/ba"), "settings"])
            }
        }

        ActionTile {
            icon: "lock"
            onClicked: {
                GlobalStates.controlPanelOpen = false
                Quickshell.execDetached([Quickshell.shellPath("scripts/ba"), "lock", "activate"])
            }
        }

        ActionTile {
            icon: "power_settings_new"
            iconColor: Appearance.angelEverywhere ? Appearance.m3colors.m3error
                     : root.baEverywhere ? Appearance.ba.colError
                     : root.auroraEverywhere ? Appearance.m3colors.m3error
                     : Appearance.colors.colError
            onClicked: {
                GlobalStates.controlPanelOpen = false
                GlobalStates.sessionOpen = true
            }
        }
    }

    component ActionTile: Rectangle {
        id: tile
        property string icon
        property bool active: false
        property color iconColor: active 
            ? (Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
             : root.baEverywhere ? Appearance.ba.colOnPrimary
             : root.auroraEverywhere ? Appearance.m3colors.m3onPrimary
             : Appearance.colors.colOnPrimary)
            : (Appearance.angelEverywhere ? Appearance.angel.colText
             : root.baEverywhere ? Appearance.ba.colText
             : root.auroraEverywhere ? Appearance.m3colors.m3onSurface
             : Appearance.colors.colOnLayer1)
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: root.compactMode ? 30 : 36
        radius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
            : root.baEverywhere ? Appearance.ba.roundingSmall : Appearance.rounding.small
        
        color: tileMouseArea.containsMouse 
            ? (active 
                ? (Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimaryHover, 0.35)
                 : root.baEverywhere ? Appearance.ba.colPrimaryHover
                 : root.auroraEverywhere ? Appearance.colors.colPrimaryHover
                 : Appearance.colors.colPrimaryHover)
                : (Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
                 : root.baEverywhere ? Appearance.ba.colLayer2Hover
                 : root.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover
                 : Appearance.colors.colLayer2Hover))
            : (active 
                ? (Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimary, 0.45)
                 : root.baEverywhere ? Appearance.ba.colPrimary
                 : root.auroraEverywhere ? Appearance.m3colors.m3primary
                 : Appearance.colors.colPrimary)
                : (Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                 : root.baEverywhere ? Appearance.ba.colLayer2
                 : root.auroraEverywhere ? Appearance.aurora.colSubSurface
                 : Appearance.colors.colLayer2))

        border.width: Appearance.angelEverywhere ? 0 : (root.baEverywhere ? 1 : 0)
        border.color: Appearance.angelEverywhere ? "transparent"
            : root.baEverywhere ? (active ? Appearance.ba.colPrimary : Appearance.ba.colBorderSubtle) : "transparent"

        AngelPartialBorder { targetRadius: parent.radius; coverage: 0.4; borderColor: active ? Appearance.angel.colPrimary : Appearance.angel.colBorderSubtle }

        Behavior on color {
            enabled: Appearance.animationsEnabled
            animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: tile.icon
            iconSize: root.compactMode ? 16 : 18
            color: tile.iconColor

            Behavior on color {
                enabled: Appearance.animationsEnabled
                animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
            }
        }

        MouseArea {
            id: tileMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }
}
