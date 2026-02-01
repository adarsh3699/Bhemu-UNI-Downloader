//
//  YTDLPRunner.swift
//  Bhemu UNI Downloader
//
//  Description: Service for executing yt-dlp as a subprocess with real-time output streaming
//

import Foundation

/// Handles execution of yt-dlp CLI commands
class YTDLPRunner {
    
    // MARK: - Properties
    
    private var process: Process?
    private let ytdlpPath: String
    private let ffmpegPath: String
    
    // Store download info for resume
    private var currentURL: String?
    private var currentQuality: DownloadQuality?
    private var currentOutputDirectory: URL?
    private var currentSettings: DownloadSettings?
    private var currentPlaylistIndex: Int?
    private var isPaused: Bool = false
    
    // MARK: - Initialization
    
    init() {
        // Priority: 1. Bundled resources, 2. System binaries
        self.ytdlpPath = Self.findBinary(name: "yt-dlp")
        self.ffmpegPath = Self.findBinary(name: "ffmpeg")
        
        print("📍 Using yt-dlp at: \(ytdlpPath)")
        print("📍 Using ffmpeg at: \(ffmpegPath)")
    }
    
    // MARK: - Binary Discovery
    
    /// Finds a binary: checks SYSTEM paths first for performance, then bundled resources
    private static func findBinary(name: String) -> String {
        // 1. Common system paths (HIGHEST PRIORITY - much faster for yt-dlp)
        let commonPaths = [
            "/opt/homebrew/bin/\(name)",      // Apple Silicon Homebrew
            "/usr/local/bin/\(name)",          // Intel Homebrew
            "/usr/bin/\(name)",                // System
            "/bin/\(name)"                     // System
        ]
        
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("✅ Found system \(name) at \(path) (faster)")
                return path
            }
        }
        
        // 2. Check bundled resources (slower PyInstaller startup for yt-dlp)
        if let bundledPath = Bundle.main.path(forResource: name, ofType: nil) {
            if FileManager.default.fileExists(atPath: bundledPath) {
                print("✅ Found bundled \(name) (slower startup - consider: brew install \(name))")
                return bundledPath
            }
        }
        
        // 3. Check Resources folder in bundle
        let resourcesPath = Bundle.main.resourcePath
        if let resourcesPath = resourcesPath {
            let bundledInResources = "\(resourcesPath)/\(name)"
            if FileManager.default.fileExists(atPath: bundledInResources) {
                print("✅ Found bundled \(name) in Resources (slower startup - consider: brew install \(name))")
                return bundledInResources
            }
        }
        
        // 4. Fallback: Use 'which' command to find in PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Suppress errors
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    print("✅ Found \(name) via 'which' at \(path)")
                    return path
                }
            }
        } catch {
            print("⚠️ Failed to find \(name) using 'which': \(error)")
        }
        
        // 5. Last resort fallback
        print("⚠️ \(name) not found, using default path")
        return "/opt/homebrew/bin/\(name)"
    }
    
    // MARK: - Binary Detection
    
    /// Checks if yt-dlp is installed at the expected location
    func checkYTDLPInstallation() -> Bool {
        return FileManager.default.fileExists(atPath: ytdlpPath)
    }
    
    /// Checks if ffmpeg is installed at the expected location
    func checkFFmpegInstallation() -> Bool {
        return FileManager.default.fileExists(atPath: ffmpegPath)
    }
    
    /// Returns a user-friendly error message if dependencies are missing
    func getMissingDependenciesMessage() -> String? {
        var missing: [String] = []
        
        if !checkYTDLPInstallation() {
            missing.append("yt-dlp")
        }
        if !checkFFmpegInstallation() {
            missing.append("ffmpeg")
        }
        
        if missing.isEmpty {
            return nil
        }
        
        return """
        Missing dependencies: \(missing.joined(separator: ", "))
        
        Install via Homebrew:
        brew install yt-dlp ffmpeg
        """
    }
    
    // MARK: - Download Execution
    
    /// Starts a download with the specified parameters
    /// - Parameters:
    ///   - url: Video/playlist URL
    ///   - quality: Quality preset
    ///   - outputDirectory: Destination folder
    ///   - settings: Download settings (subtitles, retry, etc.)
    ///   - onOutput: Callback for stdout lines
    ///   - onError: Callback for stderr lines
    ///   - onCompletion: Callback when process terminates
    func startDownload(
        url: String,
        quality: DownloadQuality,
        outputDirectory: URL,
        settings: DownloadSettings,
        playlistIndex: Int? = nil,
        onOutput: @escaping (String) -> Void,
        onError: @escaping (String) -> Void,
        onCompletion: @escaping (Bool) -> Void
    ) {
        // Store current download info for potential resume
        currentURL = url
        currentQuality = quality
        currentOutputDirectory = outputDirectory
        currentSettings = settings
        currentPlaylistIndex = playlistIndex
        isPaused = false
        
        // Cancel any existing process
        cancel()
        
        // Create new process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        
        // Build arguments
        var arguments: [String] = []
        
        // Add quality-specific format arguments
        arguments.append(contentsOf: quality.formatArguments)
        
        // Add fallback to best available if specific format not found
        // This helps when YouTube blocks certain formats
        arguments.append("--ignore-errors")
        arguments.append("--no-abort-on-error")
        
        // Specify ffmpeg location explicitly
        arguments.append("--ffmpeg-location")
        arguments.append(ffmpegPath)
        
        // Subtitle options
        if settings.downloadSubtitles {
            arguments.append("--write-subs")        // Download manual subtitles
            arguments.append("--write-auto-subs")   // Download auto-generated subtitles
            arguments.append("--sub-langs")
            arguments.append(settings.subtitleLanguages)
            arguments.append("--ignore-errors")     // Continue if subtitle download fails (e.g., 429)
            
            if settings.embedSubtitles && quality != .audioOnly {
                arguments.append("--embed-subs")
                
                // Clean up subtitle files after embedding if requested
                if !settings.keepSubtitleFiles {
                    // Note: yt-dlp doesn't have a built-in flag for this
                    // We'll handle cleanup in the completion handler
                }
            }
        }
        
        // Browser cookies for bot detection
        if settings.useBrowserCookies {
            arguments.append("--cookies-from-browser")
            arguments.append(settings.browserForCookies)
        }
        
        // JS Runtime for bot detection (Critical for YouTube)
        if let jsRuntime = findJSRuntime() {
            arguments.append("--js-runtimes")
            arguments.append("\(jsRuntime.name):\(jsRuntime.path)")
        }
        
        // Custom filename template with quality info
        arguments.append("-o")
        if let index = playlistIndex {
            let prefix = String(format: "%02d ", index)
            arguments.append("\(prefix)%(title)s [%(resolution)s].%(ext)s")
        } else {
            arguments.append("%(title)s [%(resolution)s].%(ext)s")
        }
        
        // Enable continue/resume capability
        arguments.append("--continue")
        arguments.append("--no-part")  // Don't use .part files for cleaner resume
        
        // Add output directory
        arguments.append("-P")
        arguments.append(outputDirectory.path)
        
        // Add progress template for parsing
        arguments.append("--progress-template")
        arguments.append("%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s")
        
        // Add URL
        arguments.append(url)
        
        process.arguments = arguments
        
        #if DEBUG
        print("🚀 Executing command: \(ytdlpPath) \(arguments.joined(separator: " "))")
        #endif
        
        // Set up stdout pipe
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        // Set up stderr pipe
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        // Read stdout asynchronously
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                DispatchQueue.main.async {
                    onOutput(output)
                }
            }
        }
        
        // Read stderr asynchronously
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let error = String(data: data, encoding: .utf8), !error.isEmpty {
                DispatchQueue.main.async {
                    onError(error)
                }
            }
        }
        
        // Handle process termination
        process.terminationHandler = { [weak self] terminatedProcess in
            // Clean up file handle callbacks
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            let success = terminatedProcess.terminationStatus == 0
            
            // Clean up subtitle files if requested
            if success && settings.embedSubtitles && !settings.keepSubtitleFiles {
                self?.cleanupSubtitleFiles(in: outputDirectory)
            }
            
            DispatchQueue.main.async {
                onCompletion(success)
            }
            
            self?.process = nil
        }
        
        // Launch process
        do {
            try process.run()
            self.process = process
        } catch {
            DispatchQueue.main.async {
                onError("Failed to start yt-dlp: \(error.localizedDescription)")
                onCompletion(false)
            }
        }
    }
    
    /// Cancels the currently running download
    func cancel() {
        guard let process = process, process.isRunning else {
            return
        }
        
        isPaused = false
        currentURL = nil
        currentQuality = nil
        currentOutputDirectory = nil
        currentSettings = nil
        currentPlaylistIndex = nil
        
        process.terminate()
        self.process = nil
    }
    
    /// Pauses the currently running download
    func pause() {
        guard let process = process, process.isRunning else {
            return
        }
        
        isPaused = true
        // Terminate the process cleanly (yt-dlp will be restarted with --continue)
        process.terminate()
        // Don't set self.process = nil yet, let terminationHandler do it
    }
    
    /// Resumes a paused download
    func resume(
        onOutput: @escaping (String) -> Void,
        onError: @escaping (String) -> Void,
        onCompletion: @escaping (Bool) -> Void
    ) {
        // Restart download with --continue flag
        guard let url = currentURL,
              let quality = currentQuality,
              let outputDir = currentOutputDirectory,
              let settings = currentSettings else {
            return
        }
        
        isPaused = false
        startDownload(
            url: url,
            quality: quality,
            outputDirectory: outputDir,
            settings: settings,
            playlistIndex: currentPlaylistIndex,
            onOutput: onOutput,
            onError: onError,
            onCompletion: onCompletion
        )
    }
    
    /// Returns true if a download is currently in progress
    var isRunning: Bool {
        return process?.isRunning ?? false
    }
    
    /// Returns true if download is paused
    var isCurrentlyPaused: Bool {
        return isPaused
    }
    
    // MARK: - Subtitle Cleanup
    
    /// Removes subtitle files after successful embedding
    private func cleanupSubtitleFiles(in directory: URL) {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            // Find and delete subtitle files (.vtt, .srt, .ass, .ssa)
            let subtitleExtensions = ["vtt", "srt", "ass", "ssa"]
            
            for fileURL in contents {
                let fileExtension = fileURL.pathExtension.lowercased()
                
                // Check if it's a subtitle file
                if subtitleExtensions.contains(fileExtension) {
                    // Additional check: only delete if there's a corresponding video file
                    let videoName = fileURL.deletingPathExtension().lastPathComponent
                    let hasCorrespondingVideo = contents.contains { videoURL in
                        let videoExtensions = ["mp4", "webm", "mkv", "mov", "avi"]
                        return videoExtensions.contains(videoURL.pathExtension.lowercased()) &&
                               videoURL.lastPathComponent.hasPrefix(videoName.components(separatedBy: ".").first ?? "")
                    }
                    
                    if hasCorrespondingVideo {
                        try? fileManager.removeItem(at: fileURL)
                        print("🗑️ Cleaned up subtitle file: \(fileURL.lastPathComponent)")
                    }
                }
            }
        } catch {
            print("⚠️ Error cleaning up subtitle files: \(error)")
        }
    }
    
    // MARK: - JS Runtime Detection
    
    /// Finds a supported JS runtime (deno or node) to bypass YouTube bot detection
    private func findJSRuntime() -> (name: String, path: String)? {
        // Priority: 1. Deno (preferred by yt-dlp), 2. Node
        
        // Check for Deno
        let denoPaths = [
            "/opt/homebrew/bin/deno",
            "/usr/local/bin/deno",
            "/usr/bin/deno",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/.deno/bin/deno"
        ]
        
        for path in denoPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("✅ Found JS runtime: deno at \(path)")
                return ("deno", path)
            }
        }
        
        // Check for Node
        let nodePaths = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node"
            // Node might be in nvm paths, but standard install paths are safest to check first
        ]
        
        for path in nodePaths {
            if FileManager.default.fileExists(atPath: path) {
                print("✅ Found JS runtime: node at \(path)")
                return ("node", path)
            }
        }
        
        // Fallback: try `which` for both
        for tool in ["deno", "node"] {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = [tool]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !path.isEmpty {
                        print("✅ Found JS runtime via which: \(tool) at \(path)")
                        return (tool, path)
                    }
                }
            } catch {
                continue
            }
        }
        
        print("⚠️ No supported JS runtime (deno/node) found. YouTube downloads may fail.")
        return nil
    }
}
