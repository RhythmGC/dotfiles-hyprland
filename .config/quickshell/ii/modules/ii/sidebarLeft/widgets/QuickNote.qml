pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "root:"

Item {
    id: root
    implicitHeight: card.implicitHeight

    property bool editing: false
    property string draft: ""
    property var currentDate: new Date()
    property string currentDateString: Qt.formatDate(currentDate, "yyyy-MM-dd")
    property string displayDateString: Qt.formatDate(currentDate, "MMM dd, yyyy")

    // Retrieve note for current date from config
    property string savedNote: Config.options?.calendar_notes?.[currentDateString] ?? ""

    function changeDate(days) {
        let d = new Date(currentDate)
        d.setDate(d.getDate() + days)
        currentDate = d
        if (editing) {
            editing = false
            textArea.focus = false
        }
    }

    function saveNote(text) {
        Config.setNestedValue("calendar_notes." + currentDateString, text)
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (!GlobalStates.sidebarLeftOpen && root.editing) {
                root.editing = false
                textArea.focus = false
            }
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        implicitHeight: col.implicitHeight + 16
        radius: Appearance.angelEverywhere ? Appearance.angel.roundingNormal
            : Appearance.inirEverywhere ? Appearance.inir.roundingNormal
            : Appearance.rounding.normal
        color: "transparent"

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                MaterialSymbol {
                    text: "calendar_month"
                    iconSize: 16
                    color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
                }

                Item { Layout.fillWidth: true }

                RippleButton {
                    implicitWidth: 24; implicitHeight: 24
                    buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer2Hover
                    colRipple: Appearance.inirEverywhere ? Appearance.inir.colLayer2Active
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colors.colLayer2Active
                    onClicked: changeDate(-1)
                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_left"
                            iconSize: 16
                            color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
                        }
                    }
                }

                StyledText {
                    text: root.displayDateString
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
                    Layout.alignment: Qt.AlignCenter
                }

                RippleButton {
                    implicitWidth: 24; implicitHeight: 24
                    buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer2Hover
                    colRipple: Appearance.inirEverywhere ? Appearance.inir.colLayer2Active
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colors.colLayer2Active
                    onClicked: changeDate(1)
                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_right"
                            iconSize: 16
                            color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
                        }
                    }
                }

                RippleButton {
                    implicitWidth: 24; implicitHeight: 24
                    buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer2Hover
                    colRipple: Appearance.inirEverywhere ? Appearance.inir.colLayer2Active
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colors.colLayer2Active
                    opacity: root.savedNote.trim() !== "" ? 1 : 0
                    visible: opacity > 0
                    onClicked: saveNote("")

                    Behavior on opacity {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                    }

                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "delete_outline"
                            iconSize: 14
                            color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
                        }
                    }
                    StyledToolTip { text: Translation.tr("Clear note") }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(120, Math.max(60, textArea.implicitHeight + 12))
                radius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
                color: Appearance.inirEverywhere 
                    ? (root.editing ? Appearance.inir.colLayer2Hover : Appearance.inir.colLayer2)
                    : (root.editing ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)
                border.width: Appearance.inirEverywhere ? 1 : (root.editing ? 2 : 0)
                border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder : Appearance.colors.colPrimary

                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 6
                    contentHeight: textArea.implicitHeight
                    clip: true

                    TextArea {
                        id: textArea
                        width: parent.width
                        text: root.editing ? root.draft : root.savedNote
                        placeholderText: Translation.tr("Note for ") + root.displayDateString + "..."
                        renderType: Text.NativeRendering
                        wrapMode: TextEdit.Wrap
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.family: Appearance.font.family.main
                        color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer2
                        placeholderTextColor: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colOutline
                        background: null
                        padding: 0

                        onActiveFocusChanged: {
                            if (activeFocus) {
                                root.draft = root.savedNote
                                root.editing = true
                            }
                        }

                        onTextChanged: {
                            if (root.editing) root.draft = text
                        }

                        Keys.onEscapePressed: {
                            root.editing = false
                            focus = false
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return && event.modifiers & Qt.ControlModifier) {
                                saveNote(root.draft)
                                root.editing = false
                                focus = false
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                opacity: root.editing ? 1 : 0
                visible: opacity > 0
                spacing: 4

                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }

                StyledText {
                    text: root.draft.length > 0 ? `${root.draft.length} ${Translation.tr("chars")}` : Translation.tr("Ctrl+Enter to save")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colOutline
                }

                Item { Layout.fillWidth: true }

                // Cancel button
                RippleButton {
                    implicitWidth: 24; implicitHeight: 24
                    buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer2Hover
                    colRipple: Appearance.inirEverywhere ? Appearance.inir.colLayer2Active
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colors.colLayer2Active
                    onClicked: {
                        root.draft = root.savedNote
                        root.editing = false
                        textArea.focus = false
                    }

                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 14
                            color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
                        }
                    }

                    StyledToolTip { text: Translation.tr("Cancel") }
                }

                // Save button
                RippleButton {
                    implicitWidth: saveRow.implicitWidth + 12
                    implicitHeight: 24
                    buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
                    colBackground: Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colPrimaryHover : Appearance.colors.colPrimaryHover
                    colRipple: Appearance.inirEverywhere ? Appearance.inir.colPrimaryActive : Appearance.colors.colPrimaryActive
                    onClicked: {
                        saveNote(root.draft)
                        root.editing = false
                        textArea.focus = false
                    }

                    contentItem: RowLayout {
                        id: saveRow
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialSymbol {
                            text: "check"
                            iconSize: 12
                            color: Appearance.inirEverywhere ? Appearance.inir.colOnPrimary : Appearance.colors.colOnPrimary
                        }

                        StyledText {
                            text: Translation.tr("Save")
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.inirEverywhere ? Appearance.inir.colOnPrimary : Appearance.colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }
}
