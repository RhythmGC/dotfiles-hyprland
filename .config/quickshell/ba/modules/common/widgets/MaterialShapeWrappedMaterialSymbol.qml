import QtQuick
import qs.modules.common
import qs.modules.common.widgets

MaterialShape {
    id: root
    property alias text: symbol.text
    property alias iconSize: symbol.iconSize
    property alias font: symbol.font
    property alias colSymbol: symbol.color
    property real padding: 6

    color: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.baEverywhere ? Appearance.ba.colLayer2
        : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurface
        : Appearance.colors.colSecondaryContainer
    colSymbol: Appearance.angelEverywhere ? Appearance.angel.colText
        : Appearance.baEverywhere ? Appearance.ba.colText
        : Appearance.auroraEverywhere ? Appearance.colors.colOnLayer1
        : Appearance.colors.colOnSecondaryContainer
    shape: MaterialShape.Shape.Clover4Leaf
    implicitSize: Math.max(symbol.implicitWidth, symbol.implicitHeight) + padding * 2

    MaterialSymbol {
        id: symbol
        anchors.centerIn: parent
        color: root.colSymbol
    }
}
