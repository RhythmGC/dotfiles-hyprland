pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.sidebarRight.events as EventUi
import "../sidebarRight/wifiNetworks" as WifiUi

Scope {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool hasPlayer: (player?.trackTitle ?? "") !== ""
    readonly property bool playerIsPlaying: player?.isPlaying ?? false
    readonly property bool cavaHasData: (cava.points?.length ?? 0) > 0
    readonly property bool showMedia: Config.options?.idle?.showMedia ?? true
    readonly property bool showSystemMonitor: Config.options?.idle?.showSystemMonitor ?? true
    readonly property bool showWeather: (Config.options?.idle?.showWeather ?? true)
        && Weather.enabled && (Weather.data?.temp ?? "") !== ""
    readonly property color accent: Appearance.inirEverywhere
        ? Appearance.inir.colPrimary : Appearance.colors.colPrimary
    readonly property color accentAlt: Appearance.inirEverywhere
        ? Appearance.inir.colText : Appearance.colors.colTertiary
    readonly property color textPrimary: Appearance.inirEverywhere
        ? Appearance.inir.colText : Appearance.colors.colOnLayer0
    readonly property color textMuted: Appearance.inirEverywhere
        ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
    readonly property color glassColor: ColorUtils.transparentize(
        Appearance.inirEverywhere ? Appearance.inir.colLayer0 : Appearance.colors.colLayer0,
        0.22
    )
    readonly property color glassRaised: ColorUtils.transparentize(
        Appearance.inirEverywhere ? Appearance.inir.colLayer1 : Appearance.colors.colLayer1,
        0.18
    )
    readonly property color glassBorder: ColorUtils.transparentize(root.accent, 0.67)
    readonly property real panelRadius: Appearance.inirEverywhere
        ? Appearance.inir.roundingLarge : Appearance.rounding.large
    readonly property var today: DateTime.clock.date
    readonly property string weekdayTitle: Qt.locale().toString(today, "dddd").toUpperCase()
    readonly property string heroDate: Qt.locale().toString(today, "dd  MMMM  yyyy").toUpperCase()
    readonly property string monthTitle: Qt.locale().toString(today, "MMMM yyyy")
    readonly property var calendarDays: root.buildCalendar(today)
    property int eventsRevision: 0
    property var selectedCalendarDate: today
    readonly property int selectedEventCount: {
        root.eventsRevision
        const local = Events.getEventsForDate(root.selectedCalendarDate)?.length ?? 0
        const synced = CalendarSync.getEventsForDate(root.selectedCalendarDate)?.length ?? 0
        return local + synced
    }

    property real enteredAt: 0
    property int elapsedSeconds: 0
    property int railAvatarIndex: 0
    property int heroAvatarIndex: 0
    property real ambientPhase: 0
    property bool panelVisible: false
    property bool contentVisible: false
    property bool idleSubmapActive: false
    property bool wifiDialogOpen: false
    property bool eventsDialogOpen: false
    property var pendingEventDate: today
    readonly property bool modalOpen: wifiDialogOpen || eventsDialogOpen
    onWifiDialogOpenChanged: if (!root.modalOpen) focusDelay.restart()
    onEventsDialogOpenChanged: if (!root.modalOpen) focusDelay.restart()
    readonly property var ambientSpectrum: {
        const points = []
        const cpuBoost = 0.72 + Math.min(0.28, ResourceUsage.cpuUsage * 0.6)
        for (let i = 0; i < 144; ++i) {
            const x = Math.abs((i / 143) * 2 - 1)
            const outerPeak = Math.exp(-Math.pow((x - 0.62) / 0.16, 2))
            const centerPeak = Math.exp(-Math.pow(x / 0.22, 2)) * 0.55
            const ripple = 0.34 + 0.38 * Math.abs(Math.sin(i * 0.29 + root.ambientPhase))
                + 0.24 * Math.abs(Math.sin(i * 0.11 - root.ambientPhase * 0.72))
            points.push(Math.min(1000, (80 + 760 * (outerPeak + centerPeak) * ripple) * cpuBoost))
        }
        return points
    }

    readonly property string idleDuration: {
        const minutes = Math.floor(elapsedSeconds / 60)
        const seconds = elapsedSeconds % 60
        return minutes > 0 ? `${minutes}m ${seconds}s` : `${seconds}s`
    }

    function buildCalendar(date: var): var {
        const year = date.getFullYear()
        const month = date.getMonth()
        const first = new Date(year, month, 1)
        const mondayOffset = (first.getDay() + 6) % 7
        const start = new Date(year, month, 1 - mondayOffset)
        const result = []
        for (let i = 0; i < 42; ++i) {
            const day = new Date(start)
            day.setDate(start.getDate() + i)
            result.push({
                number: day.getDate(),
                date: day,
                currentMonth: day.getMonth() === month,
                today: day.getFullYear() === date.getFullYear()
                    && day.getMonth() === date.getMonth()
                    && day.getDate() === date.getDate()
            })
        }
        return result
    }

    function activate(): void {
        exitTimer.stop()
        GlobalStates.closeAllOverlays()
        if (GlobalStates.bootGreetingOpen) {
            GlobalStates.bootGreetingOpen = false
            GlobalStates.bootGreetingDone = true
        }
        root.enteredAt = Date.now()
        root.elapsedSeconds = 0
        root.panelVisible = true
        root.contentVisible = false
        root.engageIdleSubmap()
        ResourceUsage.ensureRunning()
        GlobalStates.idleOverlayOpen = true
        enterTimer.restart()
    }

    function dismiss(): void {
        if (!root.panelVisible)
            return
        root.contentVisible = false
        exitTimer.restart()
    }

    function engageIdleSubmap(): void {
        if (!CompositorService.isHyprland || root.idleSubmapActive)
            return
        root.idleSubmapActive = true
        Quickshell.execDetached([
            "hyprctl", "eval", "hl.dispatch(hl.dsp.submap(\"idle\"))"
        ])
    }

    function releaseIdleSubmap(): void {
        if (!root.idleSubmapActive)
            return
        root.idleSubmapActive = false
        Quickshell.execDetached([
            "hyprctl", "eval", "hl.dispatch(hl.dsp.submap(\"reset\"))"
        ])
    }

    function handleMediaKey(key: int, modifiers: int): bool {
        const shellMediaChord = (modifiers & Qt.MetaModifier)
            && (modifiers & Qt.ShiftModifier)
        if (key === Qt.Key_MediaNext || (shellMediaChord && key === Qt.Key_N)) {
            MprisController.next()
            return true
        }
        if (key === Qt.Key_MediaPrevious || (shellMediaChord && key === Qt.Key_B)) {
            MprisController.previous()
            return true
        }
        if (key === Qt.Key_MediaPlay
                || key === Qt.Key_MediaPause
                || key === Qt.Key_MediaTogglePlayPause
                || (shellMediaChord && key === Qt.Key_P)) {
            MprisController.togglePlaying()
            return true
        }
        return false
    }

    function openWifiDialog(): void {
        Network.enableWifi()
        Network.rescanWifi()
        root.wifiDialogOpen = true
        Qt.callLater(() => idleWifiDialogLoader.item?.forceActiveFocus())
    }

    function openEventsDialog(date: var): void {
        const requestedDate = new Date(date ?? root.today)
        requestedDate.setHours(12, 0, 0, 0)
        root.pendingEventDate = requestedDate
        root.eventsDialogOpen = true
        Qt.callLater(() => root.initializeEventsDialog())
    }

    function initializeEventsDialog(): void {
        const dialog = idleEventsDialogLoader.item
        if (!dialog)
            return
        dialog.loadEvent({
            _isNew: true,
            dateTime: root.pendingEventDate.toISOString()
        })
        dialog.forceActiveFocus()
    }

    Connections {
        target: GlobalStates
        function onIdleOverlayOpenChanged(): void {
            if (GlobalStates.idleOverlayOpen) {
                root.panelVisible = true
                root.contentVisible = false
                if (root.enteredAt <= 0)
                    root.enteredAt = Date.now()
                root.elapsedSeconds = 0
                ResourceUsage.ensureRunning()
                enterTimer.restart()
                focusDelay.restart()
            } else {
                root.releaseIdleSubmap()
                root.wifiDialogOpen = false
                root.eventsDialogOpen = false
                enterTimer.stop()
                exitTimer.stop()
                root.contentVisible = false
                root.panelVisible = false
                root.enteredAt = 0
                root.elapsedSeconds = 0
            }
        }
    }

    Connections {
        target: Events
        function onEventAdded(event): void { root.eventsRevision++ }
        function onEventRemoved(id): void { root.eventsRevision++ }
        function onEventUpdated(event): void { root.eventsRevision++ }
    }

    Connections {
        target: CalendarSync
        function onEventsUpdated(): void { root.eventsRevision++ }
    }

    Timer {
        interval: 1000
        repeat: true
        running: GlobalStates.idleOverlayOpen
        onTriggered: {
            root.elapsedSeconds = Math.max(0, Math.floor((Date.now() - root.enteredAt) / 1000))
            if (root.player && root.playerIsPlaying)
                root.player.positionChanged()
        }
    }

    Timer {
        interval: 90
        repeat: true
        running: GlobalStates.idleOverlayOpen
            && (!root.playerIsPlaying || !root.cavaHasData)
        onTriggered: root.ambientPhase += 0.085
    }

    Timer {
        id: focusDelay
        interval: 50
        repeat: false
        onTriggered: inputScope.forceActiveFocus()
    }

    Timer {
        interval: 750
        repeat: true
        running: GlobalStates.idleOverlayOpen && !root.modalOpen
        onTriggered: inputScope.forceActiveFocus()
    }

    Timer {
        id: enterTimer
        interval: 24
        repeat: false
        onTriggered: root.contentVisible = true
    }

    Timer {
        id: exitTimer
        interval: Appearance.animationsEnabled
            ? Appearance.animation.elementMoveExit.duration + 50 : 0
        repeat: false
        onTriggered: {
            root.releaseIdleSubmap()
            root.panelVisible = false
            GlobalStates.idleOverlayOpen = false
        }
    }

    Component.onDestruction: root.releaseIdleSubmap()

    MediaArtworkResolver {
        id: artworkResolver
        sourceUrl: root.player?.trackArtUrl ?? ""
        title: root.player?.trackTitle ?? ""
        artist: root.player?.trackArtist ?? ""
        album: root.player?.trackAlbum ?? ""
    }

    CavaProcess {
        id: cava
        active: GlobalStates.idleOverlayOpen && root.hasPlayer && root.playerIsPlaying
    }

    IpcHandler {
        target: "idle"
        function open(): void { root.activate() }
        function close(): void { root.dismiss() }
        function toggle(): void {
            if (GlobalStates.idleOverlayOpen)
                root.dismiss()
            else
                root.activate()
        }
    }

    Loader {
        active: CompositorService.isHyprland
        sourceComponent: GlobalShortcut {
            name: "idleToggle"
            description: "Toggle the custom IDLE overlay"
            onPressed: {
                if (GlobalStates.idleOverlayOpen)
                    root.dismiss()
                else
                    root.activate()
            }
        }
    }

    PanelWindow {
        id: idlePanel
        visible: root.panelVisible
        screen: GlobalStates.primaryScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:idle"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.idleOverlayOpen
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        implicitWidth: screen?.width ?? 1920
        implicitHeight: screen?.height ?? 1080

        FocusScope {
            id: inputScope
            anchors.fill: parent
            focus: GlobalStates.idleOverlayOpen && !root.modalOpen
            opacity: root.contentVisible ? 1 : 0
            scale: root.contentVisible ? 1 : 0.985
            transformOrigin: Item.Center
            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root.contentVisible
                        ? Appearance.animation.elementMoveEnter.duration
                        : Appearance.animation.elementMoveExit.duration
                    easing.type: root.contentVisible
                        ? Appearance.animation.elementMoveEnter.type
                        : Appearance.animation.elementMoveExit.type
                    easing.bezierCurve: root.contentVisible
                        ? Appearance.animation.elementMoveEnter.bezierCurve
                        : Appearance.animation.elementMoveExit.bezierCurve
                }
            }
            Behavior on scale {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root.contentVisible
                        ? Appearance.animation.elementMoveEnter.duration
                        : Appearance.animation.elementMoveExit.duration
                    easing.type: root.contentVisible
                        ? Appearance.animation.elementMoveEnter.type
                        : Appearance.animation.elementMoveExit.type
                    easing.bezierCurve: root.contentVisible
                        ? Appearance.animation.elementMoveEnter.bezierCurve
                        : Appearance.animation.elementMoveExit.bezierCurve
                }
            }
            Keys.onPressed: event => {
                if (root.modalOpen) {
                    event.accepted = false
                    return
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true
                    root.dismiss()
                    return
                }
                if (root.handleMediaKey(event.key, event.modifiers)) {
                    event.accepted = true
                    return
                }
                // Keep the session inert: every non-whitelisted key is swallowed.
                event.accepted = true
            }

            // Hyprland needs non-zero alpha to apply layer blur. Under 1% alpha
            // makes this an activation mask, not a visible replacement background.
            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.992)
            }

            // Absorb pointer input outside the controls so apps below cannot be
            // clicked. Media buttons remain interactive above this catch-all area.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                preventStealing: true
                onPressed: event => {
                    if (event.button === Qt.MiddleButton)
                        MprisController.togglePlaying()
                    else if (event.button === Qt.BackButton)
                        MprisController.previous()
                    else if (event.button === Qt.ForwardButton)
                        MprisController.next()
                    event.accepted = true
                    inputScope.forceActiveFocus()
                }
                onWheel: event => event.accepted = true
            }

            // Top telemetry pill from the reference, kept compact so the hero
            // typography remains the visual anchor.
            Rectangle {
                id: telemetryPill
                anchors.top: parent.top
                anchors.topMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter
                width: 310
                height: 42
                radius: 21
                color: root.glassColor
                border.width: 1
                border.color: root.glassBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8
                    MaterialSymbol { text: "bedtime"; iconSize: 18; color: root.accent }
                    StyledText {
                        text: "IDLE // " + SystemInfo.username.toUpperCase()
                        color: root.accent
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.family: Appearance.font.family.monospace
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: "CPU  " + Math.round(ResourceUsage.cpuUsage * 100) + "%"
                        color: root.textPrimary
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.family: Appearance.font.family.monospace
                        font.weight: Font.DemiBold
                    }
                }
            }

            RowLayout {
                id: dashboard
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                width: Math.min(1320, parent.width - 100)
                height: Math.min(670, parent.height - 180)
                spacing: 28

                // LEFT RAIL — weather, system identity, custom player.
                ColumnLayout {
                    Layout.preferredWidth: 338
                    Layout.fillHeight: true
                    spacing: 14

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 142
                        title: Translation.tr("Weather")
                        icon: "partly_cloudy_day"
                        visible: root.showWeather

                        RowLayout {
                            anchors.fill: parent
                            spacing: 14
                            MaterialSymbol {
                                text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "sunny"
                                iconSize: 48
                                color: root.accentAlt
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                StyledText {
                                    text: Weather.data?.description ?? Translation.tr("Unknown")
                                    color: root.textPrimary
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                }
                                StyledText {
                                    text: `${Weather.data?.humidity ?? "--"} humidity  //  ${Weather.data?.wind ?? "--"}`
                                    color: root.textMuted
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.family: Appearance.font.family.monospace
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                            StyledText {
                                text: Weather.data?.temp ?? "--"
                                color: root.textPrimary
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.family: Appearance.font.family.numbers
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 220
                        title: Translation.tr("System pipeline")
                        icon: "computer"
                        visible: root.showSystemMonitor

                        RowLayout {
                            anchors.fill: parent
                            spacing: 16

                            Rectangle {
                                Layout.preferredWidth: 112
                                Layout.fillHeight: true
                                Layout.maximumHeight: 200
                                radius: 18
                                color: root.glassRaised
                                clip: true
                                Image {
                                    id: railAvatar
                                    anchors.fill: parent
                                    source: Directories.avatarSourceAt(root.railAvatarIndex)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    onStatusChanged: {
                                        if (status === Image.Error
                                                && root.railAvatarIndex + 1 < Directories.userAvatarPaths.length)
                                            root.railAvatarIndex++
                                    }
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    visible: railAvatar.status !== Image.Ready
                                    text: "person"
                                    iconSize: 42
                                    color: root.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 0
                                PipelineRow { keyText: "OS"; valueText: SystemInfo.distroName }
                                PipelineRow { keyText: "WM"; valueText: SystemInfo.desktopEnvironment || "Hyprland" }
                                PipelineRow { keyText: "CPU"; valueText: Math.round(ResourceUsage.cpuUsage * 100) + "%" }
                                PipelineRow { keyText: "RAM"; valueText: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%" }
                                PipelineRow {
                                    keyText: "TEMP"
                                    valueText: ResourceUsage.cpuTemp > 0 ? ResourceUsage.cpuTemp + "°C" : "--"
                                    valueColor: ResourceUsage.cpuTemp >= 80 ? Appearance.colors.colError : root.accentAlt
                                }
                                PipelineRow {
                                    keyText: "BAT"
                                    valueText: Battery.available ? Math.round(Battery.percentage * 100) + "%" : Translation.tr("AC power")
                                    valueColor: Battery.isLow ? Appearance.colors.colError : root.accent
                                }
                            }
                        }
                    }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 168
                        title: Translation.tr("Now playing")
                        icon: "music_note"
                        visible: root.showMedia

                        RowLayout {
                            anchors.fill: parent
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 76
                                Layout.preferredHeight: 76
                                radius: 12
                                color: root.glassRaised
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    source: artworkResolver.displaySource
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    visible: artworkResolver.ready
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    visible: !artworkResolver.ready
                                    text: "music_note"
                                    iconSize: 30
                                    color: root.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.hasPlayer ? StringUtils.cleanMusicTitle(root.player.trackTitle) : Translation.tr("Nothing playing")
                                    color: root.textPrimary
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.hasPlayer ? (root.player.trackArtist || Translation.tr("Unknown artist")) : Translation.tr("Start a player to see media here")
                                    color: root.textMuted
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    height: 3
                                    radius: 2
                                    color: ColorUtils.transparentize(root.accent, 0.8)
                                    Rectangle {
                                        width: parent.width * (root.hasPlayer && root.player.length > 0
                                            ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0)
                                        height: parent.height
                                        radius: parent.radius
                                        color: root.accent
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                                        color: root.textMuted
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.family: Appearance.font.family.numbers
                                    }
                                    Item { Layout.fillWidth: true }
                                    MediaIconButton { symbol: "skip_previous"; clickAction: () => MprisController.previous() }
                                    MediaIconButton { symbol: root.playerIsPlaying ? "pause" : "play_arrow"; prominent: true; clickAction: () => MprisController.togglePlaying() }
                                    MediaIconButton { symbol: "skip_next"; clickAction: () => MprisController.next() }
                                    Item { Layout.fillWidth: true }
                                    StyledText {
                                        text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                                        color: root.textMuted
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.family: Appearance.font.family.numbers
                                    }
                                }
                            }
                        }
                    }
                }

                // CENTER — the reference's oversized weekday/date/time and avatar.
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 470
                    spacing: 4

                    Item { Layout.fillHeight: true }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.weekdayTitle
                        color: root.accent
                        font.family: Appearance.font.family.title
                        font.pixelSize: Math.min(86, idlePanel.width * 0.052)
                        font.weight: Font.Black
                        font.letterSpacing: 9
                        layer.enabled: Appearance.effectsEnabled
                        layer.effect: GE.DropShadow {
                            horizontalOffset: 0
                            verticalOffset: 0
                            radius: 20
                            samples: 33
                            color: ColorUtils.transparentize(root.accent, 0.28)
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 2
                        text: root.heroDate
                        color: root.textPrimary
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.monospace
                        font.letterSpacing: 7
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "— " + DateTime.time + " —"
                        color: root.accentAlt
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.family: Appearance.font.family.numbers
                        font.letterSpacing: 3
                    }

                    Item { Layout.preferredHeight: 20 }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 176
                        Layout.preferredHeight: 176

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: root.accent
                            layer.enabled: Appearance.effectsEnabled
                            layer.effect: GE.DropShadow {
                                horizontalOffset: 0
                                verticalOffset: 0
                                radius: 24
                                samples: 41
                                color: ColorUtils.transparentize(root.accent, 0.26)
                            }
                        }
                        Rectangle {
                            id: heroAvatarCircle
                            anchors.fill: parent
                            anchors.margins: 7
                            radius: width / 2
                            color: root.glassRaised
                            clip: true
                            Image {
                                id: heroAvatar
                                anchors.fill: parent
                                source: Directories.avatarSourceAt(root.heroAvatarIndex)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                onStatusChanged: {
                                    if (status === Image.Error
                                            && root.heroAvatarIndex + 1 < Directories.userAvatarPaths.length)
                                        root.heroAvatarIndex++
                                }
                                layer.enabled: Appearance.effectsEnabled
                                layer.effect: GE.OpacityMask {
                                    maskSource: Rectangle {
                                        width: heroAvatarCircle.width
                                        height: heroAvatarCircle.height
                                        radius: width / 2
                                    }
                                }
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: heroAvatar.status !== Image.Ready
                                text: "person"
                                iconSize: 64
                                color: root.accent
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 12
                        text: SystemInfo.displayName || SystemInfo.username
                        color: root.textPrimary
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        width: 292
                        height: 44
                        radius: 10
                        color: root.glassColor
                        border.width: 1
                        border.color: root.glassBorder

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            MaterialSymbol { text: "keyboard_return"; iconSize: 19; color: root.accent }
                            StyledText {
                                text: Translation.tr("PRESS ENTER TO EXIT IDLE")
                                color: root.textMuted
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.family: Appearance.font.family.monospace
                                font.letterSpacing: 1.5
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                        text: "SESSION IDLE  //  " + root.idleDuration
                        color: ColorUtils.transparentize(root.textMuted, 0.22)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.family: Appearance.font.family.monospace
                        font.letterSpacing: 2
                    }

                    Item { Layout.fillHeight: true }
                }

                // RIGHT RAIL — custom month grid and private-safe activity list.
                ColumnLayout {
                    Layout.preferredWidth: 338
                    Layout.fillHeight: true
                    spacing: 14

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 388
                        title: root.monthTitle
                        icon: "calendar_month"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 9

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 7
                                columnSpacing: 4
                                rowSpacing: 3

                                Repeater {
                                    model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                                    delegate: StyledText {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 22
                                        text: modelData
                                        horizontalAlignment: Text.AlignHCenter
                                        color: root.accent
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.family: Appearance.font.family.monospace
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Repeater {
                                    model: root.calendarDays
                                    delegate: Rectangle {
                                        id: dayCell
                                        required property var modelData
                                        readonly property bool selected: root.selectedCalendarDate
                                            && modelData.date.toDateString()
                                                === root.selectedCalendarDate.toDateString()
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 29
                                        radius: 9
                                        color: selected
                                            ? ColorUtils.transparentize(root.accent, 0.55)
                                            : dayMouse.containsMouse
                                                ? ColorUtils.transparentize(root.accent, 0.82)
                                                : "transparent"
                                        border.width: modelData.today || selected ? 1 : 0
                                        border.color: root.accent

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: dayCell.modelData.number
                                            color: dayCell.modelData.today ? root.textPrimary
                                                : dayCell.modelData.currentMonth ? root.textPrimary
                                                : ColorUtils.transparentize(root.textMuted, 0.56)
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.family: Appearance.font.family.numbers
                                            font.weight: dayCell.modelData.today || dayCell.selected
                                                ? Font.Bold : Font.Normal
                                        }

                                        MouseArea {
                                            id: dayMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedCalendarDate = dayCell.modelData.date
                                                inputScope.forceActiveFocus()
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.topMargin: 4
                                radius: 13
                                color: root.glassRaised
                                border.width: 1
                                border.color: ColorUtils.transparentize(root.glassBorder, 0.22)

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: Translation.tr("EVENTS // ")
                                                + Qt.locale().toString(root.selectedCalendarDate, "dd MMM").toUpperCase()
                                            color: root.accent
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.family: Appearance.font.family.monospace
                                            font.weight: Font.DemiBold
                                        }
                                        RippleButton {
                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 28
                                            buttonRadius: 9
                                            colBackground: ColorUtils.transparentize(root.accent, 0.82)
                                            colBackgroundHover: ColorUtils.transparentize(root.accent, 0.68)
                                            colRipple: root.accent
                                            onClicked: root.openEventsDialog(root.selectedCalendarDate)
                                            contentItem: MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "add"
                                                iconSize: 17
                                                color: root.accent
                                            }
                                        }
                                    }
                                    Item { Layout.fillHeight: true }
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: root.selectedEventCount > 0
                                            ? Translation.tr("%1 scheduled event(s)").arg(root.selectedEventCount)
                                            : Translation.tr("No events scheduled")
                                        color: root.textMuted
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }
                    }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        title: Translation.tr("Session activity")
                        icon: "notifications"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8
                            ActivityRow {
                                symbol: Network.materialSymbol
                                label: Translation.tr("Network")
                                value: Network.networkName || Network.wifiStatus
                                trailingSymbol: "chevron_right"
                                clickAction: () => root.openWifiDialog()
                            }
                            ActivityRow {
                                symbol: Battery.isCharging ? "battery_charging_full" : "battery_full"
                                label: Translation.tr("Battery")
                                value: Battery.available ? Math.round(Battery.percentage * 100) + "%" : Translation.tr("AC power")
                            }
                            ActivityRow {
                                symbol: "schedule"
                                label: Translation.tr("Uptime")
                                value: DateTime.uptime || "--"
                            }
                            ActivityRow {
                                symbol: "memory"
                                label: Translation.tr("Memory")
                                value: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)
                            }
                        }
                    }
                }
            }

            // Wide symmetric spectrum like the reference. When playback is idle,
            // a subtle baseline remains instead of leaving the bottom empty.
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Math.max(210, parent.width * 0.13)
                anchors.rightMargin: Math.max(210, parent.width * 0.13)
                anchors.bottomMargin: 16
                height: 88
                opacity: 0.82

                CavaVisualizer {
                    anchors.fill: parent
                    live: true
                    points: root.playerIsPlaying && root.cavaHasData
                        ? cava.points : root.ambientSpectrum
                    maxVisualizerValue: 1000
                    smoothing: 3
                    barCount: 72
                    barSpacing: 3
                    barMinHeight: 2
                    barRadius: 2
                    colorLow: ColorUtils.transparentize(root.accent, 0.62)
                    colorMed: root.accent
                    colorHigh: root.accentAlt
                }
            }

            Loader {
                id: idleWifiDialogLoader
                anchors.fill: parent
                z: 200
                active: root.wifiDialogOpen
                sourceComponent: WifiUi.WifiDialog {
                    anchors.fill: parent
                    show: true
                    onDismiss: root.wifiDialogOpen = false
                }
                onLoaded: item.forceActiveFocus()
            }

            Loader {
                id: idleEventsDialogLoader
                anchors.fill: parent
                z: 210
                active: root.eventsDialogOpen
                sourceComponent: EventUi.EventsDialog {
                    anchors.fill: parent
                    show: true
                    onDismiss: root.eventsDialogOpen = false
                }
                onLoaded: root.initializeEventsDialog()
            }
        }
    }

    component GlassCard: Rectangle {
        id: card
        required property string title
        required property string icon
        default property alias cardContent: body.data

        radius: root.panelRadius
        color: root.glassColor
        border.width: 1
        border.color: root.glassBorder
        clip: true

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: root.accent }
                GradientStop { position: 1; color: "transparent" }
            }
            opacity: 0.55
        }

        RowLayout {
            id: cardHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 12
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            height: 22
            spacing: 7
            MaterialSymbol { text: card.icon; iconSize: 16; color: root.accent }
            StyledText {
                Layout.fillWidth: true
                text: card.title.toUpperCase()
                color: root.accent
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                elide: Text.ElideRight
            }
        }

        Item {
            id: body
            anchors.top: cardHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 8
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 13
        }
    }

    component PipelineRow: RowLayout {
        id: pipelineRow
        required property string keyText
        required property string valueText
        property color valueColor: root.textPrimary
        Layout.fillHeight: true
        spacing: 10
        StyledText {
            Layout.preferredWidth: 48
            text: pipelineRow.keyText + ":"
            color: root.accent
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.monospace
            font.weight: Font.Bold
        }
        StyledText {
            Layout.fillWidth: true
            text: pipelineRow.valueText
            color: pipelineRow.valueColor
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.monospace
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }

    component MediaIconButton: RippleButton {
        id: mediaButton
        required property string symbol
        required property var clickAction
        property bool prominent: false
        implicitWidth: prominent ? 30 : 24
        implicitHeight: prominent ? 30 : 24
        buttonRadius: prominent ? 10 : 12
        enabled: root.hasPlayer
        colBackground: prominent ? ColorUtils.transparentize(root.accent, 0.45) : "transparent"
        colBackgroundHover: ColorUtils.transparentize(root.accent, 0.62)
        colRipple: root.accent
        onClicked: clickAction()
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            text: mediaButton.symbol
            iconSize: mediaButton.prominent ? 19 : 16
            fill: 1
            color: mediaButton.prominent ? root.textPrimary : root.textMuted
        }
    }

    component ActivityRow: Rectangle {
        id: activityRow
        required property string symbol
        required property string label
        required property string value
        property string trailingSymbol: ""
        property var clickAction: null
        readonly property bool interactive: typeof clickAction === "function"
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 44
        implicitHeight: 46
        radius: 11
        color: activityMouse.containsMouse && interactive
            ? ColorUtils.transparentize(root.accent, 0.84) : root.glassRaised
        border.width: 1
        border.color: ColorUtils.transparentize(root.glassBorder, 0.3)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 9
            Rectangle {
                width: 30; height: 30; radius: 9
                color: ColorUtils.transparentize(root.accent, 0.78)
                MaterialSymbol { anchors.centerIn: parent; text: activityRow.symbol; iconSize: 17; color: root.accent }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    Layout.fillWidth: true
                    text: activityRow.label
                    color: root.textPrimary
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: activityRow.value
                    color: root.textMuted
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.monospace
                    elide: Text.ElideRight
                }
            }
            MaterialSymbol {
                visible: activityRow.trailingSymbol !== ""
                text: activityRow.trailingSymbol
                iconSize: 18
                color: root.textMuted
            }
        }

        MouseArea {
            id: activityMouse
            anchors.fill: parent
            enabled: activityRow.interactive
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mouse => {
                activityRow.clickAction()
                mouse.accepted = true
            }
        }
    }
}
