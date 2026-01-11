//
//  DownloadSettings.swift
//  Bhemu UNI Downloader
//
//  Description: User preferences and download settings
//

import Foundation

struct DownloadSettings: Sendable {
    /// Maximum number of concurrent downloads for playlists
    var maxConcurrentDownloads: Int = 3
    
    /// Whether to retry failed downloads automatically
    var autoRetryOnFailure: Bool = true
    
    /// Maximum number of retry attempts
    var maxRetryAttempts: Int = 3
    
    /// Whether to download subtitles
    var downloadSubtitles: Bool = false
    
    /// Subtitle languages (e.g., "en,es,fr")
    var subtitleLanguages: String = "en"
    
    /// Whether to embed subtitles in video
    var embedSubtitles: Bool = true
    
    /// Whether to keep separate subtitle files after embedding
    var keepSubtitleFiles: Bool = false
    
    /// Use cookies from browser to avoid bot detection (chrome, firefox, safari, edge, brave, etc.)
    var useBrowserCookies: Bool = false
    
    /// Browser to use for cookies (chrome, firefox, safari, edge, brave, etc.)
    var browserForCookies: String = "chrome"
    
    static let shared = DownloadSettings()
}
