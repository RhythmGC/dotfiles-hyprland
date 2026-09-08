pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common
import qs.services
import "root:"

/**
 * RedditService - Reddit public RSS feed
 * No auth required for public subreddits
 */
Singleton {
    id: root

    // Rate limiting: ~60 requests/minute without auth
    property int requestDelay: 1000
    property bool _canRequest: true
    
    // Data
    property var posts: []
    property string currentSubreddit: "unixporn"
    property string currentSort: "hot"  // hot, new, top
    
    // State
    property bool loading: false
    property string lastError: ""
    
    // Cache
    property var _cache: ({})
    property var _cacheTimestamps: ({})
    readonly property int cacheValidityMs: 5 * 60 * 1000  // 5 minutes
    
    // Config - use function to always get fresh value
    readonly property var defaultSubreddits: ["unixporn", "linux", "archlinux", "kde", "gnome"]
    
    function getSubreddits() {
        return Config.options?.sidebar?.reddit?.subreddits ?? root.defaultSubreddits
    }
    
    Timer {
        id: rateLimitTimer
        interval: root.requestDelay
        onTriggered: root._canRequest = true
    }
    
    function _makeRequest(url, callback) {
        if (!root._canRequest) {
            Qt.callLater(() => root._makeRequest(url, callback))
            return
        }
        
        root._canRequest = false
        rateLimitTimer.start()
        
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        callback(root._parseFeed(xhr.responseText), null)
                    } catch (e) {
                        callback(null, "Parse error: " + e.message)
                    }
                } else if (xhr.status === 429) {
                    root.lastError = "Rate limited, retrying..."
                    rateLimitTimer.interval = 2000
                    Qt.callLater(() => root._makeRequest(url, callback))
                } else {
                    callback(null, "HTTP " + xhr.status)
                }
            }
        }
        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", Config.options?.networking?.userAgent ?? "Mozilla/5.0")
        xhr.send()
    }
    
    function _isCacheValid(key) {
        const timestamp = root._cacheTimestamps[key]
        if (!timestamp) return false
        return (Date.now() - timestamp) < root.cacheValidityMs
    }
    
    function fetchPosts(subreddit, sort) {
        const sub = subreddit ?? root.currentSubreddit
        const s = sort ?? root.currentSort
        const cacheKey = sub + "_" + s
        
        if (root._isCacheValid(cacheKey) && root._cache[cacheKey]) {
            root.posts = root._cache[cacheKey]
            root.currentSubreddit = sub
            root.currentSort = s
            return
        }
        
        root.loading = true
        root.lastError = ""
        root.currentSubreddit = sub
        root.currentSort = s
        
        const limit = Config.options?.sidebar?.reddit?.limit ?? 25
        // Reddit now rejects anonymous .json requests with HTTP 403. Its Atom
        // feeds remain available for public subreddits without OAuth.
        const safeSub = encodeURIComponent(sub.replace(/^r\//, ""))
        const url = `https://www.reddit.com/r/${safeSub}/${s}/.rss?limit=${limit}`
        
        root._makeRequest(url, (children, error) => {
            root.loading = false
            if (error) {
                root.lastError = error
                return
            }
            
            root._cache[cacheKey] = children
            root._cacheTimestamps[cacheKey] = Date.now()
            root.posts = children
        })
    }

    function _parseFeed(xml) {
        const posts = []
        const entries = xml.match(/<entry(?:\s[^>]*)?>[\s\S]*?<\/entry>/g) ?? []

        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i]
            const content = root._xmlTag(entry, "content")
            const links = []
            const linkRegex = /href=["']([^"']+)["']/g
            let match
            while ((match = linkRegex.exec(content)) !== null)
                links.push(root._decodeHtml(match[1]))

            const permalinkMatch = entry.match(/<link\s[^>]*href=["']([^"']+)["'][^>]*\/?\s*>/)
            const permalink = permalinkMatch ? root._decodeHtml(permalinkMatch[1]) : ""
            const externalUrl = links.find(url => url.indexOf("/comments/") === -1 && url.indexOf("/user/") === -1) ?? permalink
            const thumbnailMatch = entry.match(/<media:thumbnail\s[^>]*url=["']([^"']+)["']/)
            const published = root._xmlTag(entry, "published") || root._xmlTag(entry, "updated")
            const author = root._xmlTag(root._xmlTag(entry, "author"), "name").replace(/^\/u\//, "")

            posts.push({
                id: root._xmlTag(entry, "id").replace(/^t3_/, ""),
                title: root._xmlTag(entry, "title"),
                author: author,
                subreddit: root.currentSubreddit,
                // Atom feeds do not expose vote or comment counts.
                score: -1,
                numComments: -1,
                created: Date.parse(published) / 1000,
                url: externalUrl,
                permalink: permalink,
                thumbnail: thumbnailMatch ? root._decodeHtml(thumbnailMatch[1]) : "",
                isVideo: false,
                isNsfw: false,
                isSelf: externalUrl === permalink,
                selftext: "",
                flair: "",
                domain: ""
            })
        }
        return posts
    }

    function _xmlTag(xml, tag) {
        const match = xml.match(new RegExp("<" + tag + "(?:\\s[^>]*)?>([\\s\\S]*?)</" + tag + ">"))
        if (!match) return ""
        return root._decodeHtml(match[1].replace(/^<!\[CDATA\[/, "").replace(/\]\]>$/, ""))
    }
    
    function _normalizePost(post) {
        // Get best thumbnail - use raw thumbnail first, then preview
        let thumbnail = ""
        
        // First try the direct thumbnail (usually works better)
        if (post.thumbnail && post.thumbnail.startsWith("http")) {
            thumbnail = post.thumbnail
        }
        // Then try preview images
        else if (post.preview?.images?.[0]?.resolutions) {
            const resolutions = post.preview.images[0].resolutions
            const medium = resolutions.find(r => r.width >= 320) ?? resolutions[resolutions.length - 1]
            thumbnail = medium?.url ?? ""
        }
        
        // Decode any HTML entities just in case
        thumbnail = root._decodeHtml(thumbnail)
        
        return {
            id: post.id,
            title: root._decodeHtml(post.title),
            author: post.author,
            subreddit: post.subreddit,
            score: post.score,
            numComments: post.num_comments,
            created: post.created_utc,
            url: post.url,
            permalink: "https://reddit.com" + post.permalink,
            thumbnail: thumbnail,
            isVideo: post.is_video,
            isNsfw: post.over_18,
            isSelf: post.is_self,
            selftext: post.selftext ?? "",
            flair: post.link_flair_text ?? "",
            domain: post.domain
        }
    }
    
    function _decodeHtml(html) {
        if (!html) return ""
        return html.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&apos;|&#39;/g, "'").replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)))
    }
    
    function formatScore(score) {
        if (score >= 1000000) return (score / 1000000).toFixed(1) + "M"
        if (score >= 1000) return (score / 1000).toFixed(1) + "k"
        return score.toString()
    }
    
    function formatTime(timestamp) {
        const now = Date.now() / 1000
        const diff = now - timestamp
        if (diff < 3600) return Math.floor(diff / 60) + "m"
        if (diff < 86400) return Math.floor(diff / 3600) + "h"
        if (diff < 604800) return Math.floor(diff / 86400) + "d"
        return Math.floor(diff / 604800) + "w"
    }
    
    function refresh() {
        root._cache = {}
        root._cacheTimestamps = {}
        root.fetchPosts()
    }
    
    function openPost(post) {
        root._openUrlFocusBrowser(post.permalink)
    }
    
    function openImage(post) {
        root._openUrlFocusBrowser(post.url)
    }
    
    function _openUrlFocusBrowser(url) {
        // Release the sidebar's keyboard focus before handing the URL to the
        // browser. Waiting one event-loop turn lets the panel close first.
        GlobalStates.sidebarLeftOpen = false
        Qt.callLater(() => {
            // Try to focus an existing browser window first on Niri. On
            // Hyprland, opening the URL activates the browser through xdg-open.
            if (typeof NiriService !== "undefined" && NiriService.windows) {
                const browserPatterns = ["firefox", "chromium", "chrome", "brave", "zen", "librewolf", "vivaldi", "opera"]
                const windows = NiriService.windows ?? []
                for (let i = 0; i < windows.length; i++) {
                    const win = windows[i]
                    const appId = (win.app_id ?? "").toLowerCase()
                    if (browserPatterns.some(p => appId.includes(p))) {
                        NiriService.focusWindow(win.id)
                        break
                    }
                }
            }
            Qt.openUrlExternally(url)
        })
    }
}
