import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: button

    property string buttonIcon
    property string buttonText
    property bool keyboardDown: false
    property real size: 120

    buttonRadius: (button.focus || button.down) ? size / 2 
        : (Appearance.angelEverywhere ? Appearance.angel.roundingLarge
            : Appearance.baEverywhere ? Appearance.ba.roundingLarge : Appearance.rounding.verylarge)
    colBackground: button.keyboardDown 
        ? (Appearance.baEverywhere ? Appearance.ba.colPrimaryActive : Appearance.colors.colSecondaryContainerActive)
        : button.focus 
            ? (Appearance.baEverywhere ? Appearance.ba.colPrimary : Appearance.colors.colPrimary)
            : (Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                : Appearance.baEverywhere ? Appearance.ba.colLayer2
                : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface 
                : Appearance.colors.colSecondaryContainer)
    colBackgroundHover: Appearance.baEverywhere ? Appearance.ba.colPrimaryHover : Appearance.colors.colPrimary
    colRipple: Appearance.baEverywhere ? Appearance.ba.colPrimaryActive : Appearance.colors.colPrimaryActive
    property color colText: (button.down || button.keyboardDown || button.focus || button.hovered) ?
        (Appearance.baEverywhere ? Appearance.ba.colOnPrimary : Appearance.m3colors.m3onPrimary)
        : (Appearance.baEverywhere ? Appearance.ba.colText : Appearance.colors.colOnLayer0)

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    background.implicitHeight: size
    background.implicitWidth: size

    Behavior on buttonRadius {
        animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = true
            button.clicked()
            event.accepted = true;
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = false
            event.accepted = true;
        }
    }

    contentItem: MaterialSymbol {
        id: icon
        anchors.fill: parent
        color: button.colText
        horizontalAlignment: Text.AlignHCenter
        iconSize: 45
        text: buttonIcon
    }

    StyledToolTip {
        text: buttonText
    }

}
