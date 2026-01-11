//
//  DownloadProgress.swift
//  Bhemu UNI Downloader
//
//  Description: Model for tracking download progress metrics
//

import Foundation

/// Represents the current progress of a download operation
/// Tracks percentage completion, speed, ETA, and current file being downloaded
struct DownloadProgress {
    /// Download progress percentage (0.0 to 100.0)
    var percentage: Double = 0.0
    
    /// Current download speed (e.g., "2.5 MiB/s")
    var speed: String = "N/A"
    
    /// Estimated time of arrival (e.g., "00:15")
    var eta: String = "N/A"
    
    /// Name of the file currently being downloaded
    var currentFile: String = ""
    
    /// Returns formatted percentage string with 1 decimal place
    var percentageFormatted: String {
        String(format: "%.1f%%", percentage)
    }
}
