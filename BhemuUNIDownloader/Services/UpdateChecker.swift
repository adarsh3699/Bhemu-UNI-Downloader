//
//  UpdateChecker.swift
//  Bhemu UNI Downloader
//
//  Description: Service to check for tool updates using Homebrew
//

import Foundation

class UpdateChecker {
    
    /// Checks if yt-dlp has an update available via Homebrew
    static func checkForUpdates() async -> Bool {
        // Run on background thread
        return await Task.detached(priority: .userInitiated) {
            // Check if Homebrew is installed first
            let brewPath = findBrewPath()
            guard !brewPath.isEmpty else {
                return false // Can't check without brew
            }
            
            print("🔍 Checking for yt-dlp updates...")
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["outdated", "yt-dlp"]
            
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // If output contains "yt-dlp", it means it's outdated
                    let hasUpdate = output.contains("yt-dlp")
                    print(hasUpdate ? "✨ yt-dlp update available" : "✅ yt-dlp is up to date")
                    return hasUpdate
                }
                
                return false
            } catch {
                print("⚠️ Failed to check for updates: \(error)")
                return false
            }
        }.value
    }
    
    private nonisolated static func findBrewPath() -> String {
        let commonPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return ""
    }
}
