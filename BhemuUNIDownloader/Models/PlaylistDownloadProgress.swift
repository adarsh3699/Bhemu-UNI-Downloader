//
//  PlaylistDownloadProgress.swift
//  Bhemu UNI Downloader
//
//  Description: Tracks progress for playlist downloads
//

import Foundation

/// Progress tracking for individual playlist items
/// Used to display real-time status and progress in the playlist queue UI
struct PlaylistItemProgress: Identifiable {
    /// Unique identifier for the playlist item
    let id: UUID
    
    /// Title of the video
    let title: String
    
    /// Current download status
    var status: DownloadItemStatus
    
    /// Download progress (0.0 to 100.0)
    var progress: Double = 0.0
    
    /// Current download speed (e.g., "2.5 MiB/s")
    var speed: String = "N/A"
    
    /// Estimated time of arrival (e.g., "00:15")
    var eta: String = "N/A"
    
    /// Represents the download status of a playlist item
    enum DownloadItemStatus: Equatable {
        /// Item is queued and waiting to start
        case queued
        
        /// Item is currently downloading
        case downloading
        
        /// Item has completed successfully
        case completed
        
        /// Item failed to download
        case failed
        
        /// Item is being retried after failure
        /// - Parameter attempt: Current retry attempt number
        case retrying(attempt: Int)
    }
    
    /// Human-readable status text for display
    var statusText: String {
        switch status {
        case .queued:
            return "Queued"
        case .downloading:
            return "Downloading..."
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .retrying(let attempt):
            return "Retrying (\(attempt))..."
        }
    }
    
    /// Formatted progress percentage string
    var progressPercentage: String {
        String(format: "%.1f%%", progress)
    }
}
