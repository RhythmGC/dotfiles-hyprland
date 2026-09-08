import qs.modules.common
import qs.services
import QtQuick
import Quickshell.Services.Notifications

RippleButton {
    id: button
    property string buttonText
    property string urgency

    implicitHeight: 34
    leftPadding: 15
    rightPadding: 15
    buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.baEverywhere ? Appearance.ba.roundingSmall : Appearance.rounding.small
    colBackground: (urgency == NotificationUrgency.Critical) 
        ? Appearance.colors.colSecondaryContainer 
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.baEverywhere ? Appearance.ba.colLayer3
        : Appearance.auroraEverywhere ? "transparent" 
        : Appearance.colors.colLayer4
    colBackgroundHover: (urgency == NotificationUrgency.Critical) 
        ? Appearance.colors.colSecondaryContainerHover 
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.baEverywhere ? Appearance.ba.colLayer3Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface 
        : Appearance.colors.colLayer4Hover
    colRipple: (urgency == NotificationUrgency.Critical) 
        ? Appearance.colors.colSecondaryContainerActive 
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.baEverywhere ? Appearance.ba.colLayer3Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive 
        : Appearance.colors.colLayer4Active

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
    }
}