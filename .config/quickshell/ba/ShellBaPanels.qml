import qs.modules.background
import qs.modules.bar
import qs.modules.bootGreeting
import qs.modules.idleOverlay
import qs.modules.cheatsheet
import qs.modules.controlPanel
import qs.modules.dock
import qs.modules.lock
import qs.modules.mediaControls
import qs.modules.notificationPopup
import qs.modules.onScreenDisplay
import qs.modules.onScreenKeyboard
import qs.modules.recordingOsd
import qs.modules.overview
import qs.modules.polkit
import qs.modules.regionSelector
import qs.modules.screenCorners
import qs.modules.sessionScreen
import qs.modules.sidebarLeft
import qs.modules.sidebarRight
import qs.modules.tilingOverlay
import qs.modules.verticalBar
import qs.modules.wallpaperSelector
import qs.modules.ba.overlay
import qs.modules.shellUpdate
import qs.modules.screenTranslator
import "modules/clipboard" as ClipboardModule

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "."

Item {
    id: panelsRoot

    // Immediate panels — visible at first frame or must catch early events
    // Uses `active` which loads synchronously (required for first-frame visibility)
    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

    // Deferred panels — loaded asynchronously after first frame to reduce boot contention
    // Uses `loading` to pre-load in spare frame time, then `activeAsync` to activate without blocking
    component DeferredPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        // Pre-load async when Config is ready (in spare frame time)
        loading: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
        // Activate async when deferred phase is ready (doesn't block UI)
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

    // === Immediate panels (first frame + early event capture) ===
    PanelLoader { identifier: "baBar"; extraCondition: !(Config.options?.bar?.vertical ?? false); component: Bar {} }
    PanelLoader { identifier: "baVerticalBar"; extraCondition: Config.options?.bar?.vertical ?? false; component: VerticalBar {} }
    PanelLoader { identifier: "baBackground"; component: Background {} }
    PanelLoader { identifier: "baBackdrop"; extraCondition: Config.options?.background?.backdrop?.enable ?? false; component: Backdrop {} }
    PanelLoader { identifier: "baDock"; extraCondition: Config.options?.dock?.enable ?? true; component: Dock {} }
    PanelLoader { identifier: "baNotificationPopup"; component: NotificationPopup {} }
    PanelLoader { identifier: "baOnScreenDisplay"; component: OnScreenDisplay {} }

    // === Deferred panels (user-triggered or non-critical at boot) ===
    DeferredPanelLoader { identifier: "baBootGreeting"; component: BootGreeting {} }
    DeferredPanelLoader { identifier: "baIdleOverlay"; component: IdleOverlay {} }
    DeferredPanelLoader { identifier: "baCheatsheet"; component: Cheatsheet {} }
    DeferredPanelLoader { identifier: "baControlPanel"; component: ControlPanel {} }
    DeferredPanelLoader { identifier: "baLock"; component: Lock {} }
    DeferredPanelLoader { identifier: "baMediaControls"; component: MediaControls {} }
    DeferredPanelLoader { identifier: "baOnScreenKeyboard"; component: OnScreenKeyboard {} }
    DeferredPanelLoader { identifier: "baOverlay"; component: Overlay {} }
    DeferredPanelLoader { identifier: "baOverview"; component: Overview {} }
    DeferredPanelLoader { identifier: "baPolkit"; component: Polkit {} }
    DeferredPanelLoader { identifier: "baRegionSelector"; component: RegionSelector {} }
    DeferredPanelLoader { identifier: "baScreenCorners"; component: ScreenCorners {} }
    DeferredPanelLoader { identifier: "baSessionScreen"; component: SessionScreen {} }
    DeferredPanelLoader { identifier: "baSidebarLeft"; component: SidebarLeft {} }
    DeferredPanelLoader { identifier: "baSidebarRight"; component: SidebarRight {} }
    DeferredPanelLoader { identifier: "baTilingOverlay"; component: TilingOverlay {} }
    DeferredPanelLoader { identifier: "baWallpaperSelector"; component: WallpaperSelector {} }
    DeferredPanelLoader { identifier: "baCoverflowSelector"; component: WallpaperCoverflow {} }
    DeferredPanelLoader { identifier: "baClipboard"; component: ClipboardModule.ClipboardPanel {} }
    DeferredPanelLoader { identifier: "baShellUpdate"; component: ShellUpdateOverlay {} }
    DeferredPanelLoader { identifier: "baRecordingOsd"; component: RecordingOsd {} }
    DeferredPanelLoader { identifier: "baScreenTranslator"; component: ScreenTranslator {} }

    LazyLoader {
        active: Config.ready && (Config.options?.background?.effects?.ripple?.enable ?? false)
        component: Variants {
            model: Quickshell.screens

            PanelWindow {
                id: rippleWindow
                required property ShellScreen modelData
                screen: modelData
                focusable: false
                color: "transparent"
                visible: ripple.playing

                WlrLayershell.namespace: "quickshell:charging-ripple"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                mask: Region {}
                implicitWidth: modelData.width
                implicitHeight: modelData.height

                FluidRipple {
                    id: ripple
                    anchors.fill: parent
                    color: Appearance.colors.colPrimary
                    duration: Config.options?.background?.effects?.ripple?.rippleDuration ?? 3000

                    Component.onCompleted: {
                        if (Config.options?.background?.effects?.ripple?.reload ?? true) {
                            spawn();
                        }
                    }

                    Connections {
                        target: Battery
                        function onIsPluggedInChanged() {
                            if (Config.options?.background?.effects?.ripple?.charging ?? true) {
                                ripple.spawn();
                            }
                        }
                    }

                    Connections {
                        target: NiriService
                        function onInOverviewChanged() {
                            if (NiriService.inOverview && (Config.options?.background?.effects?.ripple?.overview ?? true)) {
                                if (rippleWindow.modelData.name === NiriService.currentOutput) {
                                    ripple.spawn(0, 0);
                                }
                            }
                        }
                    }

                    Connections {
                        target: GlobalStates
                        function onScreenLockedChanged() {
                            if (GlobalStates.screenLocked && (Config.options?.background?.effects?.ripple?.lock ?? true)) {
                                ripple.spawn();
                            }
                        }

                        function onSessionOpenChanged() {
                            if (GlobalStates.sessionOpen && (Config.options?.background?.effects?.ripple?.session ?? true)) {
                                ripple.spawn();
                            }
                        }

                        function onRequestRipple(x: real, y: real, screenName: string) {
                            if (rippleWindow.modelData.name === screenName) {
                                ripple.spawn(x, y);
                            }
                        }
                    }
                }
            }
        }
    }
}
