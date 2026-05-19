pragma Singleton
import Quickshell
Singleton {
    property bool multiMonitorEnabled: false
    property bool effectivePerMonitor: false
    function wallpaperUrlForScreen(screen) { return "" }
}
