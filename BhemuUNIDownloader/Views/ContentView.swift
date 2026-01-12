//
//  ContentView.swift
//  Bhemu UNI Downloader
//
//  Author: Adarsh Suman (adarsh3699@gmail.com)
//  Website: https://bhemu.in
//  Description: Main SwiftUI view providing the user interface
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    @StateObject private var viewModel = DownloadViewModel()
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
                .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // URL Input Section
                    urlInputSection
                    
                    // Options Section
                    optionsSection
                    
                    // Progress Section (only for single video downloads)
                    if !viewModel.showPlaylistProgress && (viewModel.downloadState.isRunning || viewModel.progress.percentage > 0) {
                        progressSection
                    }
                    
                    // Playlist Progress Section (for concurrent downloads)
                    if viewModel.showPlaylistProgress && !viewModel.playlistProgress.isEmpty {
                        playlistProgressSection
                    }
                    
                    // Status Section
                    statusSection
                    
                    // Log Output Section
                    logOutputSection
                }
                .padding()
            }
            
            Divider()
            
            // Action Buttons
            actionButtonsView
                .padding()
                .background(Color(.windowBackgroundColor))
        }
        .onDrop(of: [.url, .text], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.outputDirectory = url
                }
            case .failure:
                break
            }
        }
        .sheet(isPresented: $viewModel.showPlaylistSheet) {
            PlaylistSelectionView(
                playlistURL: viewModel.videoURL,
                outputDirectory: viewModel.outputDirectory,
                onDownload: { items, quality, outputDir in
                    viewModel.downloadPlaylistItems(items, quality: quality, outputDir: outputDir)
                }
            )
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 48, height: 48)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Bhemu UNI Downloader")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Download videos and audio from YouTube and 1000+ sites")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Video URL", systemImage: "link")
                .font(.headline)
            
            HStack {
                TextField("https://www.website.com/watch?v=... or playlist URL", text: $viewModel.videoURL)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.downloadState.isRunning)
                    .onDrop(of: [.url, .text], isTargeted: nil) { providers in
                        handleDrop(providers: providers)
                    }
                
                if viewModel.isPlaylist {
                    Label("Playlist", systemImage: "list.bullet.rectangle")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Text("Tip: Drag and drop a URL anywhere in the app")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    /// Handles dropped URLs
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !viewModel.downloadState.isRunning else { return false }
        
        // Try to extract URL from dropped item
        for provider in providers {
            // Try URL type first
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            viewModel.videoURL = url.absoluteString
                        }
                    } else if let urlString = item as? String {
                        DispatchQueue.main.async {
                            viewModel.videoURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }
                return true
            }
            
            // Try plain text
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                    if let urlString = item as? String {
                        DispatchQueue.main.async {
                            viewModel.videoURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }
                return true
            }
            
            // Try UTF-8 plain text (fallback)
            if provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text") {
                provider.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { item, error in
                    if let urlString = item as? String {
                        DispatchQueue.main.async {
                            viewModel.videoURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }
                return true
            }
        }
        
        return false
    }
    
    private var optionsSection: some View {
        VStack(spacing: 16) {
            // Quality Selection
            HStack {
                Label("Quality", systemImage: "film")
                    .font(.headline)
                    .frame(width: 120, alignment: .leading)
                
                Picker("Quality", selection: $viewModel.selectedQuality) {
                    ForEach(viewModel.availableQualities) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
                .pickerStyle(.menu)
                .disabled(viewModel.downloadState.isRunning || viewModel.isFetchingFormats)
                
                if viewModel.isFetchingFormats {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                }
                
                Spacer()
            }
            
            // Subtitles Toggle
            HStack {
                Label("Subtitles", systemImage: "captions.bubble")
                    .font(.headline)
                    .frame(width: 120, alignment: .leading)
                
                Toggle("Download subtitles", isOn: $viewModel.downloadSubtitles)
                    .disabled(viewModel.downloadState.isRunning)
                
                Spacer()
            }
            
            // Subtitle Options (shown when enabled)
            if viewModel.downloadSubtitles {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Languages")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 120, alignment: .leading)
                        
                        // Show fetch button initially (before first attempt)
                        if !viewModel.hasAttemptedSubtitleFetch && !viewModel.isFetchingSubtitles {
                            Button(action: viewModel.fetchSubtitles) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.circle")
                                    Text("Load Available Languages")
                                }
                            }
                            .disabled(viewModel.downloadState.isRunning || viewModel.videoURL.isEmpty)
                        }
                        // Show loading spinner while fetching
                        else if viewModel.isFetchingSubtitles {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Loading...")
                                    .foregroundColor(.secondary)
                            }
                        }
                        // Show language selection menu if subtitles loaded
                        else if !viewModel.availableSubtitles.isEmpty {
                            Menu {
                                ForEach(viewModel.availableSubtitles) { subtitle in
                                    Button(action: {
                                        viewModel.toggleSubtitleLanguage(subtitle.code)
                                    }) {
                                        HStack {
                                            Text("\(subtitle.displayName) (\(subtitle.code))")
                                            Spacer()
                                            if viewModel.selectedSubtitleCodes.contains(subtitle.code) {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                Button("Clear Selection") {
                                    viewModel.selectedSubtitleCodes.removeAll()
                                    viewModel.updateSubtitleLanguagesString()
                                }
                                
                                Button("Try Again") {
                                    viewModel.fetchSubtitles()
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedSubtitleCodes.isEmpty ? "Select languages" : viewModel.selectedSubtitleCodes.sorted().joined(separator: ", "))
                                        .lineLimit(1)
                                        .frame(width: 200, alignment: .leading)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                            .disabled(viewModel.downloadState.isRunning)
                        }
                        
                        if viewModel.selectedQuality != .audioOnly {
                            Toggle("Embed in video", isOn: $viewModel.embedSubtitles)
                                .disabled(viewModel.downloadState.isRunning)
                            
                            if viewModel.embedSubtitles {
                                Toggle("Keep files", isOn: $viewModel.keepSubtitleFiles)
                                    .disabled(viewModel.downloadState.isRunning)
                                    .help("Keep separate subtitle files after embedding")
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Show hint when displaying common languages (platform doesn't support listing)
                    if viewModel.isShowingCommonLanguages {
                        HStack {
                            Spacer()
                                .frame(width: 120)
                            
                            Text("💡 Platform doesn't support auto-detection. Showing common languages. ⚠️ Only available subtitles will download.")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.leading, 20)
            }
            
            // Browser Cookies (for bot detection)
            HStack {
                Label("Cookies", systemImage: "lock.shield")
                    .font(.headline)
                    .frame(width: 120, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                Toggle("Use browser cookies", isOn: $viewModel.useBrowserCookies)
                    .disabled(viewModel.downloadState.isRunning)
                
                if viewModel.useBrowserCookies {
                            Text("Browser")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $viewModel.browserForCookies) {
                        Text("Chrome").tag("chrome")
                        Text("Firefox").tag("firefox")
                        Text("Safari").tag("safari")
                        Text("Edge").tag("edge")
                        Text("Brave").tag("brave")
                    }
                    .pickerStyle(.menu)
                            .frame(width: 100)
                    .disabled(viewModel.downloadState.isRunning)
                        }
                    }
                    
                    // Info text
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue.opacity(0.8))
                            .font(.system(size: 10))
                        
                        Text("For protected sites (Netflix, Prime, Hotstar) & bot detection bypass")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Output Directory
            HStack {
                Label("Output Folder", systemImage: "folder")
                    .font(.headline)
                    .frame(width: 120, alignment: .leading)
                
                Text(viewModel.outputDirectory.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button("Choose...") {
                    showingDirectoryPicker = true
                }
                .disabled(viewModel.downloadState.isRunning)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Progress", systemImage: "chart.bar.fill")
                .font(.headline)
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: viewModel.progress.percentage, total: 100)
                    .progressViewStyle(.linear)
                
                HStack {
                    Text(viewModel.progress.percentageFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if viewModel.progress.speed != "N/A" {
                        Text("Speed: \(viewModel.progress.speed)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if viewModel.progress.eta != "N/A" {
                        Text("ETA: \(viewModel.progress.eta)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !viewModel.progress.currentFile.isEmpty {
                Text("File: \(viewModel.progress.currentFile)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var playlistProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Playlist Queue", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                
                Spacer()
                
                let completed = viewModel.playlistProgress.filter { $0.status == .completed }.count
                let total = viewModel.playlistProgress.count
                Text("\(completed)/\(total) completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.playlistProgress) { item in
                        playlistItemRow(item: item)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func playlistItemRow(item: PlaylistItemProgress) -> some View {
        HStack(spacing: 12) {
            // Status Icon
            Group {
                switch item.status {
                case .queued:
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                case .downloading:
                    ProgressView()
                        .scaleEffect(0.7)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                case .retrying:
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                }
            }
            .frame(width: 20)
            
            // Title and Progress
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.caption)
                    .lineLimit(1)
                
                if item.status == .downloading {
                    HStack(spacing: 8) {
                        ProgressView(value: item.progress, total: 100)
                            .progressViewStyle(.linear)
                            .frame(height: 4)
                        
                        Text(item.progressPercentage)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .trailing)
                    }
                    
                    if item.speed != "N/A" || item.eta != "N/A" {
                        HStack(spacing: 12) {
                            if item.speed != "N/A" {
                                Text(item.speed)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if item.eta != "N/A" {
                                Text("ETA: \(item.eta)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Text(item.statusText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            Group {
                switch item.status {
                case .downloading:
                    Color.blue.opacity(0.1)
                case .completed:
                    Color.green.opacity(0.05)
                case .failed:
                    Color.red.opacity(0.05)
                default:
                    Color.clear
                }
            }
        )
        .cornerRadius(6)
    }
    
    private var statusSection: some View {
        Group {
            switch viewModel.downloadState {
            case .idle:
                EmptyView()
                
            case .running:
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Downloading...")
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
            case .retrying(let attempt):
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Retrying (\(attempt))...")
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
            case .paused:
                HStack {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                    Text("Download paused")
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
            case .completed:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Download completed successfully!")
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
            case .failed(let error):
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Download failed")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .textSelection(.enabled)  // Make error text selectable
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                
            case .cancelled:
                HStack {
                    Image(systemName: "stop.circle.fill")
                        .foregroundColor(.orange)
                    Text("Download cancelled")
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var logOutputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Download Log", systemImage: "doc.text")
                .font(.headline)
            
            ScrollView {
                ScrollViewReader { proxy in
                    Text(viewModel.logOutput.isEmpty ? "No activity yet" : viewModel.logOutput)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(viewModel.logOutput.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                        .id("logBottom")
                        .onChange(of: viewModel.logOutput) { oldValue, newValue in
                            proxy.scrollTo("logBottom", anchor: .bottom)
                        }
                }
            }
            .frame(height: 200)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Reset/New Download button
            if case .completed = viewModel.downloadState {
                Button(action: viewModel.reset) {
                    Label("New Download", systemImage: "plus.circle")
                }
                .keyboardShortcut("n", modifiers: .command)
            } else if case .cancelled = viewModel.downloadState {
                Button(action: viewModel.reset) {
                    Label("New Download", systemImage: "plus.circle")
                }
                .keyboardShortcut("n", modifiers: .command)
            } else if case .failed = viewModel.downloadState {
                Button(action: viewModel.reset) {
                    Label("New Download", systemImage: "plus.circle")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            Spacer()
            
            // Resume button (for paused state)
            if viewModel.downloadState.isPaused {
                Button(action: viewModel.resumeDownload) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("r", modifiers: .command)
            }
            
            // Pause button (for running state)
            if viewModel.downloadState.isRunning {
                Button(action: viewModel.pauseDownload) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .keyboardShortcut("p", modifiers: .command)
            }
            
            // Cancel button (for running or paused state)
            if viewModel.downloadState.isRunning || viewModel.downloadState.isPaused {
                Button(action: viewModel.cancelDownload) {
                    Label("Cancel", systemImage: "stop.fill")
                }
                .keyboardShortcut(.cancelAction)
            }
            
            // Start button
            if !viewModel.downloadState.isRunning && !viewModel.downloadState.isPaused {
                Button(action: viewModel.startDownload) {
                    if viewModel.isFetchingFormats {
                        Label("Loading...", systemImage: "arrow.down.circle.fill")
                    } else {
                        Label("Start Download", systemImage: "arrow.down.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canStartDownload)
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 700, height: 600)
    }
}
