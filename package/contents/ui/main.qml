import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import "RSSParser.js" as RSSParser

PlasmoidItem {
    id: root

    // Force full representation always - we want to be a panel widget
    preferredRepresentation: fullRepresentation

    // Fixed height for panel integration
    Layout.minimumHeight: 27
    Layout.maximumHeight: 27
    Layout.preferredHeight: 27

    // Width management for panel use
    Layout.fillWidth: true
    Layout.minimumWidth: 200  // Ensure minimum space for headlines
    Layout.preferredWidth: preferredWidgetWidth  // User-configurable width

    // Widget properties
    property var headlines: []
    property string currentDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property bool isLoading: false
    property int currentHeadlineIndex: 0
    property real totalTextWidth: 0
    property bool fadeInProgress: false
    property int hoveredHeadlineIndex: -1  // Track which headline is being hovered (-1 = none)

    // Debug loading state changes
    onIsLoadingChanged: {
        console.log("[RSS-Ticker] isLoading changed to:", isLoading)
    }

    // Configuration access
    property string rssUrl: plasmoid.configuration.rssUrl || "https://feeds.bbci.co.uk/news/rss.xml"
    property int updateIntervalHours: plasmoid.configuration.updateInterval || 3
    property real scrollSpeed: plasmoid.configuration.scrollSpeed || 50.0
    property bool fadeEnabled: plasmoid.configuration.fadeEnabled !== undefined ? plasmoid.configuration.fadeEnabled : true
    property int preferredWidgetWidth: plasmoid.configuration.preferredWidth || 400

    // Update layout when width preference changes
    onPreferredWidgetWidthChanged: {
        Layout.preferredWidth = preferredWidgetWidth
        console.log("[RSS-Ticker] Widget width changed to:", preferredWidgetWidth, "actual Layout.preferredWidth:", Layout.preferredWidth)
    }

    // Update text formatting when hover state changes
    onHoveredHeadlineIndexChanged: {
        if (headlines.length > 0) {
            // Force text update when hover state changes
            headlineText.text = generateFormattedText()
        }
    }

    toolTipMainText: "RSS News Ticker"
    toolTipSubText: "Showing " + headlines.length + " headlines from today"

    Component.onCompleted: {
        console.log("[RSS-Ticker] Widget initialized")
        console.log("[RSS-Ticker] RSS URL:", rssUrl)
        console.log("[RSS-Ticker] Update interval:", updateIntervalHours, "hours")
        console.log("[RSS-Ticker] Current date:", currentDate)
        console.log("[RSS-Ticker] Preferred width:", preferredWidgetWidth)
        // Ensure width is applied immediately
        Layout.preferredWidth = preferredWidgetWidth
        fetchRSSFeed()
    }

    // Timer for periodic updates
    Timer {
        id: updateTimer
        interval: updateIntervalHours * 60 * 60 * 1000 // Convert hours to milliseconds
        running: true
        repeat: true
        onTriggered: {
            console.log("[RSS-Ticker] Periodic update triggered")
            fetchRSSFeed()
        }
    }

    // Timer for date checking
    Timer {
        id: dateCheckTimer
        interval: 60000 // Check every minute
        running: true
        repeat: true
        onTriggered: {
            var newDate = Qt.formatDate(new Date(), "yyyy-MM-dd")
            if (newDate !== currentDate) {
                console.log("[RSS-Ticker] Date changed from", currentDate, "to", newDate)
                currentDate = newDate
                handleDateChange()
            }
        }
    }

    function handleDateChange() {
        if (fadeEnabled && !fadeInProgress) {
            console.log("[RSS-Ticker] Starting fade transition for date change")
            fadeInProgress = true
            fadeOutAnimation.start()
        } else {
            fetchRSSFeed()
        }
    }

    function fetchRSSFeed() {
        console.log("[RSS-Ticker] Fetching RSS feed from:", rssUrl)
        var startTime = new Date()
        isLoading = true

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var fetchTime = new Date() - startTime
                console.log("[RSS-Ticker] Fetch completed in", fetchTime, "ms")

                if (xhr.status === 200) {
                    console.log("[RSS-Ticker] Feed data received, parsing...")
                    parseRSSFeed(xhr.responseText)
                } else {
                    console.log("[RSS-Ticker] Fetch failed with status:", xhr.status)
                    headlines = []
                }
                isLoading = false
                console.log("[RSS-Ticker] Feed processing complete, loading indicator off")
            }
        }
        xhr.open("GET", rssUrl)
        xhr.send()
    }

    function parseRSSFeed(xmlText) {
        console.log("[RSS-Ticker] Parsing RSS XML...")

        // Use the RSS parser module
        var todayHeadlines = RSSParser.parseRSSFeed(xmlText, currentDate)

        if (todayHeadlines.length === 0) {
            console.log("[RSS-Ticker] No headlines found for today, using recent items as fallback")
            todayHeadlines = RSSParser.getFallbackHeadlines(xmlText, 5)
        }

        console.log("[RSS-Ticker] Final headline count:", todayHeadlines.length)
        headlines = todayHeadlines

        // Restart marquee animation
        if (headlines.length > 0) {
            console.log("[RSS-Ticker] Starting animation with", headlines.length, "headlines")
            calculateTextWidth()
            // Force immediate animation restart
            Qt.callLater(function() {
                restartAnimationWithNewSpeed()
            })
        } else {
            console.log("[RSS-Ticker] No headlines to animate")
        }

        // Explicitly stop loading
        isLoading = false
        console.log("[RSS-Ticker] Parse complete, loading stopped, isLoading =", isLoading)
    }

    function calculateTextWidth() {
        if (headlines.length === 0) {
            totalTextWidth = 0
            return
        }

        // Create combined text to measure (plain text for width calculation)
        var combinedText = headlines.map(function(headline) {
            return headline.title
        }).join("    •    ") + "    •    "

        textMetrics.text = combinedText
        totalTextWidth = textMetrics.width
        console.log("[RSS-Ticker] Calculated total text width:", totalTextWidth, "px")

        // Reset hover state when content changes
        hoveredHeadlineIndex = -1
    }

    function restartAnimationWithNewSpeed() {
        console.log("[RSS-Ticker] Restarting animation with speed:", scrollSpeed, "px/s")

        if (headlines.length === 0 || totalTextWidth <= 0) {
            console.log("[RSS-Ticker] Cannot restart animation - no content")
            return
        }

        // Stop current animation completely
        marqueeAnimation.stop()

        // Reset position immediately
        marqueeContainer.x = contentArea.width

        // Calculate new duration with current dimensions
        var availableWidth = contentArea.width > 0 ? contentArea.width : 400
        var newDuration = Math.max(1000, (totalTextWidth + availableWidth) * 1000 / scrollSpeed)

        console.log("[RSS-Ticker] Animation parameters - Width:", availableWidth, "Total:", totalTextWidth, "Duration:", newDuration, "ms")

        // Apply new settings and restart
        marqueeAnimation.duration = newDuration
        marqueeAnimation.from = availableWidth
        marqueeAnimation.to = -totalTextWidth

        // Use timer to ensure clean restart
        Qt.callLater(function() {
            if (!fadeInProgress) {
                marqueeAnimation.start()
                console.log("[RSS-Ticker] Animation restarted successfully")
            }
        })
    }

    function openLink(url) {
        console.log("[RSS-Ticker] Opening link:", url)
        Qt.openUrlExternally(url)
    }

    function getHeadlineIndexAtPosition(xPos) {
        if (headlines.length === 0) return -1

            var accumulatedWidth = 0
            var separator = "    •    "

            for (var i = 0; i < headlines.length; i++) {
                textMetrics.text = headlines[i].title
                var headlineWidth = textMetrics.width

                if (xPos >= accumulatedWidth && xPos <= accumulatedWidth + headlineWidth) {
                    return i
                }

                accumulatedWidth += headlineWidth
                textMetrics.text = separator
                accumulatedWidth += textMetrics.width
            }
            return -1
    }

    function generateFormattedText() {
        if (headlines.length === 0) {
            return "Loading headlines..."
        }

        var formattedParts = []
        for (var i = 0; i < headlines.length; i++) {
            var title = headlines[i].title
            // Escape HTML characters to prevent formatting issues
            title = title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

            if (hoveredHeadlineIndex === i) {
                // Use HTML to underline only the hovered headline
                formattedParts.push('<u>' + title + '</u>')
            } else {
                formattedParts.push(title)
            }
        }
        return formattedParts.join("    •    ") + "    •    "
    }

    // Text metrics for width calculation - optimized font metrics
    TextMetrics {
        id: textMetrics
        font.pixelSize: 11  // Reduced further for better fit
        font.weight: Font.Medium
        font.family: "Sans Serif"  // Explicit font family for consistency
    }

    fullRepresentation: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Inset background frame
        KSvg.FrameSvgItem {
            id: backgroundFrame
            anchors.fill: parent
            imagePath: "widgets/frame"
            prefix: "sunken"

            // Content area with precise clipping and margin calculation
            Item {
                id: contentArea
                anchors.fill: parent
                anchors.margins: Math.max(backgroundFrame.margins.left, 2)  // Ensure minimum margin
                clip: true

                // Scrolling headline container with precise positioning
                Item {
                    id: marqueeContainer
                    width: totalTextWidth
                    height: parent.height
                    x: parent.width // Start off-screen to the right

                    // Marquee animation with enhanced control
                    NumberAnimation {
                        id: marqueeAnimation
                        target: marqueeContainer
                        property: "x"
                        from: contentArea.width
                        to: -totalTextWidth
                        duration: totalTextWidth > 0 ? (totalTextWidth + contentArea.width) * 1000 / scrollSpeed : 0
                        loops: Animation.Infinite
                        running: headlines.length > 0 && totalTextWidth > 0 && !fadeInProgress

                        onRunningChanged: {
                            console.log("[RSS-Ticker] Marquee animation running:", running, "totalWidth:", totalTextWidth, "headlines:", headlines.length)
                            if (running) {
                                console.log("[RSS-Ticker] Animation started, duration:", duration, "ms")
                            }
                        }

                        onStopped: {
                            console.log("[RSS-Ticker] Animation stopped")
                        }
                    }

                    // Headlines text with optimized vertical positioning
                    Text {
                        id: headlineText
                        width: parent.width
                        height: parent.height
                        color: Kirigami.Theme.textColor  // Use theme-aware color
                        font.pixelSize: 11  // Reduced for better vertical fit
                        font.weight: Font.Medium  // Keep consistent weight
                        font.family: "Sans Serif"

                        // Critical: Use proper vertical alignment for panel widgets
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -1  // Fine-tune vertical position

                        // Enable rich text for individual headline underlining
                        textFormat: Text.RichText

                        // Rendering optimizations
                        renderType: Text.NativeRendering
                        antialiasing: true

                        text: generateFormattedText()

                        // Enhanced mouse handling with individual headline hover detection
                        MouseArea {
                            id: headlineMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onPositionChanged: {
                                if (containsMouse) {
                                    var newHoveredIndex = getHeadlineIndexAtPosition(mouseX)
                                    if (newHoveredIndex !== hoveredHeadlineIndex) {
                                        hoveredHeadlineIndex = newHoveredIndex
                                        console.log("[RSS-Ticker] Hovering over headline index:", hoveredHeadlineIndex)
                                    }
                                }
                            }

                            onExited: {
                                if (hoveredHeadlineIndex !== -1) {
                                    hoveredHeadlineIndex = -1
                                    console.log("[RSS-Ticker] Mouse exited, clearing hover")
                                }
                            }

                            onClicked: function(mouse) {
                                if (headlines.length === 0) return

                                    var clickedIndex = getHeadlineIndexAtPosition(mouse.x)
                                    if (clickedIndex !== -1) {
                                        console.log("[RSS-Ticker] Clicked on headline", clickedIndex + 1, ":", headlines[clickedIndex].title)
                                        openLink(headlines[clickedIndex].link)
                                    } else if (headlines.length > 0) {
                                        // Fallback - open first headline
                                        console.log("[RSS-Ticker] Default click action - opening first headline")
                                        openLink(headlines[0].link)
                                    }
                            }
                        }
                    }
                }

                // Loading indicator with precise positioning
                PlasmaComponents3.BusyIndicator {
                    anchors.centerIn: parent
                    running: isLoading
                    visible: isLoading
                    implicitWidth: 14  // Reduced size for 27px height
                    implicitHeight: 14
                    z: 10 // Ensure it's on top

                    onVisibleChanged: {
                        console.log("[RSS-Ticker] Loading indicator visible:", visible, "isLoading:", isLoading)
                    }
                }
            }
        }

        // Fade animations for date transitions
        NumberAnimation {
            id: fadeOutAnimation
            target: contentArea
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 300
            onFinished: {
                console.log("[RSS-Ticker] Fade out complete, fetching new data")
                fetchRSSFeed()
                fadeInAnimation.start()
            }
        }

        NumberAnimation {
            id: fadeInAnimation
            target: contentArea
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 300
            onFinished: {
                console.log("[RSS-Ticker] Fade in complete")
                fadeInProgress = false
            }
        }
    }

    // Enhanced configuration change handling with immediate effects
    Connections {
        target: plasmoid.configuration
        function onRssUrlChanged() {
            console.log("[RSS-Ticker] RSS URL changed to:", plasmoid.configuration.rssUrl)
            rssUrl = plasmoid.configuration.rssUrl
            fetchRSSFeed()
        }
        function onUpdateIntervalChanged() {
            console.log("[RSS-Ticker] Update interval changed to:", plasmoid.configuration.updateInterval, "hours")
            updateIntervalHours = plasmoid.configuration.updateInterval
            updateTimer.interval = updateIntervalHours * 60 * 60 * 1000
            updateTimer.restart()
        }
        function onScrollSpeedChanged() {
            console.log("[RSS-Ticker] Scroll speed changed to:", plasmoid.configuration.scrollSpeed)
            var oldSpeed = scrollSpeed
            scrollSpeed = plasmoid.configuration.scrollSpeed
            console.log("[RSS-Ticker] Speed change from", oldSpeed, "to", scrollSpeed)

            // Immediate synchronous restart with new speed
            if (headlines.length > 0 && totalTextWidth > 0) {
                restartAnimationWithNewSpeed()
            }
        }
        function onPreferredWidthChanged() {
            console.log("[RSS-Ticker] Preferred width changed to:", plasmoid.configuration.preferredWidth)
            preferredWidgetWidth = plasmoid.configuration.preferredWidth
        }
        function onFadeEnabledChanged() {
            console.log("[RSS-Ticker] Fade enabled changed to:", plasmoid.configuration.fadeEnabled)
            fadeEnabled = plasmoid.configuration.fadeEnabled
        }
    }
}
