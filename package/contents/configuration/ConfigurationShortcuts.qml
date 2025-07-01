import QtQuick
import QtQuick.Controls as QtControls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: root

    // Dummy properties so ConfigModel can assign values without warnings
    property string cfg_rssUrl
    property int cfg_updateInterval
    property real cfg_scrollSpeed
    property bool cfg_fadeEnabled
    property int cfg_preferredWidth

    title: i18n("Shortcuts")

    signal configurationChanged
    function saveConfig() {
        Plasmoid.globalShortcut = button.keySequence
    }

    Kirigami.FormLayout {
        QtControls.Label {
            Layout.fillWidth: true
            text: i18nd("plasma_shell_org.kde.plasma.desktop", "This shortcut will activate the applet as though it had been clicked.")
            wrapMode: Text.WordWrap
        }
        KeySequenceItem {
            id: button
            keySequence: Plasmoid.globalShortcut
            onKeySequenceChanged: {
                if (keySequence != Plasmoid.globalShortcut) {
                    root.configurationChanged();
                }
            }
        }
    }
}
