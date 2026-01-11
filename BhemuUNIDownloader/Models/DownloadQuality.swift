//
//  DownloadQuality.swift
//  Bhemu UNI Downloader
//
//  Description: Enum representing available download quality options
//

import Foundation

enum DownloadQuality: String, CaseIterable, Identifiable {
    case best = "Best Quality (4K if available)"
    case p1440 = "1440p (VP9/AV1)"
    case p1080 = "1080p MP4 (H.264)"
    case p720 = "720p MP4 (H.264)"
    case p480 = "480p MP4 (H.264)"
    case audioOnly = "Audio Only (MP3)"
    
    var id: String { rawValue }
    
    /// Returns yt-dlp format arguments for the selected quality
    var formatArguments: [String] {
        switch self {
        case .best:
            // Absolute best quality - includes 4K/8K VP9/AV1 (may be WEBM, smaller file)
            return ["-f", "bestvideo+bestaudio/best"]
        case .p1440:
            // 1440p (2K) - any codec (VP9/AV1), YouTube doesn't offer H.264 at this resolution
            return ["-f", "bestvideo[height<=1440]+bestaudio/best", "--merge-output-format", "mp4"]
        case .p1080:
            // 1080p H.264 MP4 (larger file, better compatibility, better quality than VP9)
            return ["-f", "bv*[vcodec^=avc1][height<=1080]+ba/bv*[ext=mp4][height<=1080]+ba/best", "--merge-output-format", "mp4"]
        case .p720:
            // 720p H.264 MP4
            return ["-f", "bv*[vcodec^=avc1][height<=720]+ba/bv*[ext=mp4][height<=720]+ba/best", "--merge-output-format", "mp4"]
        case .p480:
            // 480p H.264 MP4
            return ["-f", "bv*[vcodec^=avc1][height<=480]+ba/bv*[ext=mp4][height<=480]+ba/best", "--merge-output-format", "mp4"]
        case .audioOnly:
            // Best audio quality MP3 (quality 0 = highest, 320kbps)
            return ["-x", "--audio-format", "mp3", "--audio-quality", "0"]
        }
    }
}
