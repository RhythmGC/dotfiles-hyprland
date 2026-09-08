pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

/**
 * A service that provides access to Hyprland keybinds.
 * Reads the live Hyprland bind registry so Lua-generated and user binds are
 * represented exactly as they are in the running compositor.
 */
Singleton {
    id: root
    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/hyprland/get_keybinds.py`)
    property var keybinds: ({"children": []})

    Connections {
        target: Hyprland

        enabled: CompositorService.isHyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                getKeybinds.running = true
            }
        }
    }

    Process {
        id: getKeybinds
        running: false
        command: [root.keybindParserPath, "--live"]
        
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.keybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }

    Timer {
        id: initTimer
        interval: 600
        repeat: false
        onTriggered: {
            if (!CompositorService.isHyprland) return
            getKeybinds.running = true
        }
    }

    Connections {
        target: CompositorService
        function onIsHyprlandChanged() {
            if (CompositorService.isHyprland) {
                initTimer.start()
            }
        }
    }

    Component.onCompleted: {
        if (CompositorService.isHyprland) initTimer.start()
    }
}
