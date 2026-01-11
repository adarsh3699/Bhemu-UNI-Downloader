# Bhemu UNI Downloader

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-green)

A beautiful, native macOS application for downloading videos and audio from YouTube and 1000+ websites.

**Author:** Adarsh Suman  
**Email:** adarsh3699@gmail.com  
**Website:** [bhemu.in](https://bhemu.in)

</div>

---

## ✨ Features

-   **🎯 Simple Interface** - Clean, native macOS design built with SwiftUI
-   **⚙️ Preferences Window** - Centralized settings for downloads, subtitles, and advanced options
-   **🎬 Quality Options** - Best, 1440p, 1080p, 720p, 480p, or Audio-only (MP3)
-   **📁 Flexible Output** - Choose any directory for downloads
-   **⚡ Real-time Progress** - Live percentage, speed, and ETA
-   **📊 Detailed Logs** - View complete yt-dlp output
-   **🚀 100% Local** - No cloud services, no telemetry
-   **🌐 1000+ Sites** - YouTube, Instagram, Twitter, TikTok, Vimeo, and more
-   **🎭 Drag & Drop** - Drop URLs directly into the app
-   **📝 Subtitle Support** - Download and embed subtitles in multiple languages
-   **🔄 Auto-Retry** - Automatic retry on failed downloads (up to 3 attempts)
-   **⚡ Concurrent Downloads** - Download up to 5 playlist videos simultaneously
-   **📊 Playlist Queue UI** - Real-time progress tracking for each video in playlist
-   **🔍 Smart Detection** - Automatically detects yt-dlp and ffmpeg locations
-   **⏱️ Timeout Protection** - Format detection with 10-second timeout
-   **💾 Disk Space Check** - Automatic validation before downloads
-   **🧹 Auto-Cleanup** - Optional cleanup of subtitle files after embedding
-   **📏 SwiftLint Ready** - Code quality configuration included

---

## 🚀 Quick Start (Beginner-Friendly)

### Step 1: Install Xcode (First Time Only)

1. **Open App Store** on your Mac
2. **Search for "Xcode"**
3. **Click "Get"** or "Install" (it's free, but large ~15GB)
4. **Wait for installation** (takes 20-30 minutes)
5. **Open Xcode once** to accept the license agreement

### Step 2: Install Dependencies

Open **Terminal** (press `⌘ + Space`, type "Terminal", press Enter):

```bash
# Install Homebrew (if you don't have it)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install yt-dlp and ffmpeg
brew install yt-dlp ffmpeg
```

### Step 3: Open the Project

Navigate to the folder and open the Xcode project:

**Using Finder (Easiest):**

1. Open Finder and navigate to "Bhemu UNI Downloader/BhemuUNIDownloader" folder
2. **Double-click** `BhemuUNIDownloader.xcodeproj` (blue Xcode icon)
3. Xcode opens with the project

**Or using Terminal:**

```bash
cd "Bhemu UNI Downloader/BhemuUNIDownloader"
open BhemuUNIDownloader.xcodeproj
```

### Step 4: Build & Run in Xcode

1. **Wait for indexing** to finish (bottom center shows "Indexing..." - wait ~30 seconds)

2. **Select your Mac:**

    - Look at the top toolbar
    - Click the dropdown next to the Play button
    - Select **"My Mac"** (or your Mac's name)

3. **Click the Play button** (▶️) in the top-left corner
    - Or press `⌘R` on your keyboard
    - Wait ~30 seconds for building
    - **The app launches!** 🎉

### Step 5: Start Downloading!

1. Paste any video URL
2. Select quality
3. Choose output folder
4. Click "Start Download"

---

## 🆘 Troubleshooting

### "command not found: brew"

Install Homebrew first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### "Build Failed" in Xcode

1. Menu: **Product** → **Clean Build Folder** (or press `⇧⌘K`)
2. Click Play button again

### "No scheme" or can't select destination

1. Click dropdown next to Play button
2. Make sure it says "Bhemu UNI Downloader"
3. Select "My Mac" as destination

### App says "Missing dependencies"

Install them:

```bash
brew install yt-dlp ffmpeg
```

### Still having issues?

1. Make sure you have **macOS 13.0+** (check Apple menu → About This Mac)
2. Make sure you have **Xcode 14.0+** (check in App Store)
3. Try restarting Xcode

---

## 📖 Usage

### Supported URLs

-   **YouTube**: videos, playlists, channels, shorts, livestreams
-   **Instagram, Twitter/X, TikTok, Facebook, Reddit**
-   **Vimeo, Twitch, SoundCloud**
-   **1000+ more sites** - [Full list](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)

### Quality Presets

| Preset       | Output                                               |
| ------------ | ---------------------------------------------------- |
| Best Quality | Highest available video + audio (4K/8K if available) |
| 1440p        | 2K resolution with any codec                         |
| 1080p MP4    | 1080p H.264 video with audio                         |
| 720p MP4     | 720p H.264 video with audio                          |
| 480p MP4     | 480p H.264 video with audio                          |
| Audio Only   | MP3 audio extracted from video                       |

### Subtitle Support

-   **Download subtitles** in multiple languages (e.g., `en`, `es`, `fr`)
-   **Embed subtitles** directly into video files
-   **Auto-cleanup option**: Remove separate subtitle files after embedding
-   **Auto-generated** and **manual** subtitles supported
-   Subtitle files saved separately when not embedded or when "Keep files" is enabled

### Advanced Features

-   **Auto-Retry**: Failed downloads automatically retry up to 3 times
-   **Concurrent Downloads**: Playlists download up to 3 videos simultaneously
-   **Playlist Queue UI**: Real-time visual progress for each video in the queue:
    -   🕐 **Queued**: Waiting to start
    -   ⬇️ **Downloading**: Active with progress bar, speed, and ETA
    -   ✅ **Completed**: Successfully downloaded
    -   ❌ **Failed**: Download failed (after all retries)
    -   🔄 **Retrying**: Attempting download again
-   **Smart Binary Detection**: Automatically finds yt-dlp and ffmpeg on both Intel and Apple Silicon Macs
-   **Timeout Protection**: Format detection times out after 10 seconds to prevent hanging
-   **Drag & Drop**: Drop video URLs directly into the URL field

### Keyboard Shortcuts

-   `⌘↩` - Start download
-   `⌘.` - Cancel download
-   `⌘N` - New download (after completion)

---

## 🏗️ Project Structure

```
BhemuUNIDownloader/
├── BhemuUNIDownloader.swift              # App entry point
├── Views/
│   ├── ContentView.swift       # Main UI
│   ├── PlaylistSelectionView.swift # Playlist picker
│   └── SettingsView.swift      # Preferences window
├── ViewModels/
│   ├── DownloadViewModel.swift # Download logic
│   └── PlaylistViewModel.swift # Playlist logic
├── Models/
│   ├── DownloadQuality.swift   # Quality presets
│   ├── DownloadState.swift     # State machine
│   ├── DownloadProgress.swift  # Progress tracking
│   ├── PlaylistItem.swift      # Playlist data
│   ├── PlaylistDownloadProgress.swift # Playlist progress
│   ├── VideoFormatInfo.swift   # Format metadata
│   └── DownloadSettings.swift  # User preferences
├── Services/
│   ├── YTDLPRunner.swift       # Process execution
│   └── FormatFetcher.swift     # Quality detection
└── Utilities/
    ├── ProgressParser.swift    # Output parsing
    └── DiskSpaceChecker.swift  # Disk validation
```

**Architecture**: MVVM (Model-View-ViewModel)

-   **Models**: Data structures (quality, state, progress)
-   **Views**: SwiftUI UI components
-   **ViewModels**: State management & business logic
-   **Services**: External process handling (yt-dlp execution)
-   **Utilities**: Helper functions (parsing, disk checks)

---

## 🔧 Technical Details

### Implementation Highlights

-   **Thread-safe**: All UI updates on main thread via `@MainActor`
-   **Real-time streaming**: Live output capture via Pipes
-   **Non-blocking**: Async subprocess execution
-   **Memory efficient**: Proper cleanup, weak references
-   **Error handling**: Graceful failures with user feedback
-   **Smart binary detection**: Automatic path discovery for Intel/Apple Silicon
-   **Concurrent execution**: TaskGroup-based parallel downloads
-   **Retry logic**: Exponential backoff with configurable attempts
-   **Timeout handling**: Network and format detection timeouts

### Configuration Options

Access settings via **Bhemu UNI Downloader → Settings** (⌘,) or edit `DownloadSettings.swift`:

```swift
struct DownloadSettings {
    var maxConcurrentDownloads: Int = 3      // Playlist concurrency (1-5)
    var autoRetryOnFailure: Bool = true      // Enable auto-retry
    var maxRetryAttempts: Int = 3            // Retry attempts (1-5)
    var downloadSubtitles: Bool = false      // Download subtitles
    var subtitleLanguages: String = "en"     // Subtitle languages
    var embedSubtitles: Bool = true          // Embed in video
    var keepSubtitleFiles: Bool = false      // Keep separate files
}
```

### Quality Format Strings

```swift
Best:     -f "bestvideo+bestaudio/best"
1440p:    -f "bestvideo[height<=1440]+bestaudio/best"
1080p:    -f "bv*[vcodec^=avc1][height<=1080]+ba/best"
720p:     -f "bv*[vcodec^=avc1][height<=720]+ba/best"
480p:     -f "bv*[vcodec^=avc1][height<=480]+ba/best"
Audio:    -x --audio-format mp3 --audio-quality 0
```

### Subtitle Options

```swift
--write-subs                    // Download subtitle files
--sub-langs en,es,fr           // Specify languages
--embed-subs                   // Embed into video
```

---

## 🛠️ Customization

### Add New Quality Preset

Edit `DownloadQuality.swift`:

```swift
case p480 = "480p MP4"

var formatArguments: [String] {
    case .p480:
        return ["-f", "bv*[ext=mp4][height<=480]+ba[ext=m4a]/best"]
}
```

### Add Custom yt-dlp Arguments

Edit `YTDLPRunner.swift` in the `startDownload` method:

```swift
// Add after quality arguments
arguments.append("--embed-thumbnail")
arguments.append("--embed-metadata")
```

---

## 🐛 Troubleshooting

### "Missing dependencies" error

```bash
# Verify installation
which yt-dlp    # Should output: /opt/homebrew/bin/yt-dlp
which ffmpeg    # Should output: /opt/homebrew/bin/ffmpeg

# Reinstall if needed
brew reinstall yt-dlp ffmpeg
```

### Download fails

1. Check log panel for error messages
2. Verify URL works in browser
3. Update yt-dlp: `brew upgrade yt-dlp`
4. Test in terminal: `yt-dlp <URL>`

### App won't build

1. Requires **macOS 13.0+** (Ventura or later)
2. Requires **Xcode 14.0+**
3. Clean build: `⇧⌘K` then rebuild

### Can't select output folder

Grant permissions in **System Settings → Privacy & Security → Files and Folders**

---

## 📦 Distribution

### Create Standalone App (No Xcode needed to run)

Once built, copy the app to Applications:

```bash
cp -R build/Release/Bhemu\ UNI\ Downloader.app /Applications/
```

Now anyone can run it by double-clicking (yt-dlp and ffmpeg still required).

### Create DMG Installer (No Xcode needed)

```bash
# Create DMG for easy distribution
hdiutil create -volname "yt-dlp Downloader" \
               -srcfolder build/Release/Bhemu\ UNI\ Downloader.app \
               -ov -format UDZO \
               YTDLPDownloader.dmg
```

Users can then:

1. Download the DMG
2. Drag the app to Applications
3. Install yt-dlp and ffmpeg: `brew install yt-dlp ffmpeg`
4. Run the app!

---

## 📚 Additional Documentation

-   **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete architecture guide with detailed diagrams
-   **[APP_ICON_GUIDE.md](APP_ICON_GUIDE.md)** - How to create and add your custom app icon
-   **[Yt-dlp guide doc.md](Yt-dlp%20guide%20doc.md)** - Complete yt-dlp capabilities reference

---

## 🔐 Privacy & Security

-   **100% Local**: All processing on your Mac
-   **No Telemetry**: Zero data collection or analytics
-   **No Cloud**: No external services or API calls
-   **Open & Auditable**: All code is visible and readable

---

## 💡 Tips

1. **Update regularly**: Run `brew upgrade yt-dlp` weekly
2. **Playlist downloads**: Paste playlist URL to download all videos (up to 5 concurrent)
3. **Check logs**: Error details appear in the log panel
4. **Test URLs**: Try in browser first if download fails
5. **Audio extraction**: Great for converting music videos to MP3
6. **Drag & drop**: Drop URLs from your browser directly into the app
7. **Subtitles**: Enable subtitle download for language learning or accessibility
8. **Auto-retry**: Failed downloads automatically retry up to 3 times
9. **Settings**: Access preferences via **Bhemu UNI Downloader → Settings** or press ⌘,
10. **Disk space**: App automatically checks available space before downloads
11. **Intel Macs**: The app automatically detects binaries in `/usr/local/bin/`
12. **Code quality**: Run `swiftlint` to check code (config included)

---

## ⚖️ Legal & Disclaimer

This application is a **GUI wrapper** around yt-dlp. It does not:

-   Bypass DRM or copy protection
-   Violate terms of service
-   Encourage piracy

**Your Responsibility**: Comply with terms of service and respect copyright laws.

---

## 🚧 Future Ideas

-   [x] Multiple concurrent downloads ✅
-   [x] Auto-retry mechanism ✅
-   [x] Drag & drop URL support ✅
-   [x] Subtitle options ✅
-   [ ] Download queue management
-   [ ] Download history
-   [ ] Thumbnail preview

---

## 🙏 Acknowledgments

-   **[yt-dlp](https://github.com/yt-dlp/yt-dlp)** - The powerful download engine
-   **[FFmpeg](https://ffmpeg.org/)** - Media processing toolkit
-   **Apple** - Swift and SwiftUI frameworks

---

<div align="center">

**Built with ❤️ using Swift and SwiftUI**

_January 2026_

</div>
