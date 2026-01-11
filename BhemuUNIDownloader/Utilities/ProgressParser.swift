//
//  ProgressParser.swift
//  Bhemu UNI Downloader
//
//  Description: Utility to parse yt-dlp stdout for progress information
//

import Foundation

struct ProgressParser {
    
    /// Parses a single line of yt-dlp output and extracts progress information
    /// Expected format from --progress-template: "percentage|speed|eta"
    static func parse(line: String, currentProgress: inout DownloadProgress) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if this is a progress line with our custom template
        if trimmed.contains("|") {
            let components = trimmed.components(separatedBy: "|")
            
            if components.count >= 3 {
                // Parse percentage
                if let percentStr = components[0].components(separatedBy: .whitespaces).first,
                   let percent = Double(percentStr.replacingOccurrences(of: "%", with: "")) {
                    currentProgress.percentage = percent
                }
                
                // Parse speed
                let speed = components[1].trimmingCharacters(in: .whitespaces)
                if !speed.isEmpty && speed != "N/A" {
                    currentProgress.speed = speed
                }
                
                // Parse ETA
                let eta = components[2].trimmingCharacters(in: .whitespaces)
                if !eta.isEmpty && eta != "N/A" {
                    currentProgress.eta = eta
                }
            }
        }
        
        // Extract filename from download lines
        if trimmed.contains("[download] Destination:") {
            let parts = trimmed.components(separatedBy: "[download] Destination:")
            if parts.count > 1 {
                let filename = parts[1].trimmingCharacters(in: .whitespaces)
                currentProgress.currentFile = (filename as NSString).lastPathComponent
            }
        }
        
        // Handle completion
        if trimmed.contains("[download] 100%") || trimmed.contains("has already been downloaded") {
            currentProgress.percentage = 100.0
        }
    }
    
    /// Extracts error messages from yt-dlp output
    static func extractError(from output: String) -> String? {
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines.reversed() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().contains("error") {
                return trimmed
            }
        }
        
        return nil
    }
}
