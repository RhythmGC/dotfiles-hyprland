pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

ContentPage {
    id: root
    settingsPageIndex: 12
    settingsPageName: Translation.tr("Compositor")

    // Hyprland Options
    HyprlandConfigOption { id: gapsInOpt; key: "general:gaps_in" }
    HyprlandConfigOption { id: gapsOutOpt; key: "general:gaps_out" }
    HyprlandConfigOption { id: borderSizeOpt; key: "general:border_size" }
    HyprlandConfigOption { id: roundingOpt; key: "decoration:rounding" }
    HyprlandConfigOption { id: shadowOpt; key: "decoration:shadow:enabled" }
    HyprlandConfigOption { id: blurOpt; key: "decoration:blur:enabled" }
    HyprlandConfigOption { id: activeOpacityOpt; key: "decoration:active_opacity" }
    HyprlandConfigOption { id: inactiveOpacityOpt; key: "decoration:inactive_opacity" }
    HyprlandConfigOption { id: sensitivityOpt; key: "input:sensitivity" }
    HyprlandConfigOption { id: followMouseOpt; key: "input:follow_mouse" }
    HyprlandConfigOption { id: tapToClickOpt; key: "input:touchpad:tap-to-click" }
    HyprlandConfigOption { id: naturalScrollOpt; key: "input:touchpad:natural_scroll" }
    HyprlandConfigOption { id: animationsOpt; key: "animations:enabled" }

    // Helper to parse CSS gap strings returned by hyprctl (e.g., "4 4 4 4")
    function parseGap(val) {
        if (val === undefined || val === null) return 0
        const str = String(val).trim()
        const parts = str.split(/\s+/)
        if (parts.length === 0) return 0
        const parsed = parseInt(parts[0])
        return isNaN(parsed) ? 0 : parsed
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: compositorIntro.implicitHeight

        ColumnLayout {
            id: compositorIntro
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 4

            StyledText {
                text: Translation.tr("Hyprland Configuration")
                font.pixelSize: Appearance.font.pixelSize.huge
                font.family: Appearance.font.family.title
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Adjust gaps, borders, decoration, pointer and animation behavior for the Hyprland compositor. Options apply immediately to the running session and persist to shellOverrides.")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
            }

            Item { Layout.preferredHeight: 4 }

            RippleButton {
                Layout.preferredHeight: 34
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    gapsInOpt.reset()
                    gapsOutOpt.reset()
                    borderSizeOpt.reset()
                    roundingOpt.reset()
                    shadowOpt.reset()
                    blurOpt.reset()
                    activeOpacityOpt.reset()
                    inactiveOpacityOpt.reset()
                    followMouseOpt.reset()
                    tapToClickOpt.reset()
                    naturalScrollOpt.reset()
                    sensitivityOpt.reset()
                    animationsOpt.reset()
                }
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    MaterialSymbol { text: "restart_alt"; iconSize: 15; color: Appearance.colors.colOnLayer1 }
                    StyledText { text: Translation.tr("Reset all settings to defaults"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                }
            }
        }
    }

    // =====================
    // LAYOUT SECTION
    // =====================
    SettingsCardSection {
        expanded: true
        icon: "grid_view"
        title: Translation.tr("Layout")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Window Gaps")
                tooltip: Translation.tr("Space between tiled windows (inner) and screen borders (outer).")

                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        text: Translation.tr("Inner gap (px)")
                        value: root.parseGap(gapsInOpt.value)
                        from: 0
                        to: 64
                        stepSize: 1
                        onValueChanged: {
                            if (gapsInOpt.value !== undefined && root.parseGap(gapsInOpt.value) !== value) {
                                gapsInOpt.setValue(value)
                            }
                        }
                    }
                    ConfigSpinBox {
                        text: Translation.tr("Outer gap (px)")
                        value: root.parseGap(gapsOutOpt.value)
                        from: 0
                        to: 64
                        stepSize: 1
                        onValueChanged: {
                            if (gapsOutOpt.value !== undefined && root.parseGap(gapsOutOpt.value) !== value) {
                                gapsOutOpt.setValue(value)
                            }
                        }
                    }
                }
            }

            SettingsDivider {}

            ContentSubsection {
                title: Translation.tr("Borders")
                tooltip: Translation.tr("Tiled window borders configuration.")

                ConfigSpinBox {
                    text: Translation.tr("Border size (px)")
                    value: borderSizeOpt.value !== undefined ? borderSizeOpt.value : 1
                    from: 0
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        if (borderSizeOpt.value !== undefined && borderSizeOpt.value !== value) {
                            borderSizeOpt.setValue(value)
                        }
                    }
                }
            }

            SettingsDivider {}

            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    gapsInOpt.reset()
                    gapsOutOpt.reset()
                    borderSizeOpt.reset()
                }
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    MaterialSymbol { text: "restart_alt"; iconSize: 15; color: Appearance.colors.colOnLayer1 }
                    StyledText { text: Translation.tr("Reset layout to defaults"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                }
            }
        }
    }

    // =====================
    // DECORATION SECTION
    // =====================
    SettingsCardSection {
        expanded: false
        icon: "texture"
        title: Translation.tr("Decoration")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Corners")
                tooltip: Translation.tr("Round window corners radius.")

                ConfigSpinBox {
                    text: Translation.tr("Rounding radius (px)")
                    value: roundingOpt.value !== undefined ? roundingOpt.value : 10
                    from: 0
                    to: 30
                    stepSize: 1
                    onValueChanged: {
                        if (roundingOpt.value !== undefined && roundingOpt.value !== value) {
                            roundingOpt.setValue(value)
                        }
                    }
                }
            }

            SettingsDivider {}

            ContentSubsection {
                title: Translation.tr("Effects")
                tooltip: Translation.tr("Visual window effects like drop shadows and background blur.")

                SettingsSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "dark_mode"
                    text: Translation.tr("Enable Drop Shadows")
                    checked: shadowOpt.value == true
                    onCheckedChanged: {
                        if (shadowOpt.value !== undefined) {
                            shadowOpt.setValue(checked ? "true" : "false")
                        }
                    }
                }

                SettingsSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "water_drop"
                    text: Translation.tr("Enable Background Blur")
                    checked: blurOpt.value == true
                    onCheckedChanged: {
                        if (blurOpt.value !== undefined) {
                            blurOpt.setValue(checked ? "true" : "false")
                        }
                    }
                }
            }

            SettingsDivider {}

            ContentSubsection {
                title: Translation.tr("Window Opacity")
                tooltip: Translation.tr("Opacity of active (focused) and inactive (unfocused) windows.")

                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        text: Translation.tr("Active Opacity (%)")
                        value: activeOpacityOpt.value !== undefined ? Math.round(activeOpacityOpt.value * 100) : 100
                        from: 10
                        to: 100
                        stepSize: 5
                        onValueChanged: {
                            if (activeOpacityOpt.value !== undefined) {
                                const floatValue = value / 100.0
                                if (Math.abs(activeOpacityOpt.value - floatValue) > 0.01) {
                                    activeOpacityOpt.setValue(floatValue)
                                }
                            }
                        }
                    }
                    ConfigSpinBox {
                        text: Translation.tr("Inactive Opacity (%)")
                        value: inactiveOpacityOpt.value !== undefined ? Math.round(inactiveOpacityOpt.value * 100) : 100
                        from: 10
                        to: 100
                        stepSize: 5
                        onValueChanged: {
                            if (inactiveOpacityOpt.value !== undefined) {
                                const floatValue = value / 100.0
                                if (Math.abs(inactiveOpacityOpt.value - floatValue) > 0.01) {
                                    inactiveOpacityOpt.setValue(floatValue)
                                }
                            }
                        }
                    }
                }
            }

            SettingsDivider {}

            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    roundingOpt.reset()
                    shadowOpt.reset()
                    blurOpt.reset()
                    activeOpacityOpt.reset()
                    inactiveOpacityOpt.reset()
                }
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    MaterialSymbol { text: "restart_alt"; iconSize: 15; color: Appearance.colors.colOnLayer1 }
                    StyledText { text: Translation.tr("Reset decoration to defaults"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                }
            }
        }
    }

    // =====================
    // INPUT SECTION
    // =====================
    SettingsCardSection {
        expanded: false
        icon: "keyboard"
        title: Translation.tr("Input & Touchpad")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Focus Behavior")
                tooltip: Translation.tr("Determines whether focus follows mouse pointer or requires clicking.")

                ConfigSelectionArray {
                    currentValue: followMouseOpt.value !== undefined ? followMouseOpt.value : 1
                    options: [
                        { displayName: Translation.tr("Click to focus"), icon: "mouse", value: 0 },
                        { displayName: Translation.tr("Focus follows mouse"), icon: "open_in_new", value: 1 }
                    ]
                    onSelected: newValue => {
                        if (followMouseOpt.value !== undefined && followMouseOpt.value !== newValue) {
                            followMouseOpt.setValue(newValue)
                        }
                    }
                }
            }

            SettingsDivider {}

            ContentSubsection {
                title: Translation.tr("Touchpad")
                tooltip: Translation.tr("Gestures and behavior for laptop touchpads.")

                SettingsSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "touchpad"
                    text: Translation.tr("Enable Tap to Click")
                    checked: tapToClickOpt.value == true
                    onCheckedChanged: {
                        if (tapToClickOpt.value !== undefined) {
                            tapToClickOpt.setValue(checked ? "true" : "false")
                        }
                    }
                }

                SettingsSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "swap_vert"
                    text: Translation.tr("Enable Natural Scrolling")
                    checked: naturalScrollOpt.value == true
                    onCheckedChanged: {
                        if (naturalScrollOpt.value !== undefined) {
                            naturalScrollOpt.setValue(checked ? "true" : "false")
                        }
                    }
                }
            }

            SettingsDivider {}

            ContentSubsection {
                title: Translation.tr("Pointer Speed")
                tooltip: Translation.tr("Mouse sensitivity from -1.0 (slowest) to 1.0 (fastest).")

                ConfigSpinBox {
                    text: Translation.tr("Sensitivity (x10)")
                    value: sensitivityOpt.value !== undefined ? Math.round(sensitivityOpt.value * 10) : 0
                    from: -10
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        if (sensitivityOpt.value !== undefined) {
                            const floatValue = value / 10.0
                            if (Math.abs(sensitivityOpt.value - floatValue) > 0.01) {
                                sensitivityOpt.setValue(floatValue)
                            }
                        }
                    }
                }
            }

            SettingsDivider {}

            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    followMouseOpt.reset()
                    tapToClickOpt.reset()
                    naturalScrollOpt.reset()
                    sensitivityOpt.reset()
                }
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    MaterialSymbol { text: "restart_alt"; iconSize: 15; color: Appearance.colors.colOnLayer1 }
                    StyledText { text: Translation.tr("Reset input to defaults"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                }
            }
        }
    }

    // =====================
    // ANIMATIONS SECTION
    // =====================
    SettingsCardSection {
        expanded: false
        icon: "animation"
        title: Translation.tr("Animations")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("General Animations")
                tooltip: Translation.tr("Toggle physics-based animations globally.")

                SettingsSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "play_circle"
                    text: Translation.tr("Enable Animations")
                    checked: animationsOpt.value == true
                    onCheckedChanged: {
                        if (animationsOpt.value !== undefined) {
                            animationsOpt.setValue(checked ? "true" : "false")
                        }
                    }
                }
            }

            SettingsDivider {}

            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    animationsOpt.reset()
                }
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    MaterialSymbol { text: "restart_alt"; iconSize: 15; color: Appearance.colors.colOnLayer1 }
                    StyledText { text: Translation.tr("Reset animations to defaults"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                }
            }
        }
    }
}
