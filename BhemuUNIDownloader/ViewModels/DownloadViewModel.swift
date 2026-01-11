//
//  DownloadViewModel.swift
//  Bhemu UNI Downloader
//
//  Description: ViewModel managing download state and coordinating between UI and yt-dlp service
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DownloadViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var videoURL: String = ""
    @Published var selectedQuality: DownloadQuality = .p1080
    @Published var outputDirectory: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
    
    @Published var downloadState: DownloadState = .idle
    @Published var progress: DownloadProgress = DownloadProgress()
    @Published var logOutput: String = ""
    
    // Playlist support
    @Published var isPlaylist: Bool = false
    @Published var showPlaylistSheet: Bool = false
    @Published var playlistProgress: [PlaylistItemProgress] = []
    @Published var showPlaylistProgress: Bool = false
    
    // Available qualities for current video
    @Published var availableQualities: [DownloadQuality] = DownloadQuality.allCases
    @Published var isFetchingFormats: Bool = false
    
    // Subtitle options
    @Published var downloadSubtitles: Bool = false
    @Published var subtitleLanguages: String = "en"
    @Published var embedSubtitles: Bool = true  // Default: embed when subtitles enabled
    @Published var keepSubtitleFiles: Bool = false  // Default: delete after embedding
    
    // Browser cookies for bot detection (persisted)
    @AppStorage("useBrowserCookies") var useBrowserCookies: Bool = false
    @AppStorage("browserForCookies") var browserForCookies: String = "chrome"
    
    // MARK: - Private Properties
    
    private let ytdlpRunner = YTDLPRunner()
    private var urlDebounceTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var settings = DownloadSettings.shared
    
    // Track concurrent downloads
    private var activeDownloadTasks: Set<UUID> = []
    private var downloadQueue: [(id: UUID, item: PlaylistItem)] = []
    private var progressTrackers: [UUID: DownloadProgress] = [:]
    private var isUserPausing: Bool = false  // Flag to prevent retry during pause
    private var activeRunners: [UUID: YTDLPRunner] = [:]  // Track runners for each concurrent download
    private var originalPlaylistItems: [UUID: PlaylistItem] = [:]  // Map progress ID to original item
    
    // MARK: - Initialization
    
    init() {
        // Set up debouncing for URL changes
        $videoURL
            .debounce(for: .milliseconds(800), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkIfPlaylist()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var canStartDownload: Bool {
        return !videoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !downloadState.isRunning
            && !isFetchingFormats  // Disable while fetching quality data
    }
    
    var showDependencyError: Bool {
        return ytdlpRunner.getMissingDependenciesMessage() != nil
    }
    
    var dependencyErrorMessage: String {
        return ytdlpRunner.getMissingDependenciesMessage() ?? ""
    }
    
    // MARK: - Actions
    
    /// Check if URL is a playlist and fetch available qualities
    func checkIfPlaylist() {
        let url = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        isPlaylist = url.contains("playlist") || url.contains("&list=")
        
        // Fetch available qualities for non-playlist URLs
        if !isPlaylist && !url.isEmpty {
            Task {
                await fetchAvailableQualities()
            }
        } else {
            // Reset to all qualities if empty or playlist
            availableQualities = DownloadQuality.allCases
        }
    }
    
    /// Fetches available qualities for the current video URL
    func fetchAvailableQualities() async {
        let url = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty, !isPlaylist else { return }
        
        // Cancel any existing fetch task
        urlDebounceTask?.cancel()
        
        // Create new task
        urlDebounceTask = Task {
            isFetchingFormats = true
            
            let qualities = await FormatFetcher.fetchAvailableQualities(for: url)
            
            // Check if task was cancelled
            guard !Task.isCancelled else {
                isFetchingFormats = false
                return
            }
            
            availableQualities = qualities.availableOptions()
            
            // If current selection is not available, switch to first available
            if !availableQualities.contains(selectedQuality) {
                selectedQuality = availableQualities.first ?? .p1080
            }
            
            isFetchingFormats = false
        }
        
        await urlDebounceTask?.value
    }
    
    /// Validates dependencies and starts the download
    func startDownload() {
        // Check for missing dependencies
        if let error = ytdlpRunner.getMissingDependenciesMessage() {
            downloadState = .failed(error)
            appendLog("❌ \(error)")
            return
        }
        
        // Validate URL
        guard !videoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            downloadState = .failed("Please enter a valid URL")
            appendLog("❌ Please enter a valid URL")
            return
        }
        
        // Check disk space
        if let diskWarning = DiskSpaceChecker.getDiskSpaceWarning(at: outputDirectory) {
            downloadState = .failed(diskWarning)
            appendLog("❌ \(diskWarning)")
            return
        }
        
        // Check if playlist
        checkIfPlaylist()
        if isPlaylist {
            showPlaylistSheet = true
            return
        }
        
        // Reset state
        downloadState = .running
        progress = DownloadProgress()
        logOutput = ""
        isUserPausing = false  // Reset pause flag
        
        appendLog("🚀 Starting download...")
        appendLog("📺 URL: \(videoURL)")
        appendLog("🎬 Quality: \(selectedQuality.rawValue)")
        appendLog("📁 Output: \(outputDirectory.path)")
        
        // Log disk space info
        let (_, freeGB, _) = DiskSpaceChecker.checkDiskSpace(at: outputDirectory)
        appendLog("💾 Available space: \(String(format: "%.2f", freeGB)) GB")
        appendLog("---")
        
        // Start download with retry support
        Task {
            await startDownloadWithRetry()
        }
    }
    
    /// Starts download with automatic retry on failure
    private func startDownloadWithRetry() async {
        var attemptCount = 0
        let maxAttempts = settings.autoRetryOnFailure ? settings.maxRetryAttempts : 1
        
        // Update settings from UI
        let downloadSettings = buildDownloadSettings()
        
        while attemptCount < maxAttempts {
            attemptCount += 1
            
            if attemptCount > 1 {
                await MainActor.run {
                    appendLog("⚠️ Retry attempt \(attemptCount - 1)/\(maxAttempts - 1)")
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
            }
            
            let success = await performDownload(with: downloadSettings)
            
            if success {
                return // Download completed successfully
            }
            
            // Check if download was paused by user (don't retry)
            if isUserPausing || downloadState == .paused {
                return // Don't retry if user is pausing
            }
            
            // Check if download was cancelled by user
            if case .cancelled = downloadState {
                return // Don't retry if user cancelled
            }
        }
        
        // All attempts failed
        await MainActor.run {
            if downloadState != .cancelled && downloadState != .paused {
                let errorMsg = ProgressParser.extractError(from: logOutput) ?? "Download failed after \(maxAttempts) attempts"
                downloadState = .failed(errorMsg)
                appendLog("---")
                appendLog("❌ Download failed after \(maxAttempts) attempts")
            }
        }
    }
    
    /// Performs a single download attempt
    private func performDownload(with settings: DownloadSettings) async -> Bool {
        return await withCheckedContinuation { continuation in
        ytdlpRunner.startDownload(
            url: videoURL,
            quality: selectedQuality,
            outputDirectory: outputDirectory,
                settings: settings,
            onOutput: { [weak self] output in
                self?.handleOutput(output)
            },
            onError: { [weak self] error in
                self?.handleError(error)
            },
            onCompletion: { [weak self] success in
                    Task { @MainActor in
                        if success {
                            self?.downloadState = .completed
                            self?.progress.percentage = 100.0
                            self?.appendLog("---")
                            self?.appendLog("✅ Download completed successfully!")
                        }
                    }
                    continuation.resume(returning: success)
                }
            )
        }
    }
    
    /// Cancels the current download or all playlist downloads
    func cancelDownload() {
        if showPlaylistProgress {
            // Cancel all active playlist downloads
            for (_, runner) in activeRunners {
                runner.cancel()
            }
            activeRunners.removeAll()
            activeDownloadTasks.removeAll()
            downloadQueue.removeAll()
            appendLog("⏹️ All downloads cancelled")
        } else {
            // Cancel single download
        ytdlpRunner.cancel()
            appendLog("⏹️ Download cancelled")
        }
        downloadState = .cancelled
    }
    
    /// Pauses the current download or all playlist downloads
    func pauseDownload() {
        isUserPausing = true  // Set flag before pausing
        downloadState = .paused
        
        if showPlaylistProgress {
            // Pause all active playlist downloads
            for (_, runner) in activeRunners {
                runner.pause()
            }
            
            // Update UI status for currently downloading items
            for item in playlistProgress where item.status == .downloading {
                if let index = playlistProgress.firstIndex(where: { $0.id == item.id }) {
                    playlistProgress[index].speed = "Paused"
                    playlistProgress[index].eta = "Paused"
                }
            }
            
            appendLog("⏸️ All downloads paused")
        } else {
            // Pause single download
            ytdlpRunner.pause()
            appendLog("⏸️ Download paused")
        }
    }
    
    /// Resumes a paused download or all paused playlist downloads
    func resumeDownload() {
        isUserPausing = false  // Clear flag when resuming
        
        if showPlaylistProgress {
            appendLog("▶️ Resuming playlist downloads...")
            downloadState = .running
            
            // Clear "Paused" status from UI
            for i in 0..<playlistProgress.count {
                if playlistProgress[i].speed == "Paused" {
                    playlistProgress[i].speed = "N/A"
                    playlistProgress[i].eta = "N/A"
                }
            }
            
            // Check if there are items still in the queue
            if !downloadQueue.isEmpty {
                appendLog("📥 Continuing with \(downloadQueue.count) queued videos...")
                
                // CRITICAL FIX: Restart downloads from queue
                Task {
                    await restartQueuedDownloads()
                }
            } else if activeDownloadTasks.isEmpty {
                // No active tasks and empty queue means downloads are done
                downloadState = .completed
                showPlaylistProgress = false
                appendLog("✅ All downloads completed")
            }
        } else {
            // Resume single download
            appendLog("▶️ Resuming download...")
            downloadState = .running
            ytdlpRunner.resume(
                onOutput: { [weak self] output in
                    self?.handleOutput(output)
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                },
                onCompletion: { [weak self] success in
                    self?.handleCompletion(success: success)
                }
            )
        }
    }
    
    /// Restarts queued downloads after resume
    private func restartQueuedDownloads() async {
        // Find all incomplete videos (downloading or queued)
        let incompleteProgresses = playlistProgress.filter { 
            $0.status == .downloading || $0.status == .queued 
        }
        
        guard !incompleteProgresses.isEmpty else {
            // All done
            await MainActor.run {
                downloadState = .completed
                showPlaylistProgress = false
                appendLog("✅ All downloads completed")
            }
            return
        }
        
        await MainActor.run {
            appendLog("📥 Restarting \(incompleteProgresses.count) incomplete downloads...")
            
            // Rebuild download queue from incomplete items
            downloadQueue.removeAll()
            for progressItem in incompleteProgresses {
                if let originalItem = originalPlaylistItems[progressItem.id] {
                    downloadQueue.append((id: progressItem.id, item: originalItem))
                    // Reset status to queued
                    if let index = playlistProgress.firstIndex(where: { $0.id == progressItem.id }) {
                        playlistProgress[index].status = .queued
                        playlistProgress[index].progress = 0.0
                        playlistProgress[index].speed = "N/A"
                        playlistProgress[index].eta = "N/A"
                    }
                }
            }
        }
        
        // Get the selected quality and output directory
        let quality = selectedQuality
        let outputDir = outputDirectory
        let totalCount = playlistProgress.count
        
        // Restart the concurrent download loop
        await downloadPlaylistConcurrently(quality: quality, outputDir: outputDir, totalCount: totalCount)
    }
    
    /// Resets the download state for a new download
    func reset() {
        downloadState = .idle
        progress = DownloadProgress()
        logOutput = ""
    }
    
    // MARK: - Private Methods
    
    /// Builds download settings from current UI state
    private func buildDownloadSettings() -> DownloadSettings {
        var downloadSettings = settings
        downloadSettings.downloadSubtitles = downloadSubtitles
        downloadSettings.subtitleLanguages = subtitleLanguages
        downloadSettings.embedSubtitles = embedSubtitles
        downloadSettings.keepSubtitleFiles = keepSubtitleFiles
        downloadSettings.useBrowserCookies = useBrowserCookies
        downloadSettings.browserForCookies = browserForCookies
        return downloadSettings
    }
    
    private func handleOutput(_ output: String) {
        // Parse progress from output
        ProgressParser.parse(line: output, currentProgress: &progress)
        
        // Append to log (filter out progress lines to reduce clutter)
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            // Only log non-progress lines
            if !trimmed.contains("|") || trimmed.contains("[download]") {
                appendLog(trimmed)
            }
        }
    }
    
    private func handleError(_ error: String) {
        let trimmed = error.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            appendLog("⚠️ \(trimmed)")
        }
    }
    
    private func handleCompletion(success: Bool) {
        // Don't change state if we're in paused state (pause triggers termination)
        if case .paused = downloadState {
            return
        }
        
        if success {
            downloadState = .completed
            progress.percentage = 100.0
            appendLog("---")
            appendLog("✅ Download completed successfully!")
        } else {
            if case .cancelled = downloadState {
                // Already handled in cancelDownload()
            } else {
                let errorMsg = ProgressParser.extractError(from: logOutput) ?? "Download failed"
                downloadState = .failed(errorMsg)
                appendLog("---")
                appendLog("❌ Download failed")
            }
        }
    }
    
    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logOutput += "[\(timestamp)] \(message)\n"
    }
    
    // MARK: - Playlist Downloads
    
    /// Downloads multiple videos from a playlist with concurrent support
    func downloadPlaylistItems(_ items: [PlaylistItem], quality: DownloadQuality, outputDir: URL) {
        guard !items.isEmpty else { return }
        
        // Reset state
        downloadState = .running
        progress = DownloadProgress()
        logOutput = ""
        activeDownloadTasks.removeAll()
        downloadQueue.removeAll()
        progressTrackers.removeAll()
        
        // Initialize playlist progress tracking
        showPlaylistProgress = true
        originalPlaylistItems.removeAll()
        playlistProgress = items.map { item in
            let progressId = UUID()
            originalPlaylistItems[progressId] = item  // Store original item
            return PlaylistItemProgress(
                id: progressId,
                title: item.title,
                status: .queued
            )
        }
        
        appendLog("🚀 Starting playlist download...")
        appendLog("📺 Selected: \(items.count) videos")
        appendLog("🎬 Quality: \(quality.rawValue)")
        appendLog("📁 Output: \(outputDir.path)")
        appendLog("⚡ Concurrent downloads: \(settings.maxConcurrentDownloads)")
        appendLog("---")
        
        // Build queue with unique IDs matching progress trackers
        downloadQueue = zip(playlistProgress.map(\.id), items).map { ($0, $1) }
        
        Task {
            await downloadPlaylistConcurrently(quality: quality, outputDir: outputDir, totalCount: items.count)
        }
    }
    
    /// Downloads playlist items concurrently with configurable limit
    private func downloadPlaylistConcurrently(quality: DownloadQuality, outputDir: URL, totalCount: Int) async {
        await withTaskGroup(of: (UUID, Bool, String).self) { group in
            var completedCount = 0
            var failedCount = 0
            var currentIndex = 0
            
            // Start initial batch of concurrent downloads
            while activeDownloadTasks.count < settings.maxConcurrentDownloads && !downloadQueue.isEmpty {
                let queueItem = downloadQueue.removeFirst()
                activeDownloadTasks.insert(queueItem.id)
                currentIndex += 1
                let itemIndex = currentIndex
                
                group.addTask {
                    let success = await self.downloadSingleVideo(
                        item: queueItem.item,
                        quality: quality,
                        outputDir: outputDir,
                        index: itemIndex,
                        total: totalCount,
                        trackingId: queueItem.id
                    )
                    return (queueItem.id, success, queueItem.item.title)
                }
            }
            
            // Process completed downloads and start new ones
            for await (taskId, success, title) in group {
                activeDownloadTasks.remove(taskId)
                
                // Check if download was paused (don't count as success or failure)
                let wasPaused = await MainActor.run {
                    return self.isUserPausing || self.downloadState == .paused
                }
                
                if wasPaused {
                    // Don't log or count paused downloads
                    // They'll resume later
                } else if success {
                    completedCount += 1
                    await MainActor.run {
                        appendLog("✅ [\(completedCount + failedCount)/\(totalCount)] Downloaded: \(title)")
                    }
                } else {
                    failedCount += 1
                    await MainActor.run {
                        appendLog("❌ [\(completedCount + failedCount)/\(totalCount)] Failed: \(title)")
                    }
                }
                
                // Check if user paused before starting next download
                let isPaused = await MainActor.run {
                    return self.isUserPausing || self.downloadState == .paused
                }
                
                // Start next download if queue has items and not paused
                if !downloadQueue.isEmpty && !isPaused {
                    let queueItem = downloadQueue.removeFirst()
                    activeDownloadTasks.insert(queueItem.id)
                    currentIndex += 1
                    let itemIndex = currentIndex
                    
                    group.addTask {
                        let success = await self.downloadSingleVideo(
                            item: queueItem.item,
                            quality: quality,
                            outputDir: outputDir,
                            index: itemIndex,
                            total: totalCount,
                            trackingId: queueItem.id
                        )
                        return (queueItem.id, success, queueItem.item.title)
                    }
                }
            }
            
            // All active downloads completed or paused
            await MainActor.run {
                // Check if we're still paused
                if self.downloadState == .paused {
                    // Don't mark as completed, stay paused
                    // Downloads will resume when user clicks Resume
                } else {
                    downloadState = .completed
                    showPlaylistProgress = false
                    appendLog("---")
                    if failedCount > 0 {
                        appendLog("✅ Completed: \(completedCount)/\(totalCount) videos")
                        appendLog("❌ Failed: \(failedCount)/\(totalCount) videos")
                    } else {
                        appendLog("✅ All \(totalCount) videos downloaded successfully!")
                    }
                }
            }
        }
    }
    
    /// Downloads a single video and returns success status
    private func downloadSingleVideo(item: PlaylistItem, quality: DownloadQuality, outputDir: URL, index: Int, total: Int, trackingId: UUID) async -> Bool {
        await MainActor.run {
            appendLog("📥 [\(index)/\(total)] Starting: \(item.title)")
            updatePlaylistItemStatus(id: trackingId, status: .downloading)
        }
        
        var attemptCount = 0
        let maxAttempts = settings.autoRetryOnFailure ? settings.maxRetryAttempts : 1
        
        // Build settings with subtitle options
        let downloadSettings = buildDownloadSettings()
        
        while attemptCount < maxAttempts {
            attemptCount += 1
            
            if attemptCount > 1 {
                await MainActor.run {
                    updatePlaylistItemStatus(id: trackingId, status: .retrying(attempt: attemptCount - 1))
                }
            }
            
            let success = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                // Create a new YTDLPRunner instance for concurrent downloads
                let runner = YTDLPRunner()
                
                // Store runner for pause/resume/cancel control
                Task { @MainActor in
                    self.activeRunners[trackingId] = runner
                }
                
                // Initialize progress tracker for this download
                progressTrackers[trackingId] = DownloadProgress()
                
                runner.startDownload(
                    url: item.url,
                    quality: quality,
                    outputDirectory: outputDir,
                    settings: downloadSettings,
                    onOutput: { [weak self] output in
                        Task { @MainActor in
                            // Parse progress for this specific download
                            if var itemProgress = self?.progressTrackers[trackingId] {
                                ProgressParser.parse(line: output, currentProgress: &itemProgress)
                                self?.progressTrackers[trackingId] = itemProgress
                                self?.updatePlaylistItemProgress(
                                    id: trackingId,
                                    progress: itemProgress.percentage,
                                    speed: itemProgress.speed,
                                    eta: itemProgress.eta
                                )
                            }
                        }
                    },
                    onError: { [weak self] error in
                        Task { @MainActor in
                            self?.handleError(error)
                        }
                    },
                    onCompletion: { [weak self] success in
                        // Remove runner when download completes
                        Task { @MainActor in
                            self?.activeRunners.removeValue(forKey: trackingId)
                            
                            // Check if this was paused by user (not a real failure)
                            if let isPaused = self?.isUserPausing, isPaused {
                                // Don't count as failure if user paused
                                continuation.resume(returning: false)
                            } else {
                                continuation.resume(returning: success)
                            }
                        }
                    }
                )
            }
            
            if success {
                await MainActor.run {
                    updatePlaylistItemStatus(id: trackingId, status: .completed)
                    updatePlaylistItemProgress(id: trackingId, progress: 100.0, speed: "N/A", eta: "N/A")
                }
                return true
            }
            
            // Check if user manually paused or cancelled (don't retry)
            let shouldStopRetrying = await MainActor.run {
                if self.isUserPausing || self.downloadState == .paused {
                    return true
                }
                if case .cancelled = self.downloadState {
                    return true
                }
                return false
            }
            
            if shouldStopRetrying {
                // Don't retry if user paused or cancelled
                return false
            }
            
            if attemptCount < maxAttempts {
                await MainActor.run {
                    appendLog("⚠️ [\(index)/\(total)] Retry \(attemptCount)/\(maxAttempts) for: \(item.title)")
                }
                // Wait a bit before retrying
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        }
        
        // All attempts failed
        await MainActor.run {
            updatePlaylistItemStatus(id: trackingId, status: .failed)
        }
        return false
    }
    
    /// Updates playlist item status
    private func updatePlaylistItemStatus(id: UUID, status: PlaylistItemProgress.DownloadItemStatus) {
        if let index = playlistProgress.firstIndex(where: { $0.id == id }) {
            playlistProgress[index].status = status
        }
    }
    
    /// Updates playlist item progress
    private func updatePlaylistItemProgress(id: UUID, progress: Double, speed: String, eta: String) {
        if let index = playlistProgress.firstIndex(where: { $0.id == id }) {
            playlistProgress[index].progress = progress
            playlistProgress[index].speed = speed
            playlistProgress[index].eta = eta
        }
    }
    
    /// Legacy sequential download method (kept for compatibility)
    private func downloadNextVideo(from items: [PlaylistItem], quality: DownloadQuality, outputDir: URL, currentIndex: Int) async {
        guard currentIndex < items.count else {
            // All done
            downloadState = .completed
            appendLog("---")
            appendLog("✅ All \(items.count) videos downloaded successfully!")
            return
        }
        
        let item = items[currentIndex]
        appendLog("📥 [\(currentIndex + 1)/\(items.count)] \(item.title)")
        
        // Build settings with subtitle options
        let downloadSettings = buildDownloadSettings()
        
        // Download this video
        await withCheckedContinuation { continuation in
            ytdlpRunner.startDownload(
                url: item.url,
                quality: quality,
                outputDirectory: outputDir,
                settings: downloadSettings,
                onOutput: { [weak self] output in
                    self?.handleOutput(output)
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                },
                onCompletion: { [weak self] success in
                    if success {
                        self?.appendLog("✅ Downloaded: \(item.title)")
                    } else {
                        self?.appendLog("❌ Failed: \(item.title)")
                    }
                    continuation.resume()
                }
            )
        }
        
        // Download next
        await downloadNextVideo(from: items, quality: quality, outputDir: outputDir, currentIndex: currentIndex + 1)
    }
}
