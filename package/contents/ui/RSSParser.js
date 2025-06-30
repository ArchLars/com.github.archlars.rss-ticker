// RSS Parser utility functions for Plasma 6 RSS Ticker widget

.pragma library

/**
 * Parse RSS XML and extract items with today's date
 * @param {string} xmlText - The RSS XML content
 * @param {string} targetDate - Date string in YYYY-MM-DD format
 * @returns {Array} Array of headline objects
 */
function parseRSSFeed(xmlText, targetDate) {
    console.log("[RSS-Parser] Starting RSS parse for date:", targetDate)

    try {
        // Use regex to extract RSS items since DOMParser isn't available in QML
        var headlines = []

        // Extract all <item>...</item> blocks
        var itemRegex = /<item[^>]*>([\s\S]*?)<\/item>/gi
        var itemMatches = xmlText.match(itemRegex)

        if (!itemMatches) {
            console.log("[RSS-Parser] No RSS items found")
            return []
        }

        console.log("[RSS-Parser] Found", itemMatches.length, "items in feed")

        for (var i = 0; i < itemMatches.length; i++) {
            var itemXml = itemMatches[i]
            var headline = parseRSSItem(itemXml, targetDate, i + 1)

            if (headline) {
                headlines.push(headline)
            }
        }

        console.log("[RSS-Parser] Extracted", headlines.length, "headlines for", targetDate)
        return headlines

    } catch (error) {
        console.log("[RSS-Parser] Error parsing RSS:", error.toString())
        return []
    }
}

/**
 * Parse a single RSS item using regex
 * @param {string} itemXml - RSS item XML string
 * @param {string} targetDate - Target date in YYYY-MM-DD format
 * @param {number} itemNumber - Item number for logging
 * @returns {Object|null} Headline object or null if not matching criteria
 */
function parseRSSItem(itemXml, targetDate, itemNumber) {
    try {
        // Extract title
        var titleMatch = itemXml.match(/<title[^>]*><!\[CDATA\[(.*?)\]\]><\/title>|<title[^>]*>(.*?)<\/title>/i)
        var title = titleMatch ? (titleMatch[1] || titleMatch[2] || "").trim() : ""

        // Extract link
        var linkMatch = itemXml.match(/<link[^>]*><!\[CDATA\[(.*?)\]\]><\/link>|<link[^>]*>(.*?)<\/link>/i)
        var link = linkMatch ? (linkMatch[1] || linkMatch[2] || "").trim() : ""

        // Extract pubDate
        var pubDateMatch = itemXml.match(/<pubDate[^>]*>(.*?)<\/pubDate>/i)
        var pubDateText = pubDateMatch ? pubDateMatch[1].trim() : ""

        // Clean up title - remove HTML entities
        title = cleanupText(title)

        if (!title || !link) {
            console.log("[RSS-Parser] Item", itemNumber, "has empty title or link")
            return null
        }

        // Parse and validate publication date
        var pubDate = null
        var pubDateString = ""

        if (pubDateText) {
            pubDate = new Date(pubDateText)
            if (isValidDate(pubDate)) {
                pubDateString = Qt.formatDate(pubDate, "yyyy-MM-dd")
            } else {
                console.log("[RSS-Parser] Item", itemNumber, "has invalid date:", pubDateText)
                pubDate = new Date()
                pubDateString = Qt.formatDate(pubDate, "yyyy-MM-dd")
            }
        } else {
            pubDate = new Date()
            pubDateString = Qt.formatDate(pubDate, "yyyy-MM-dd")
        }

        console.log("[RSS-Parser] Item", itemNumber, "- Date:", pubDateString, "Target:", targetDate)
        console.log("[RSS-Parser] Item", itemNumber, "- Title:", title.substring(0, 60) + (title.length > 60 ? "..." : ""))

        // Check if this item matches our target date
        if (pubDateString === targetDate) {
            console.log("[RSS-Parser] ✓ Item", itemNumber, "matches target date")
            return {
                title: title,
                link: link,
                pubDate: pubDate,
                description: ""
            }
        } else {
            console.log("[RSS-Parser] ✗ Item", itemNumber, "doesn't match target date")
            return null
        }

    } catch (error) {
        console.log("[RSS-Parser] Error parsing item", itemNumber, ":", error.toString())
        return null
    }
}

