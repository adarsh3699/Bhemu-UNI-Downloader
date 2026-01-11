//
//  FormatFetcher.swift
//  Bhemu UNI Downloader
//
//  Description: Service to fetch available video formats
//

import Foundation

class FormatFetcher {
    
    /// Timeout for format fetching (in seconds)
    private static let fetchTimeout: TimeInterval = 10.0
    
    /// Fetches available qualities for a given URL with timeout
    static func fetchAvailableQualities(for url: String) async -> AvailableQualities {
        // Run fetch task with timeout
        return await withTaskGroup(of: AvailableQualities.self) { group in
            // Add fetch task
            group.addTask {
                await fetchFormatsInternal(for: url)
            }
            
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(fetchTimeout * 1_000_000_000))
                print("⏱️ Format fetch timeout reached")
                return .all // Fallback to showing all options
            }
            
            // Return first completed task (either fetch or timeout)
            if let result = await group.next() {
                group.cancelAll() // Cancel remaining tasks
                return result
            }
            
            return .all // Fallback if both tasks fail
        }
    }
    
    /// Internal method to fetch formats from yt-dlp
    private static func fetchFormatsInternal(for url: String) async -> AvailableQualities {
        // Run on background thread to avoid blocking UI
        return await Task.detached(priority: .userInitiated) {
            let ytdlpPath = findYtdlpPath()
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ytdlpPath)
            
            // Use -F to list formats (much faster than --dump-json)
            let arguments = [
                "-F",  // List available formats
                "--no-warnings",
                "--socket-timeout", "8", // Network timeout
                url
            ]
            process.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                
                guard process.terminationStatus == 0,
                      let output = String(data: outputData, encoding: .utf8) else {
                    print("⚠️ Failed to fetch formats")
                    return .all // Fallback to showing all options
                }
                
                return Self.parseFormatsList(output)
                
            } catch {
                print("⚠️ Error fetching formats: \(error)")
                return .all // Fallback to showing all options
            }
        }.value
    }
    
    /// Finds yt-dlp binary path: PRIORITIZES system paths for performance, then bundled
    private nonisolated static func findYtdlpPath() -> String {
        // 1. System paths FIRST (much faster - 0.26s vs 10s for PyInstaller binary)
        let commonPaths = [
            "/opt/homebrew/bin/yt-dlp",      // Apple Silicon Homebrew
            "/usr/local/bin/yt-dlp",          // Intel Homebrew
            "/usr/bin/yt-dlp"                 // System
        ]
        
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("✅ FormatFetcher using system yt-dlp (fast)")
                return path
            }
        }
        
        // 2. Check bundled resources (slower but works without dependencies)
        if let bundledPath = Bundle.main.path(forResource: "yt-dlp", ofType: nil) {
            if FileManager.default.fileExists(atPath: bundledPath) {
                print("⚠️ FormatFetcher using bundled yt-dlp (slower startup)")
                return bundledPath
            }
        }
        
        // 3. Check Resources folder
        if let resourcesPath = Bundle.main.resourcePath {
            let bundledInResources = "\(resourcesPath)/yt-dlp"
            if FileManager.default.fileExists(atPath: bundledInResources) {
                print("⚠️ FormatFetcher using bundled yt-dlp (slower startup)")
                return bundledInResources
            }
        }
        
        return "/opt/homebrew/bin/yt-dlp" // Default fallback
    }
    
    /// Parse format list from -F output (faster than JSON parsing)
    private nonisolated static func parseFormatsList(_ output: String) -> AvailableQualities {
        var has4K = false
        var has1440p = false
        var has1080p = false
        var has720p = false
        var has480p = false
        let hasAudio = true // Audio is almost always available
        
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            // Skip header lines and audio-only lines
            if line.contains("ID") || line.contains("audio only") {
                continue
            }
            
            // Extract resolution height using multiple methods
            let height = extractHeight(from: line)
            
            if let h = height {
                if h >= 2160 {
                    has4K = true
                } else if h >= 1440 {
                    has1440p = true
                } else if h >= 1080 {
                    has1080p = true
                } else if h >= 720 {
                    has720p = true
                } else if h >= 480 {
                    has480p = true
                }
            }
        }
        
        print("📊 Available qualities: 4K=\(has4K), 1440p=\(has1440p), 1080p=\(has1080p), 720p=\(has720p), 480p=\(has480p)")
        
        return AvailableQualities(
            has4K: has4K,
            has1440p: has1440p,
            has1080p: has1080p,
            has720p: has720p,
            has480p: has480p,
            hasAudio: hasAudio
        )
    }
    
    /// Extract height from format line using multiple patterns
    private nonisolated static func extractHeight(from line: String) -> Int? {
        // Pattern 1: "1920x1080" format
        if let match = line.range(of: #"(\d{3,4})x(\d{3,4})"#, options: .regularExpression) {
            let resolution = String(line[match])
            let parts = resolution.split(separator: "x")
            if parts.count == 2, let height = Int(parts[1]) {
                return height
            }
        }
        
        // Pattern 2: "1080p" format
        if let match = line.range(of: #"(\d{3,4})p"#, options: .regularExpression) {
            let resString = String(line[match]).replacingOccurrences(of: "p", with: "")
            if let height = Int(resString) {
                return height
            }
        }
        
        // Pattern 3: Look for common dimensions in any format
        // Instagram, TikTok often use patterns like "1080 " or " 1080"
        let numberPattern = #"\b(\d{3,4})\b"#
        if let regex = try? NSRegularExpression(pattern: numberPattern) {
            let nsString = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if let range = Range(match.range, in: line) {
                    let numString = String(line[range])
                    if let num = Int(numString), num >= 240 && num <= 4320 {
                        // Valid video height range (240p to 8K)
                        return num
                    }
                }
            }
        }
        
        return nil
    }
}
