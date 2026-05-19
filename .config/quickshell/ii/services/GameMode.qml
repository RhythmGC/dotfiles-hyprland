pragma Singleton
import Quickshell
Singleton {
    property bool active: false
    function toggle() { active = !active; }
}
