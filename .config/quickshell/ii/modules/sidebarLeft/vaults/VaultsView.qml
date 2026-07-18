import qs
import qs.services.deferred
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string editingName: ""
    property bool revealValues: false
    property bool revealInput: false
    property bool formOpen: false
    readonly property var variables: KeyringStorage.keyringData?.environmentVariables ?? ({})
    readonly property var variableNames: Object.keys(root.variables).sort()
    readonly property bool validName: /^[A-Za-z_][A-Za-z0-9_]*$/.test(popupNameInput.text.trim())

    function resetForm() {
        root.editingName = ""
        popupDisplayNameInput.text = ""
        popupNameInput.text = ""
        popupValueInput.text = ""
        root.revealInput = false
        root.formOpen = false
    }

    function editVariable(name) {
        const entry = root.variables[name]
        root.editingName = name
        popupDisplayNameInput.text = typeof entry === "object" ? (entry?.name ?? "") : ""
        popupNameInput.text = name
        popupValueInput.text = String((typeof entry === "object" ? entry?.value : entry) ?? "")
        root.formOpen = true
        popupNameInput.forceActiveFocus()
    }

    function saveVariable() {
        if (!root.validName || popupValueInput.text.length === 0) return
        const key = popupNameInput.text.trim()
        if (root.editingName.length > 0 && root.editingName !== key)
            KeyringStorage.removeNestedField(["environmentVariables", root.editingName])
        KeyringStorage.setNestedField(["environmentVariables", key], {
            "name": popupDisplayNameInput.text.trim(),
            "value": popupValueInput.text
        })
        root.resetForm()
    }

    function displayNameFor(key) {
        const entry = root.variables[key]
        return (typeof entry === "object" && entry?.name) ? entry.name : key
    }

    function valueFor(key) {
        const entry = root.variables[key]
        return String((typeof entry === "object" ? entry?.value : entry) ?? "")
    }

    Component.onCompleted: {
        if (!KeyringStorage.loaded) KeyringStorage.fetchKeyringData()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText {
                    text: Translation.tr("Vaults")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: "Environment variables stored securely in your system keyring"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }
            }

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: root.revealValues = !root.revealValues
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.revealValues ? "visibility_off" : "visibility"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        Rectangle {
            visible: false
            Layout.fillWidth: true
            implicitHeight: formLayout.implicitHeight
            color: "transparent"

            ColumnLayout {
                id: formLayout
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    MaterialSymbol {
                        text: root.editingName.length > 0 ? "edit" : "add_circle"
                        iconSize: 18
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: root.editingName.length > 0 ? "Edit secret" : "Add secret"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                    Item { Layout.fillWidth: true }
                }

                StyledText {
                    text: "Variable name"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.78
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: nameInput.activeFocus ? 2 : 1
                    border.color: nameInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                    MaterialSymbol {
                        id: nameIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: "data_object"
                        iconSize: 18
                        color: nameInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }
                    StyledTextInput {
                        id: nameInput
                        anchors.left: nameIcon.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 9
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: nameInput.text.length === 0
                            text: "API_KEY"
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                StyledText {
                    text: "Secret value"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.78
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: valueInput.activeFocus ? 2 : 1
                    border.color: valueInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                    MaterialSymbol {
                        id: valueIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: "key"
                        iconSize: 18
                        color: valueInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }
                    StyledTextInput {
                        id: valueInput
                        anchors.left: valueIcon.right
                        anchors.right: inputRevealButton.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 9
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: root.revealInput ? TextInput.Normal : TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        onAccepted: root.saveVariable()
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: valueInput.text.length === 0
                            text: "Enter a secret"
                            color: Appearance.colors.colSubtext
                        }
                    }
                    RippleButton {
                        id: inputRevealButton
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        onClicked: root.revealInput = !root.revealInput
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.revealInput ? "visibility_off" : "visibility"
                            iconSize: 17
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                StyledText {
                    visible: nameInput.text.length > 0 && !root.validName
                    text: "Use a valid environment name, for example API_KEY"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colError
                }
                RowLayout {
                    Layout.fillWidth: true
                    RippleButton {
                        visible: root.editingName.length > 0
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonText: "Cancel"
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        onClicked: root.resetForm()
                    }
                    RippleButton {
                        id: saveButton
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonText: root.editingName.length > 0 ? "Update" : "Add variable"
                        enabled: root.validName && valueInput.text.length > 0
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        onClicked: {
                            root.saveVariable()
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            RowLayout {
                id: cardHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                height: 28
                MaterialSymbol {
                    text: "key"
                    iconSize: 18
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Environment variables"
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: countText.implicitWidth + 14
                    implicitHeight: 24
                    radius: 12
                    color: Appearance.colors.colLayer1
                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        text: root.variableNames.length
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: cardHeader.bottom
                anchors.topMargin: 10
                height: 1
                color: Appearance.colors.colLayer0Border
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: KeyringStorage.loaded && root.variableNames.length === 0
                MaterialSymbol {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "encrypted"
                    iconSize: 34
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No variables yet"
                    color: Appearance.colors.colSubtext
                }
            }

            StyledListView {
                id: variableList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: cardHeader.bottom
                anchors.bottom: parent.bottom
                anchors.topMargin: 12
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 8
                visible: root.variableNames.length > 0
                clip: true
                spacing: 0
                model: root.variableNames

                delegate: Rectangle {
                    required property string modelData
                    width: variableList.width
                    implicitHeight: variableRow.implicitHeight + 18
                    radius: Appearance.rounding.small
                    color: rowMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    RowLayout {
                        id: variableRow
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 8
                        MaterialSymbol {
                            text: "key"
                            iconSize: 18
                            color: Appearance.colors.colPrimary
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            StyledText {
                                Layout.fillWidth: true
                                text: root.displayNameFor(modelData)
                                elide: Text.ElideRight
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData + "  •  " + (root.revealValues ? root.valueFor(modelData) : "••••••••••••")
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colSubtext
                            }
                        }
                        RippleButton {
                            implicitWidth: 30
                            implicitHeight: 30
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            onClicked: root.editVariable(modelData)
                            contentItem: MaterialSymbol { anchors.centerIn: parent; text: "edit"; iconSize: 17; color: Appearance.colors.colOnLayer1 }
                        }
                        RippleButton {
                            implicitWidth: 30
                            implicitHeight: 30
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            onClicked: {
                                if (root.editingName === modelData) root.resetForm()
                                KeyringStorage.removeNestedField(["environmentVariables", modelData])
                            }
                            contentItem: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 17; color: Appearance.colors.colError }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: true

            Item { Layout.fillWidth: true }
            RippleButton {
                implicitWidth: addButtonRow.implicitWidth + 24
                implicitHeight: 40
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                onClicked: {
                    root.editingName = ""
                    popupDisplayNameInput.text = ""
                    popupNameInput.text = ""
                    popupValueInput.text = ""
                    root.formOpen = true
                    Qt.callLater(() => popupNameInput.forceActiveFocus())
                }
                contentItem: RowLayout {
                    id: addButtonRow
                    spacing: 6
                    Item { Layout.fillWidth: true }
                    MaterialSymbol {
                        text: "add"
                        iconSize: 18
                        color: Appearance.colors.colOnPrimary
                    }
                    StyledText {
                        text: "Add"
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimary
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.formOpen
        z: 100

        MouseArea {
            anchors.fill: parent
            onClicked: root.resetForm()
        }

        Rectangle {
            id: vaultPopup
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 320)
            implicitHeight: popupLayout.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: popupLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    MaterialSymbol {
                        text: root.editingName.length > 0 ? "edit" : "add_circle"
                        iconSize: 18
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.editingName.length > 0 ? "Edit variable" : "Add variable"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer2
                    }
                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        onClicked: root.resetForm()
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 18; color: Appearance.colors.colSubtext }
                    }
                }

                StyledText {
                    text: "Name (optional)"
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: popupDisplayNameInput.activeFocus ? 2 : 1
                    border.color: popupDisplayNameInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    StyledTextInput {
                        id: popupDisplayNameInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        KeyNavigation.tab: popupNameInput
                        KeyNavigation.backtab: popupSaveButton
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: popupDisplayNameInput.text.length === 0
                            text: "e.g. OpenAI"
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                StyledText {
                    text: "KEY"
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: popupNameInput.activeFocus ? 2 : 1
                    border.color: popupNameInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    StyledTextInput {
                        id: popupNameInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                        KeyNavigation.tab: popupValueInput
                        KeyNavigation.backtab: popupDisplayNameInput
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: popupNameInput.text.length === 0
                            text: "API_KEY"
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                StyledText {
                    text: "VALUE"
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: popupValueInput.activeFocus ? 2 : 1
                    border.color: popupValueInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    StyledTextInput {
                        id: popupValueInput
                        anchors.left: parent.left
                        anchors.right: popupRevealButton.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: root.revealInput ? TextInput.Normal : TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        KeyNavigation.tab: popupCancelButton
                        KeyNavigation.backtab: popupNameInput
                        onAccepted: root.saveVariable()
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: popupValueInput.text.length === 0
                            text: "Enter a secret"
                            color: Appearance.colors.colSubtext
                        }
                    }
                    RippleButton {
                        id: popupRevealButton
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 30
                        implicitHeight: 30
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        onClicked: root.revealInput = !root.revealInput
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: root.revealInput ? "visibility_off" : "visibility"; iconSize: 17; color: Appearance.colors.colSubtext }
                    }
                }

                StyledText {
                    visible: popupNameInput.text.length > 0 && !root.validName
                    text: "Use a valid name, for example API_KEY"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colError
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    RippleButton {
                        id: popupCancelButton
                        activeFocusOnTab: true
                        Layout.fillWidth: true
                        implicitHeight: 34
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colLayer1
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        onClicked: root.resetForm()
                        KeyNavigation.tab: popupSaveButton
                        KeyNavigation.backtab: popupValueInput
                        contentItem: StyledText {
                            text: "Cancel"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                    RippleButton {
                        id: popupSaveButton
                        activeFocusOnTab: true
                        Layout.fillWidth: true
                        implicitHeight: 34
                        enabled: root.validName && popupValueInput.text.length > 0
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        onClicked: root.saveVariable()
                        KeyNavigation.tab: popupDisplayNameInput
                        KeyNavigation.backtab: popupCancelButton
                        contentItem: StyledText {
                            text: root.editingName.length > 0 ? "Update" : "Add"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }
}
