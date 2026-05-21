pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root
    implicitHeight: showTemp || showBattery ? 64 : 0

    readonly property bool showTemp: ResourceUsage.cpuTemp > 0 && (Config.options?.sidebar?.widgets?.statusRings?.showTemp ?? true)
    readonly property bool showBattery: Battery.available && (Config.options?.sidebar?.widgets?.statusRings?.showBattery ?? true)

    // Component.onCompleted: ResourceUsage.ensureRunning()
    // onVisibleChanged: if (visible) ResourceUsage.ensureRunning()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        Ring {
            icon: "thermostat"
            value: Math.min(1, ResourceUsage.maxTemp / 100)
            label: ResourceUsage.maxTemp + "°"
            ringColor: ResourceUsage.maxTemp >= 80 ? Appearance.colors.colError :
                   ResourceUsage.maxTemp >= 60 ? Appearance.colors.colTertiary :
                   Appearance.angelEverywhere ? Appearance.angel.colPrimary : Appearance.colors.colPrimary
            visible: root.showTemp
            tip: Translation.tr("Temperature")
        }

        Ring {
            icon: Battery.isCharging ? "battery_charging_full" : "battery_full"
            value: Battery.percentage
            label: Math.round(Battery.percentage * 100) + "%"
            ringColor: Battery.isCritical ? Appearance.colors.colError :
                   Battery.isCharging ? (Appearance.angelEverywhere ? Appearance.angel.colPrimary : Appearance.colors.colPrimary) :
                   Battery.percentage < 0.3 ? Appearance.colors.colTertiary :
                   Appearance.angelEverywhere ? Appearance.angel.colPrimary : Appearance.colors.colPrimary
            visible: root.showBattery
            tip: Battery.isCharging ? Translation.tr("Charging") : Translation.tr("Battery")
        }
    }

    component Ring: Item {
        property string icon
        property string label
        property string tip
        property real value
        property color ringColor: Appearance.angelEverywhere ? Appearance.angel.colPrimary : Appearance.colors.colPrimary

        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
            id: ringBg
            anchors.centerIn: parent
            width: 52
            height: 52
            radius: 26
            color: "transparent"
            border.width: 3
            border.color: Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle
                        : Appearance.inirEverywhere ? Appearance.inir.colBorderSubtle
                        : Appearance.auroraEverywhere ? "transparent" 
                        : Appearance.colors.colLayer2

            Behavior on border.color {
                enabled: Appearance.animationsEnabled
                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
            }

            Canvas {
                id: canvas
                anchors.fill: parent

                property real progressValue: value
                property color progressColor: ringColor

                onProgressValueChanged: requestPaint()
                onProgressColorChanged: requestPaint()

                Behavior on progressValue {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }

                Behavior on progressColor {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.lineWidth = 3
                    ctx.lineCap = "round"
                    ctx.strokeStyle = progressColor
                    ctx.beginPath()
                    ctx.arc(width/2, height/2, width/2 - 2, -Math.PI/2, -Math.PI/2 + 2 * Math.PI * Math.min(1, progressValue))
                    ctx.stroke()
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: -2

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: icon
                    iconSize: 14
                    color: Appearance.angelEverywhere ? Appearance.angel.colText : Appearance.colors.colOnLayer1
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: label
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.numbers
                    font.weight: Font.Medium
                    color: Appearance.angelEverywhere ? Appearance.angel.colText : Appearance.colors.colOnLayer1
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }

            StyledToolTip {
                text: tip
                extraVisibleCondition: false
                alternativeVisibleCondition: hoverArea.containsMouse && tip !== ""
            }
        }
    }
}
