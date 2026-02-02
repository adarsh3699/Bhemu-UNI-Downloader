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
        let process = Process()
        
        return await withTaskCancellationHandler {
            // Run on background thread to avoid blocking UI
            return await Task.detached(priority: .userInitiated) {
                let ytdlpPath = findYtdlpPath()
                
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
        } onCancel: {
            print("🛑 Cancelling format fetch process")
            process.terminate()
        }
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
    
    /// Fetches available subtitle languages for a given URL
    static func fetchAvailableSubtitles(for url: String) async -> [SubtitleLanguage] {
        let process = Process()
        
        return await withTaskCancellationHandler {
            return await Task.detached(priority: .userInitiated) {
                let ytdlpPath = findYtdlpPath()
                
                process.executableURL = URL(fileURLWithPath: ytdlpPath)
                
                // Use --list-subs to get available subtitles
                let arguments = [
                    "--list-subs",
                    "--no-warnings",
                    "--socket-timeout", "8",
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
                        print("⚠️ Failed to fetch subtitles")
                        return []
                    }
                    
                    return Self.parseSubtitlesList(output)
                    
                } catch {
                    print("⚠️ Error fetching subtitles: \(error)")
                    return []
                }
            }.value
        } onCancel: {
            print("🛑 Cancelling subtitle fetch process")
            process.terminate()
        }
    }
    
    /// Parse subtitle list from --list-subs output
    private nonisolated static func parseSubtitlesList(_ output: String) -> [SubtitleLanguage] {
        var subtitles: [SubtitleLanguage] = []
        var seenCodes = Set<String>()
        
        let lines = output.components(separatedBy: .newlines)
        var inSubtitleSection = false
        var isAutoGenerated = false
        
        for line in lines {
            // Detect subtitle section types
            if line.contains("Available subtitles") {
                inSubtitleSection = true
                isAutoGenerated = false
                continue
            }
            
            if line.contains("automatic captions") || line.contains("auto-generated") {
                inSubtitleSection = true
                isAutoGenerated = true
                continue
            }
            
            // Skip empty lines and headers
            if line.trimmingCharacters(in: .whitespaces).isEmpty || line.contains("Language") {
                continue
            }
            
            // Parse subtitle line (format: "en    English   vtt, srv3, srv2, srv1")
            if inSubtitleSection {
                let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                
                if components.count >= 2 {
                    let code = components[0]
                    let name = components[1...].joined(separator: " ").components(separatedBy: "vtt").first?
                        .trimmingCharacters(in: .whitespaces) ?? components[1]
                    
                    // Only add valid language codes (2-5 chars, alphanumeric with possible hyphens)
                    if code.count >= 2 && code.count <= 5 && !seenCodes.contains(code) {
                        seenCodes.insert(code)
                        subtitles.append(SubtitleLanguage(
                            code: code,
                            name: name,
                            isAutoGenerated: isAutoGenerated,
                            isCommon: false
                        ))
                    }
                }
            }
        }
        
        print("📝 Found \(subtitles.count) subtitle languages")
        return subtitles.sorted { $0.name < $1.name }
    }
}

/// Represents a subtitle language option
struct SubtitleLanguage: Identifiable, Equatable, Sendable {
    let id = UUID()
    let code: String
    let name: String
    let isAutoGenerated: Bool
    let isCommon: Bool // True if from common languages list (not video-specific)
    
    nonisolated init(code: String, name: String, isAutoGenerated: Bool = false, isCommon: Bool = false) {
        self.code = code
        self.name = name
        self.isAutoGenerated = isAutoGenerated
        self.isCommon = isCommon
    }
    
    var displayName: String {
        if isAutoGenerated {
            return "\(name) (auto)"
        }
        return name
    }
    
    /// Common subtitle languages to show when platform doesn't support listing
    static let commonLanguages: [SubtitleLanguage] = [
        SubtitleLanguage(code: "en", name: "English", isCommon: true),
        SubtitleLanguage(code: "hi", name: "Hindi", isCommon: true),
        SubtitleLanguage(code: "es", name: "Spanish", isCommon: true),
        SubtitleLanguage(code: "fr", name: "French", isCommon: true),
        SubtitleLanguage(code: "de", name: "German", isCommon: true),
        SubtitleLanguage(code: "pt", name: "Portuguese", isCommon: true),
        SubtitleLanguage(code: "it", name: "Italian", isCommon: true),
        SubtitleLanguage(code: "ja", name: "Japanese", isCommon: true),
        SubtitleLanguage(code: "ko", name: "Korean", isCommon: true),
        SubtitleLanguage(code: "zh", name: "Chinese", isCommon: true),
        SubtitleLanguage(code: "ar", name: "Arabic", isCommon: true),
        SubtitleLanguage(code: "ru", name: "Russian", isCommon: true),
        SubtitleLanguage(code: "ta", name: "Tamil", isCommon: true),
        SubtitleLanguage(code: "te", name: "Telugu", isCommon: true),
        SubtitleLanguage(code: "ml", name: "Malayalam", isCommon: true),
        SubtitleLanguage(code: "kn", name: "Kannada", isCommon: true),
        SubtitleLanguage(code: "bn", name: "Bengali", isCommon: true),
        SubtitleLanguage(code: "mr", name: "Marathi", isCommon: true),
        SubtitleLanguage(code: "pa", name: "Punjabi", isCommon: true),
        SubtitleLanguage(code: "gu", name: "Gujarati", isCommon: true)
    ]
}