/**
 * Clean up text content - decode HTML entities and trim whitespace
 * @param {string} text - Raw text
 * @returns {string} Cleaned text
 */
function cleanupText(text) {
    if (!text) return ""

        // Decode common HTML entities
        text = text.replace(/&amp;/g, "&")
        text = text.replace(/&lt;/g, "<")
        text = text.replace(/&gt;/g, ">")
        text = text.replace(/&quot;/g, '"')
        text = text.replace(/&#39;/g, "'")
        text = text.replace(/&apos;/g, "'")

        // Remove any remaining HTML tags
        text = text.replace(/<[^>]*>/g, "")

        // Normalize whitespace
        text = text.replace(/\s+/g, " ")
        text = text.trim()

        return text
}

/**
 * Check if a Date object is valid
 * @param {Date} date - Date object to validate
 * @returns {boolean} True if valid date
 */
function isValidDate(date) {
    return date instanceof Date && !isNaN(date.getTime())
}

/**
 * Get fallback headlines when no items match today's date
 * @param {string} xmlText - RSS XML content
 * @param {number} maxItems - Maximum number of items to return
 * @returns {Array} Array of recent headline objects
 */
function getFallbackHeadlines(xmlText, maxItems) {
    console.log("[RSS-Parser] Getting fallback headlines, max:", maxItems)

    try {
        var headlines = []

        // Extract all <item>...</item> blocks
        var itemRegex = /<item[^>]*>([\s\S]*?)<\/item>/gi
        var itemMatches = xmlText.match(itemRegex)

        if (!itemMatches) {
            return []
        }

        var itemsToProcess = Math.min(maxItems || 5, itemMatches.length)

        for (var i = 0; i < itemsToProcess; i++) {
            var itemXml = itemMatches[i]

            // Extract title and link
            var titleMatch = itemXml.match(/<title[^>]*><!\[CDATA\[(.*?)\]\]><\/title>|<title[^>]*>(.*?)<\/title>/i)
            var linkMatch = itemXml.match(/<link[^>]*><!\[CDATA\[(.*?)\]\]><\/link>|<link[^>]*>(.*?)<\/link>/i)

            var title = titleMatch ? cleanupText(titleMatch[1] || titleMatch[2] || "") : ""
            var link = linkMatch ? (linkMatch[1] || linkMatch[2] || "").trim() : ""

            if (title && link) {
                headlines.push({
                    title: title,
                    link: link,
                    pubDate: new Date(),
                               description: ""
                })
                console.log("[RSS-Parser] Added fallback headline:", title.substring(0, 50) + "...")
            }
        }

        console.log("[RSS-Parser] Created", headlines.length, "fallback headlines")
        return headlines

    } catch (error) {
        console.log("[RSS-Parser] Error getting fallback headlines:", error.toString())
        return []
    }
}

/**
 * Validate RSS URL format
 * @param {string} url - URL to validate
 * @returns {Object} Validation result with isValid boolean and message string
 */
function validateRSSUrl(url) {
    if (!url || typeof url !== "string") {
        return {
            isValid: false,
            message: "URL is required"
        }
    }

    url = url.trim()

    if (url === "") {
        return {
            isValid: false,
            message: "URL cannot be empty"
        }
    }

    if (!url.startsWith("http://") && !url.startsWith("https://")) {
        return {
            isValid: false,
            message: "URL must start with http:// or https://"
        }
    }

    // Basic URL pattern check
    var urlPattern = /^https?:\/\/.+\..+/
    if (!urlPattern.test(url)) {
        return {
            isValid: false,
            message: "URL format appears invalid"
        }
    }

    return {
        isValid: true,
        message: "URL format is valid"
    }
}
