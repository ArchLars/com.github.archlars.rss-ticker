import QtQuick 2.0
import QtQuick.Controls 2.3 as QtControls
import QtQuick.Layouts 1.0
import org.kde.kquickcontrols 2.0
import org.kde.kirigami 2.14 as Kirigami
import org.kde.plasma.plasmoid 2.0

Kirigami.ScrollablePage {
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

    ColumnLayout {
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
