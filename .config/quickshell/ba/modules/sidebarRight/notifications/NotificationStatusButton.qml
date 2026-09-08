import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

GroupButton {
    id: button
    property string buttonIcon: ""
    property string buttonText: ""

    baseHeight: 36
    baseWidth: content.implicitWidth + 46
    clickedWidth: baseWidth + 6

    buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.baEverywhere ? Appearance.ba.roundingSmall : baseHeight / 2
    buttonRadiusPressed: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.baEverywhere ? Appearance.ba.roundingSmall : Appearance.rounding.small
    colBackground: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.baEverywhere ? Appearance.ba.colLayer2
        : Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colLayer2
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.baEverywhere ? Appearance.ba.colLayer2Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover : Appearance.colors.colLayer2Hover
    colBackgroundActive: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.baEverywhere ? Appearance.ba.colLayer2Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colors.colLayer2Active
    property color colText: Appearance.baEverywhere
        ? (toggled ? Appearance.ba.colOnPrimaryContainer : Appearance.ba.colText)
        : (toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1)

    contentItem: Item {
        id: content
        anchors.fill: parent
        implicitWidth: contentRowLayout.implicitWidth
        implicitHeight: contentRowLayout.implicitHeight
        RowLayout {
            id: contentRowLayout
            anchors.centerIn: parent
            spacing: 5
            MaterialSymbol {
                visible: buttonIcon !== ""
                text: buttonIcon
                iconSize: Appearance.font.pixelSize.huge
                color: button.colText
            }
            StyledText {
                visible: buttonText !== ""
                text: buttonText
                font.pixelSize: Appearance.font.pixelSize.small
                color: button.colText
            }
        }
    }

}