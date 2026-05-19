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
    implicitHeight: card.implicitHeight + Appearance.sizes.elevationMargin

    property string draft: ""
    readonly property var notes: Persistent.states.sidebar.notes.items ?? []

    function addNote(): void {
        const text = draft.trim()
        if (text.length === 0) return

        const next = [{
            "id": Date.now().toString(),
            "text": text,
            "createdAt": Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss")
        }, ...notes]

        Persistent.states.sidebar.notes.items = next
        draft = ""
        noteInput.text = ""
        noteInput.focus = false
    }

    function deleteNote(noteId: string): void {
        Persistent.states.sidebar.notes.items = notes.filter(note => note.id !== noteId)
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

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: "edit_note"
                    iconSize: 20
                    color: Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Notes")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
                }

                StyledText {
                    text: `${root.notes.length}`
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                radius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
                color: Appearance.inirEverywhere ? Appearance.inir.colLayer2 : Appearance.colors.colLayer1
                border.width: noteInput.activeFocus ? 1 : 0
                border.color: Appearance.inirEverywhere ? Appearance.inir.colBorderFocus : Appearance.colors.colPrimary

                TextArea {
                    id: noteInput
                    anchors.fill: parent
                    anchors.margins: 8
                    text: root.draft
                    placeholderText: Translation.tr("Write a quick note...")
                    wrapMode: TextEdit.Wrap
                    renderType: Text.NativeRendering
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.main
                    color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
                    placeholderTextColor: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colOutline
                    background: null
                    padding: 0

                    onTextChanged: root.draft = text

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Return && event.modifiers & Qt.ControlModifier) {
                            root.addNote()
                            event.accepted = true
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Ctrl+Enter to save")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
                }

                RippleButton {
                    implicitWidth: 34
                    implicitHeight: 30
                    buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
                    colBackground: root.draft.trim().length > 0
                        ? (Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary)
                        : "transparent"
                    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colPrimaryHover : Appearance.colors.colPrimaryHover
                    colRipple: Appearance.inirEverywhere ? Appearance.inir.colPrimaryActive : Appearance.colors.colPrimaryActive
                    onClicked: root.addNote()

                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "add"
                            iconSize: 18
                            color: root.draft.trim().length > 0
                                ? (Appearance.inirEverywhere ? Appearance.inir.colOnPrimary : Appearance.colors.colOnPrimary)
                                : (Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext)
                        }
                    }
                    StyledToolTip { text: Translation.tr("Save note") }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.notes.length > 0

                Repeater {
                    model: root.notes.slice(0, 5)

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: noteRow.implicitHeight + 14
                        radius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
                        color: Appearance.inirEverywhere ? Appearance.inir.colLayer2 : Appearance.colors.colLayer1

                        RowLayout {
                            id: noteRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 8
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.text
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.createdAt ?? ""
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
                                }
                            }

                            RippleButton {
                                implicitWidth: 28
                                implicitHeight: 28
                                buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.full
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover : Appearance.colors.colLayer2Hover
                                colRipple: Appearance.inirEverywhere ? Appearance.inir.colLayer2Active : Appearance.colors.colLayer2Active
                                onClicked: root.deleteNote(modelData.id)

                                contentItem: Item {
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "delete_outline"
                                        iconSize: 16
                                        color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
                                    }
                                }
                                StyledToolTip { text: Translation.tr("Delete note") }
                            }
                        }
                    }
                }
            }
        }
    }
}
