//
//  VideoFormatInfo.swift
//  Bhemu UNI Downloader
//
//  Description: Model for video format information
//

import Foundation

struct VideoFormatInfo {
    let resolution: String
    let fps: Int?
    let codec: String?
    let formatId: String
    
    var height: Int? {
        // Extract height from resolution like "1920x1080" -> 1080
        let components = resolution.split(separator: "x")
        if components.count == 2, let h = Int(components[1]) {
            return h
        }
        return nil
    }
}

struct AvailableQualities: Sendable {
    let has4K: Bool
    let has1440p: Bool
    let has1080p: Bool
    let has720p: Bool
    let has480p: Bool
    let hasAudio: Bool
    
    nonisolated static let all = AvailableQualities(
        has4K: true,
        has1440p: true,
        has1080p: true,
        has720p: true,
        has480p: true,
        hasAudio: true
    )
    
    nonisolated static let none = AvailableQualities(
        has4K: false,
        has1440p: false,
        has1080p: false,
        has720p: false,
        has480p: false,
        hasAudio: false
    )
    
    /// Returns filtered quality options based on availability
    func availableOptions() -> [DownloadQuality] {
        var options: [DownloadQuality] = []
        
        if has4K {
            options.append(.best)
        }
        if has1440p {
            options.append(.p1440)
        }
        if has1080p {
            options.append(.p1080)
        }
        if has720p {
            options.append(.p720)
        }
        if has480p {
            options.append(.p480)
        }
        if hasAudio {
            options.append(.audioOnly)
        }
        
        return options
    }
}
