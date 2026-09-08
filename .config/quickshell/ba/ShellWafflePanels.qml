import qs.modules.bootGreeting
import qs.modules.idleOverlay
import qs.modules.cheatsheet
import qs.modules.lock
import qs.modules.onScreenKeyboard
import qs.modules.recordingOsd
import qs.modules.overview
import qs.modules.polkit
import qs.modules.regionSelector
import qs.modules.screenCorners
import qs.modules.sessionScreen
import qs.modules.wallpaperSelector
import qs.modules.ba.overlay
import qs.modules.screenTranslator
import "modules/clipboard" as ClipboardModule

import qs.modules.waffle.actionCenter
import qs.modules.waffle.altSwitcher as WaffleAltSwitcherModule
import qs.modules.waffle.background as WaffleBackgroundModule
import qs.modules.waffle.bar as WaffleBarModule
import qs.modules.waffle.clipboard as WaffleClipboardModule
import qs.modules.waffle.notificationCenter
import qs.modules.waffle.onScreenDisplay as WaffleOSDModule
import qs.modules.waffle.startMenu
import qs.modules.waffle.widgets
import qs.modules.waffle.backdrop as WaffleBackdropModule
import qs.modules.waffle.notificationPopup as WaffleNotificationPopupModule
import qs.modules.waffle.taskview as WaffleTaskViewModule

import QtQuick
import Quickshell
import qs.modules.common
import "."

Item {
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
    PanelLoader { identifier: "wBar"; component: WaffleBarModule.WaffleBar {} }
    PanelLoader { identifier: "wBackground"; component: WaffleBackgroundModule.WaffleBackground {} }
    PanelLoader { identifier: "wBackdrop"; extraCondition: Config.options?.waffles?.background?.backdrop?.enable ?? true; component: WaffleBackdropModule.WaffleBackdrop {} }
    PanelLoader { identifier: "wNotificationPopup"; component: WaffleNotificationPopupModule.WaffleNotificationPopup {} }
    PanelLoader { identifier: "wOnScreenDisplay"; component: WaffleOSDModule.WaffleOSD {} }

    // === Deferred panels (user-triggered or non-critical at boot) ===
    DeferredPanelLoader { identifier: "wStartMenu"; component: WaffleStartMenu {} }
    DeferredPanelLoader { identifier: "wActionCenter"; component: WaffleActionCenter {} }
    DeferredPanelLoader { identifier: "wNotificationCenter"; component: WaffleNotificationCenter {} }
    DeferredPanelLoader { identifier: "wWidgets"; extraCondition: Config.options?.waffles?.modules?.widgets ?? true; component: WaffleWidgets {} }
    DeferredPanelLoader { identifier: "wLock"; component: Lock {} }
    DeferredPanelLoader { identifier: "wPolkit"; component: Polkit {} }
    DeferredPanelLoader { identifier: "wSessionScreen"; component: SessionScreen {} }
    DeferredPanelLoader { identifier: "wTaskView"; component: WaffleTaskViewModule.WaffleTaskView {} }

    // Shared modules that work with waffle (all deferred — user-triggered)
    DeferredPanelLoader { identifier: "baBootGreeting"; component: BootGreeting {} }
    DeferredPanelLoader { identifier: "baIdleOverlay"; component: IdleOverlay {} }
    DeferredPanelLoader { identifier: "baCheatsheet"; component: Cheatsheet {} }
    DeferredPanelLoader { identifier: "baOnScreenKeyboard"; component: OnScreenKeyboard {} }
    DeferredPanelLoader { identifier: "baOverlay"; component: Overlay {} }
    DeferredPanelLoader { identifier: "baOverview"; component: Overview {} }
    DeferredPanelLoader { identifier: "baRegionSelector"; component: RegionSelector {} }
    DeferredPanelLoader { identifier: "baScreenCorners"; component: ScreenCorners {} }
    DeferredPanelLoader { identifier: "baWallpaperSelector"; component: WallpaperSelector {} }
    DeferredPanelLoader { identifier: "baCoverflowSelector"; component: WallpaperCoverflow {} }
    DeferredPanelLoader { identifier: "baClipboard"; extraCondition: Config.options?.panelFamily !== "waffle"; component: ClipboardModule.ClipboardPanel {} }
    DeferredPanelLoader { identifier: "baRecordingOsd"; component: RecordingOsd {} }
    DeferredPanelLoader { identifier: "baScreenTranslator"; component: ScreenTranslator {} }

    // Waffle Clipboard - handles IPC when panelFamily === "waffle"
    LazyLoader {
        loading: Config.ready && Config.options?.panelFamily === "waffle"
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady && Config.options?.panelFamily === "waffle"
        component: WaffleClipboardModule.WaffleClipboard {}
    }

    // Waffle AltSwitcher - handles IPC when panelFamily === "waffle"
    LazyLoader {
        loading: Config.ready && Config.options?.panelFamily === "waffle"
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady && Config.options?.panelFamily === "waffle"
        component: WaffleAltSwitcherModule.WaffleAltSwitcher {}
    }
}
