import QtQuick
import QtQuick.Layouts
import qs.modules.common

ToolbarButton {
    id: iconBtn
    implicitWidth: height

    colBackgroundToggled: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.baEverywhere ? Appearance.ba.colSelection
        : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurface 
        : Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.baEverywhere ? Appearance.ba.colSelectionHover
        : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurfaceHover 
        : Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.baEverywhere ? Appearance.ba.colPrimaryActive
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive 
        : Appearance.colors.colSecondaryContainerActive
    property color colText: toggled ? (Appearance.baEverywhere ? Appearance.ba.colOnSelection : Appearance.colors.colOnSecondaryContainer) : (Appearance.baEverywhere ? Appearance.ba.colText : Appearance.colors.colOnSurfaceVariant)

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        iconSize: 22
        text: iconBtn.text
        color: iconBtn.colText
    }
}
