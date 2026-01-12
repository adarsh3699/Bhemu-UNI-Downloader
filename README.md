# Bhemu UNI Downloader

<div align="center">

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

**A beautiful macOS app for downloading videos from YouTube, Instagram, TikTok, and 1000+ websites.**

[Features](#-features) • [Quick Start](#-quick-start) • [Usage](#-usage) • [Contributing](#-contributing)

</div>

---

## ✨ Features

-   🌐 **1000+ Websites** - YouTube, Instagram, TikTok, Twitter, Vimeo, and more
-   🎬 **Multiple Quality Options** - Best, 1440p, 1080p, 720p, 480p, or Audio-only (MP3)
-   📋 **Playlist Support** - Download entire playlists with concurrent downloads
-   💬 **Subtitle Support** - Download and embed subtitles in multiple languages
-   ⚡ **Real-time Progress** - Live speed, percentage, and ETA tracking
-   🔄 **Auto-Retry** - Failed downloads automatically retry up to 3 times
-   🎭 **Drag & Drop** - Drop URLs directly into the app
-   🔒 **100% Private** - All processing happens locally on your Mac

---

## 🚀 Quick Start

### For Users (Download Pre-built App)

1. Download the latest `.dmg` from [Releases](https://github.com/adarsh3699/Bhemu-UNI-Downloader/releases)
2. Open the DMG and drag the app to Applications
3. Launch the app - it will automatically install dependencies
4. Start downloading! 🎉

### For Developers (Build from Source)

#### 1. Prerequisites

-   macOS 13.0+ (Ventura or later)
-   Xcode 14.0+

#### 2. Clone & Build

```bash
# Clone the repository
git clone https://github.com/adarsh3699/Bhemu-UNI-Downloader.git
cd Bhemu-UNI-Downloader

# Open in Xcode
open BhemuUNIDownloader.xcodeproj

# Build and run (⌘+R)
```

The app will automatically install `yt-dlp` and `ffmpeg` on first launch.

---

## 📖 Usage

### Downloading Videos

1. **Paste URL** - Copy any video URL and paste it into the app
2. **Select Quality** - Choose from Best, 1080p, 720p, 480p, or Audio-only
3. **Choose Folder** (optional) - Select where to save the video
4. **Start Download** - Click the button or press `⌘↩`

### Downloading Playlists

1. **Paste Playlist URL** - The app will detect it's a playlist
2. **Select Videos** - Choose which videos to download
3. **Pick Quality** - Select preferred quality
4. **Download** - Up to 3 videos download simultaneously

### Subtitles

1. Open **Settings** (⌘,)
2. Enable **"Download Subtitles"**
3. Enter language codes (e.g., `en`, `es`, `fr`)
4. Enable **"Embed in Video"** to include subtitles in the file

### Supported Websites

YouTube • Instagram • TikTok • Twitter/X • Facebook • Reddit • Vimeo • Twitch • SoundCloud • [1000+ more](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)

### Keyboard Shortcuts

-   `⌘↩` - Start download
-   `⌘.` - Cancel download
-   `⌘,` - Open settings
-   `⌘?` - Help

---

## 🛠️ Troubleshooting

**"Cannot be opened because Apple cannot verify it is free from malware"**

This is a normal macOS security warning for unsigned apps. To fix:

1. Go to **System Settings** → **Privacy & Security**
2. Scroll down to the **Security** section
3. You'll see a message: _"Bhemu UNI Downloader was blocked from use because it is not from an identified developer"_
4. Click **Open Anyway**
5. In the confirmation dialog, click **Open**

The app will now launch normally. This only needs to be done once.

**Alternative methods:**

**Method 2 - Right-click:**

-   Right-click the app → **Open** → Click **Open** in the warning dialog

**Method 3 - Terminal command:**

```bash
xattr -cr /Applications/Bhemu\ UNI\ Downloader.app
```

This removes the quarantine attribute. Run this in Terminal if the app is in your Applications folder.

**Download fails?**

-   Check if the URL works in your browser
-   Update yt-dlp: `brew upgrade yt-dlp`
-   Check the Download Log for error details

**Build issues?**

-   Clean build folder: `⇧⌘K` then rebuild in Xcode
-   Make sure you're running macOS 13.0+ and Xcode 14.0+

**Still stuck?** Open an [issue](https://github.com/adarsh3699/Bhemu-UNI-Downloader/issues) or check the built-in Help (⌘?)

---

## 🏗️ Project Structure

```
BhemuUNIDownloader/
├── Views/          # SwiftUI UI components
├── ViewModels/     # Business logic & state management
├── Models/         # Data structures
├── Services/       # yt-dlp & ffmpeg integration
└── Utilities/      # Helper functions
```

**Architecture**: MVVM (Model-View-ViewModel) with SwiftUI

---

## 🤝 Contributing

We welcome contributions! Whether it's bug reports, feature requests, or code improvements.

**Quick Start:**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**TL;DR:** Free to use, modify, and distribute. No warranties provided.

---

## 🙏 Acknowledgments

-   **[yt-dlp](https://github.com/yt-dlp/yt-dlp)** - The powerful download engine
-   **[FFmpeg](https://ffmpeg.org/)** - Media processing toolkit
-   **Apple** - Swift and SwiftUI frameworks

---

## ⭐ Support

If you find this project useful, please give it a star! ⭐

**Author:** Adarsh Suman ([adarsh3699@gmail.com](mailto:adarsh3699@gmail.com))  
**Website:** [bhemu.in](https://bhemu.in)

---

<div align="center">

**Built with ❤️ using Swift and SwiftUI**

[⬆ Back to Top](#bhemu-uni-downloader)

</div>
