pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.modules.ba.overlay.crosshair
import qs.modules.ba.overlay.volumeMixer
import qs.modules.ba.overlay.floatingImage
import qs.modules.ba.overlay.fpsLimiter
import qs.modules.ba.overlay.recorder
import qs.modules.ba.overlay.resources
import qs.modules.ba.overlay.notes
import qs.modules.ba.overlay.discord
import qs.modules.ba.overlay.notifications

DelegateChooser {
    id: root
    role: "identifier"

    DelegateChoice { roleValue: "crosshair"; Crosshair {} }
    DelegateChoice { roleValue: "floatingImage"; FloatingImage {} }
    DelegateChoice { roleValue: "fpsLimiter"; FpsLimiter {} }
    DelegateChoice { roleValue: "recorder"; Recorder {} }
    DelegateChoice { roleValue: "resources"; Resources {} }
    DelegateChoice { roleValue: "notes"; Notes {} }
    DelegateChoice { roleValue: "discord"; Discord {} }
    DelegateChoice { roleValue: "volumeMixer"; VolumeMixer {} }
    DelegateChoice { roleValue: "notifications"; Notifications {} }
}
