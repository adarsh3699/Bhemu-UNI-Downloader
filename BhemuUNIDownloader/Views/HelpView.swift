//
//  HelpView.swift
//  Bhemu UNI Downloader
//
//  Author: Adarsh Suman (adarsh3699@gmail.com)
//  Website: https://bhemu.in
//  Description: User-friendly help and documentation
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection = .quickStart
    
    enum HelpSection: String, CaseIterable {
        case quickStart = "Quick Start"
        case features = "Features"
        case howTo = "How to Use"
        case playlists = "Playlists"
        case subtitles = "Subtitles"
        case troubleshooting = "Troubleshooting"
        case about = "About"
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(HelpSection.allCases, id: \.self, selection: $selectedSection) { section in
                HStack {
                    Image(systemName: iconForSection(section))
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text(section.rawValue)
                }
                .padding(.vertical, 4)
            }
            .navigationSplitViewColumnWidth(180)
            .listStyle(.sidebar)
        } detail: {
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    contentForSection(selectedSection)
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 800, height: 600)
        .navigationTitle("Help")
    }
    
    // MARK: - Section Icons
    
    func iconForSection(_ section: HelpSection) -> String {
        switch section {
        case .quickStart: return "bolt.circle.fill"
        case .features: return "star.fill"
        case .howTo: return "questionmark.circle.fill"
        case .playlists: return "list.bullet"
        case .subtitles: return "captions.bubble.fill"
        case .troubleshooting: return "wrench.and.screwdriver.fill"
        case .about: return "info.circle.fill"
        }
    }
    
    // MARK: - Section Content
    
    @ViewBuilder
    func contentForSection(_ section: HelpSection) -> some View {
        switch section {
        case .quickStart:
            quickStartContent
        case .features:
            featuresContent
        case .howTo:
            howToContent
        case .playlists:
            playlistsContent
        case .subtitles:
            subtitlesContent
        case .troubleshooting:
            troubleshootingContent
        case .about:
            aboutContent
        }
    }
    
    // MARK: - Quick Start Content
    
    var quickStartContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚡ Quick Start")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            Text("Download a video in 3 simple steps:")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 20) {
                StepView(
                    number: "1",
                    title: "Paste Video URL",
                    description: "Copy a video URL from YouTube, Instagram, TikTok, or 1000+ sites, then paste it into the URL field.",
                    icon: "link"
                )
                
                StepView(
                    number: "2",
                    title: "Choose Quality",
                    description: "Select your preferred quality: Best, 1080p, 720p, 480p, or Audio Only (MP3).",
                    icon: "slider.horizontal.3"
                )
                
                StepView(
                    number: "3",
                    title: "Click Download",
                    description: "Select output folder (optional) and click \"Start Download\". Watch real-time progress!",
                    icon: "arrow.down.circle.fill"
                )
            }
            .padding(.top)
            
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tip: You can also drag and drop URLs directly into the app!")
                    .font(.callout)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Features Content
    
    var featuresContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("✨ Features")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "globe", color: .blue, title: "1000+ Websites", description: "YouTube, Instagram, Twitter, TikTok, Facebook, Vimeo, Twitch, and many more")
                
                FeatureRow(icon: "tv.fill", color: .purple, title: "Multiple Quality Options", description: "Best Quality (4K/8K), 1440p, 1080p, 720p, 480p, or Audio Only (MP3)")
                
                FeatureRow(icon: "list.bullet", color: .green, title: "Playlist Support", description: "Download entire playlists with up to 3 concurrent downloads")
                
                FeatureRow(icon: "gauge.high", color: .orange, title: "Real-time Progress", description: "Live download speed, percentage, and estimated time remaining")
                
                FeatureRow(icon: "arrow.clockwise", color: .pink, title: "Auto-Retry", description: "Failed downloads automatically retry up to 3 times")
                
                FeatureRow(icon: "captions.bubble", color: .cyan, title: "Subtitle Support", description: "Download and embed subtitles in multiple languages")
                
                FeatureRow(icon: "square.and.arrow.down.fill", color: .indigo, title: "Drag & Drop", description: "Drop URLs from your browser directly into the app")
                
                FeatureRow(icon: "lock.shield.fill", color: .gray, title: "100% Private", description: "All processing happens locally on your Mac, no cloud services")
            }
        }
    }
    
    // MARK: - How To Content
    
    var howToContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📖 How to Use")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            Group {
                SectionHeader(title: "Downloading Videos")
                Text("1. Copy a video URL from your browser")
                Text("2. Paste it into the \"Video URL\" field (or drag & drop)")
                Text("3. The app will automatically detect available quality options")
                Text("4. Select your preferred quality from the dropdown")
                Text("5. (Optional) Click \"Choose...\" to select a custom output folder")
                Text("6. Click \"Start Download\" or press ⌘↩")
                Text("7. Watch the progress bar and download speed in real-time")
                
                SectionHeader(title: "Understanding Quality Options")
                QualityOptionRow(name: "Best Quality", description: "Highest available (4K, 8K, or best available)")
                QualityOptionRow(name: "1440p", description: "2K resolution video")
                QualityOptionRow(name: "1080p MP4", description: "Full HD with H.264 codec")
                QualityOptionRow(name: "720p MP4", description: "HD ready video")
                QualityOptionRow(name: "480p MP4", description: "Standard definition")
                QualityOptionRow(name: "Audio Only", description: "Extract audio as MP3 file")
                
                SectionHeader(title: "Pausing & Resuming")
                Text("• Click \"Pause\" to pause an active download")
                Text("• Click \"Resume\" to continue from where you left off")
                Text("• Note: Not all websites support resume functionality")
                
                SectionHeader(title: "Canceling Downloads")
                Text("• Click \"Cancel\" or press ⌘. to stop a download")
                Text("• Partial files will be deleted automatically")
            }
        }
    }
    
    // MARK: - Playlists Content
    
    var playlistsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📋 Downloading Playlists")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            Text("Download entire playlists with ease!")
                .font(.title3)
                .fontWeight(.semibold)
            
            Group {
                SectionHeader(title: "How to Download Playlists")
                Text("1. Paste a playlist URL (e.g., YouTube playlist)")
                Text("2. Wait for the playlist to load (shows video count)")
                Text("3. Click \"Select Videos\" to choose which videos to download")
                Text("4. Check the videos you want (or \"Select All\")")
                Text("5. Choose quality and click \"Download Selected\"")
                
                SectionHeader(title: "Playlist Features")
                Text("✓ Download up to 3 videos simultaneously")
                Text("✓ Visual progress for each video in the queue")
                Text("✓ Pause/Resume entire playlist")
                Text("✓ Automatic retry for failed videos")
                Text("✓ Real-time status updates:")
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Queued - Waiting to start")
                    }
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Downloading - Active with progress bar")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed - Successfully downloaded")
                    }
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Failed - Download failed after retries")
                    }
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retrying - Attempting download again")
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Subtitles Content
    
    var subtitlesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💬 Subtitle Support")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            Text("Download and embed subtitles in your videos!")
                .font(.title3)
                .fontWeight(.semibold)
            
            Group {
                SectionHeader(title: "How to Use Subtitles")
                Text("1. Open Settings (⌘,) or menu → Bhemu UNI Downloader → Settings")
                Text("2. Enable \"Download Subtitles\"")
                Text("3. Enter language codes (e.g., en, es, fr) separated by commas")
                Text("4. Enable \"Embed in Video\" to include subtitles in the video file")
                Text("5. Optional: Enable \"Keep Subtitle Files\" to save separate .srt files")
                
                SectionHeader(title: "Common Language Codes")
                VStack(alignment: .leading, spacing: 8) {
                    LanguageRow(code: "en", name: "English")
                    LanguageRow(code: "es", name: "Spanish")
                    LanguageRow(code: "fr", name: "French")
                    LanguageRow(code: "de", name: "German")
                    LanguageRow(code: "it", name: "Italian")
                    LanguageRow(code: "pt", name: "Portuguese")
                    LanguageRow(code: "ja", name: "Japanese")
                    LanguageRow(code: "ko", name: "Korean")
                    LanguageRow(code: "zh", name: "Chinese")
                    LanguageRow(code: "ar", name: "Arabic")
                    LanguageRow(code: "hi", name: "Hindi")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Not all videos have subtitles in all languages. The app will download available subtitles.")
                        .font(.callout)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Troubleshooting Content
    
    var troubleshootingContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🔧 Troubleshooting")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            Group {
                TroubleshootingItem(
                    title: "Download fails immediately",
                    solutions: [
                        "Check if the URL works in your browser",
                        "Update yt-dlp: Open Terminal and run: brew upgrade yt-dlp",
                        "Check the Download Log for specific error messages",
                        "Try a different quality option"
                    ]
                )
                
                TroubleshootingItem(
                    title: "Download is very slow",
                    solutions: [
                        "Check your internet connection speed",
                        "Some websites throttle download speeds",
                        "Try downloading at a different time of day",
                        "Lower quality downloads are usually faster"
                    ]
                )
                
                TroubleshootingItem(
                    title: "Can't find downloaded file",
                    solutions: [
                        "Check the output folder shown in the app",
                        "Default location is your Downloads folder",
                        "Look in Finder → Downloads",
                        "Check the Download Log for the exact save path"
                    ]
                )
                
                TroubleshootingItem(
                    title: "Playlist not loading",
                    solutions: [
                        "Ensure the URL is a valid playlist link",
                        "Wait a few seconds for loading to complete",
                        "Try refreshing by re-pasting the URL",
                        "Check if the playlist is public (not private)"
                    ]
                )
                
                TroubleshootingItem(
                    title: "Setup/Installation issues",
                    solutions: [
                        "Run the First-Run Setup again from the Help menu",
                        "Manually install: brew install yt-dlp ffmpeg",
                        "Check if Homebrew is installed: which brew",
                        "Restart the app after installing dependencies"
                    ]
                )
                
                SectionHeader(title: "Still Need Help?")
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text("Contact: adarsh3699@gmail.com")
                        .font(.callout)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - About Content
    
    var aboutContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bhemu UNI Downloader")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Version 1.2.0")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Developer", value: "Adarsh Suman")
                InfoRow(label: "Email", value: "adarsh3699@gmail.com")
                InfoRow(label: "Website", value: "bhemu.in")
                InfoRow(label: "Built with", value: "Swift & SwiftUI")
                InfoRow(label: "Powered by", value: "yt-dlp & FFmpeg")
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacy & Security")
                    .font(.headline)
                
                HStack(alignment: .top) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("100% Local Processing")
                            .fontWeight(.semibold)
                        Text("All downloads happen on your Mac. No data is sent to any server.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Telemetry or Analytics")
                            .fontWeight(.semibold)
                        Text("We don't track or collect any user data.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Source Tools")
                            .fontWeight(.semibold)
                        Text("Built on trusted open-source projects: yt-dlp and FFmpeg.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            Divider()
            
            Text("Copyright © 2026 Adarsh Suman. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Helper Views

struct StepView: View {
    let number: String
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                Text(number)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                    Text(title)
                        .font(.headline)
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.top, 8)
    }
}

struct QualityOptionRow: View {
    let name: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
            Text(name)
                .fontWeight(.semibold)
            Text("-")
                .foregroundColor(.secondary)
            Text(description)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
}

struct LanguageRow: View {
    let code: String
    let name: String
    
    var body: some View {
        HStack {
            Text(code)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)
                .frame(width: 40, alignment: .leading)
            Text("→")
                .foregroundColor(.secondary)
            Text(name)
        }
        .font(.subheadline)
    }
}

struct TroubleshootingItem: View {
    let title: String
    let solutions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Solutions:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach(solutions, id: \.self) { solution in
                    HStack(alignment: .top) {
                        Text("✓")
                            .foregroundColor(.green)
                        Text(solution)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
}

#Preview {
    HelpView()
}
