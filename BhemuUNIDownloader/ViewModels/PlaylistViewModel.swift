//
//  PlaylistViewModel.swift
//  Bhemu UNI Downloader
//
//  Author: Adarsh Suman (adarsh3699@gmail.com)
//  Website: https://bhemu.in
//  Description: ViewModel for managing playlist data and selections
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PlaylistViewModel: ObservableObject {
    @Published var playlistTitle: String = ""
    @Published var videos: [PlaylistItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var rangeInput: String = ""
    
    private let ytdlpRunner = YTDLPRunner()
    
    var selectedCount: Int {
        videos.filter { $0.isSelected }.count
    }
    
    var selectedVideos: [PlaylistItem] {
        videos.filter { $0.isSelected }
    }
    
    /// Fetches playlist information from yt-dlp
    func fetchPlaylist(url: String) async {
        // Set loading state and give UI time to update
        isLoading = true
        errorMessage = nil
        videos = []  // Clear previous videos
        
        // Yield to let UI update
        await Task.yield()
        
        // Find yt-dlp binary
        guard let ytdlpPath = findYtdlpPath() else {
            errorMessage = "yt-dlp not found. Please install it first."
            isLoading = false
            return
        }
        
        // Run the blocking process on a background thread
        let result = await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ytdlpPath)
            
            let arguments = [
                "--flat-playlist",
                "--dump-json",
                "--no-warnings",
                url
            ]
            process.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                
                // Read output asynchronously
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                process.waitUntilExit()
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                
                if process.terminationStatus == 0 {
                    return (success: true, output: output, error: "")
                } else {
                    return (success: false, output: "", error: errorOutput.isEmpty ? "Unknown error" : errorOutput)
                }
                
            } catch {
                return (success: false, output: "", error: error.localizedDescription)
            }
        }.value
        
        // Update UI on main actor
        if result.success {
            parsePlaylistOutput(result.output)
            
            // If no videos found, show error
            if videos.isEmpty {
                errorMessage = "No videos found in playlist or invalid URL"
            }
        } else {
            errorMessage = "Failed to fetch playlist: \(result.error)"
        }
        
        // Always set loading to false at the end
        isLoading = false
    }
    
    private func parsePlaylistOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var items: [PlaylistItem] = []
        
        print("📊 Parsing \(lines.count) lines from yt-dlp output")
        
        for line in lines {
            if let data = line.data(using: .utf8),
               let json = try? JSONDecoder().decode(PlaylistEntry.self, from: data) {
                let item = PlaylistItem(
                    id: json.id ?? UUID().uuidString,
                    title: json.title ?? "Unknown",
                    duration: json.duration,
                    url: json.url ?? "",
                    thumbnail: json.thumbnail,
                    originalIndex: items.count + 1
                )
                items.append(item)
            } else {
                print("⚠️ Failed to parse line: \(line.prefix(100))...")
            }
        }
        
        print("✅ Parsed \(items.count) videos")
        
        videos = items
        
        if !items.isEmpty {
            playlistTitle = "Playlist (\(items.count) videos)"
        }
    }
    
    struct PlaylistEntry: Codable {
        let id: String?
        let title: String?
        let duration: Int?
        let url: String?
        let thumbnail: String?
    }
    
    /// Finds yt-dlp binary path
    private func findYtdlpPath() -> String? {
        let commonPaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        
        // Check common paths first
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try `which` command as fallback
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["yt-dlp"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            print("⚠️ Failed to find yt-dlp: \(error)")
        }
        
        return nil
    }
    
    /// Toggles selection for a video
    func toggleSelection(for id: String) {
        if let index = videos.firstIndex(where: { $0.id == id }) {
            videos[index].isSelected.toggle()
        }
    }
    
    /// Selects all videos
    func selectAll() {
        for index in videos.indices {
            videos[index].isSelected = true
        }
    }
    
    /// Deselects all videos
    func deselectAll() {
        for index in videos.indices {
            videos[index].isSelected = false
        }
    }
    
    /// Applies range selection (e.g., "1-5" or "10-15")
    func applyRange() {
        guard !rangeInput.isEmpty else { return }
        
        // Parse range like "1-5" or "10-15"
        let components = rangeInput.components(separatedBy: "-")
        guard components.count == 2,
              let start = Int(components[0]),
              let end = Int(components[1]),
              start > 0,
              end <= videos.count,
              start <= end else {
            errorMessage = "Invalid range. Use format: 1-5"
            return
        }
        
        // Deselect all first
        deselectAll()
        
        // Select range (1-based indexing for user, 0-based for array)
        for index in (start - 1)..<end {
            videos[index].isSelected = true
        }
    }
}
