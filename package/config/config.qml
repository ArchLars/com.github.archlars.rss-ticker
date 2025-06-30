import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        // Load page from contents/ui
        source: "../contents/ui/configGeneral.qml"
    }
}
