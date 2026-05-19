pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root
    implicitHeight: card.implicitHeight + Appearance.sizes.elevationMargin

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: parent.width
        implicitHeight: content.implicitHeight + 24
        radius: Appearance.angelEverywhere ? Appearance.angel.roundingNormal
            : Appearance.inirEverywhere ? Appearance.inir.roundingNormal
            : Appearance.rounding.normal
        color: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
            : Appearance.inirEverywhere ? Appearance.inir.colLayer1
            : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
            : Appearance.colors.colLayer2
        border.width: Appearance.angelEverywhere ? Appearance.angel.cardBorderWidth
            : Appearance.inirEverywhere ? 1 : 0
        border.color: Appearance.angelEverywhere ? Appearance.angel.colCardBorder
            : Appearance.inirEverywhere ? Appearance.inir.colBorder : "transparent"

        RowLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: Appearance.rounding.full
                color: Appearance.inirEverywhere ? Appearance.inir.colLayer2
                    : Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "schedule"
                    iconSize: 24
                    color: Appearance.inirEverywhere ? Appearance.inir.colPrimary
                        : Appearance.colors.colOnPrimaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: Qt.locale().toString(clock.date, "hh:mm:ss")
                    font.pixelSize: Appearance.font.pixelSize.huge * 1.25
                    font.family: Appearance.font.family.numbers
                    font.weight: Font.DemiBold
                    color: Appearance.inirEverywhere ? Appearance.inir.colText
                        : Appearance.colors.colOnLayer1
                }

                StyledText {
                    Layout.fillWidth: true
                    text: DateTime.longDate
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary
                        : Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }
        }
    }
}
