import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils 1.0 as KCM

KCM.SimpleKCM {
    id: configRoot

    property alias cfg_rssUrl: rssUrlField.text
    property alias cfg_updateInterval: updateIntervalSpinBox.value
    property alias cfg_scrollSpeed: scrollSpeedSpinBox.value
    property alias cfg_fadeEnabled: fadeEnabledCheckBox.checked
    property alias cfg_preferredWidth: preferredWidthSpinBox.value

    Kirigami.FormLayout {
        QQC2.TextField {
            id: rssUrlField
            Kirigami.FormData.label: "RSS Feed URL:"
            placeholderText: "Enter RSS feed URL..."
            selectByMouse: true
        }

        QQC2.SpinBox {
            id: updateIntervalSpinBox
            Kirigami.FormData.label: "Update interval (hours):"
            from: 1
            to: 24
            stepSize: 1
            textFromValue: function(value, locale) {
                return value + " hour" + (value === 1 ? "" : "s")
            }
        }

        QQC2.SpinBox {
            id: scrollSpeedSpinBox
            Kirigami.FormData.label: "Scroll speed (px/sec):"
            from: 10
            to: 200
            stepSize: 10
            textFromValue: function(value, locale) {
                return value + " px/sec"
            }
        }

        QQC2.SpinBox {
            id: preferredWidthSpinBox
            Kirigami.FormData.label: "Widget width (pixels):"
            from: 200
            to: 1200
            stepSize: 50
            textFromValue: function(value, locale) {
                return value + " px"
            }
        }

        QQC2.CheckBox {
            id: fadeEnabledCheckBox
            Kirigami.FormData.label: "Fade transitions:"
            text: "Enable smooth fade effects when date changes"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Information"
        }

        QQC2.Label {
            Kirigami.FormData.label: "About:"
            text: "This widget displays today's headlines from an RSS feed in a scrolling marquee. Headlines are clickable and will open in your default browser."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            Kirigami.FormData.label: "Height:"
            text: "Widget height is fixed at 27px for optimal panel integration. Use the width setting above to control how much space the widget takes in your panel."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Button {
            Kirigami.FormData.label: "Test feed:"
            text: "Test RSS URL"
            icon.name: "view-refresh"
            onClicked: {
                // Simple URL validation
                var url = rssUrlField.text.trim()
                if (url === "") {
                    testResultLabel.text = "Please enter an RSS URL"
                    testResultLabel.color = Kirigami.Theme.negativeTextColor
                    return
                }

                if (!url.startsWith("http://") && !url.startsWith("https://")) {
                    testResultLabel.text = "URL must start with http:// or https://"
                    testResultLabel.color = Kirigami.Theme.negativeTextColor
                    return
                }

                testResultLabel.text = "URL format looks valid"
                testResultLabel.color = Kirigami.Theme.positiveTextColor
            }
        }

        QQC2.Label {
            id: testResultLabel
            text: ""
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
