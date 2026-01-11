# Contributing to Bhemu UNI Downloader

First off, thank you for considering contributing to Bhemu UNI Downloader! 🎉

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

-   **Clear title** describing the issue
-   **Steps to reproduce** the problem
-   **Expected behavior** vs actual behavior
-   **Screenshots** if applicable
-   **macOS version** and app version
-   **Console logs** from the Download Log panel

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

-   **Clear title** and description
-   **Use case** - why would this be useful?
-   **Mockups** or examples if applicable

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Make your changes**
4. **Test thoroughly** on your Mac
5. **Run SwiftLint** to ensure code quality
6. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
7. **Push to the branch** (`git push origin feature/AmazingFeature`)
8. **Open a Pull Request**

## 💻 Development Setup

### Requirements

-   macOS 13.0+ (Ventura or later)
-   Xcode 14.0+
-   Homebrew
-   yt-dlp and ffmpeg (`brew install yt-dlp ffmpeg`)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/adarsh3699/Bhemu-UNI-Downloader.git
cd Bhemu-UNI-Downloader

# Open in Xcode
open BhemuUNIDownloader.xcodeproj

# Build and run (⌘+R)
```

## 📝 Code Style

-   Follow **Swift standard naming conventions**
-   Use **meaningful variable names**
-   Add **comments** for complex logic
-   Keep functions **small and focused**
-   Use **MVVM architecture** pattern
-   Run **SwiftLint** before committing

### SwiftLint

```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint
```

## 🏗️ Project Structure

```
BhemuUNIDownloader/
├── Views/           # SwiftUI views
├── ViewModels/      # Business logic & state
├── Models/          # Data structures
├── Services/        # External process handling
└── Utilities/       # Helper functions
```

## 🧪 Testing

-   Test on both **Intel and Apple Silicon Macs** if possible
-   Test with **various video URLs** (YouTube, Instagram, TikTok, etc.)
-   Test **playlist downloads**
-   Test **subtitle functionality**
-   Check **error handling**

## 📄 Commit Messages

Use clear, descriptive commit messages:

-   `feat: Add subtitle language selection`
-   `fix: Resolve playlist progress tracking issue`
-   `docs: Update README with new features`
-   `refactor: Simplify download state management`
-   `style: Format code with SwiftLint`

## 🐛 Bug Fixes

When fixing bugs:

1. **Reference the issue** in your PR
2. **Explain the root cause**
3. **Describe your solution**
4. **Add tests** if applicable

## ✨ Feature Development

When adding features:

1. **Discuss in an issue first** for major features
2. **Keep UI consistent** with existing design
3. **Update documentation** (README, Help view)
4. **Consider backward compatibility**

## 🔍 Code Review Process

-   All PRs require review
-   Be respectful and constructive
-   Address feedback promptly
-   Maintainers will merge when ready

## 📞 Questions?

-   **Email:** adarsh3699@gmail.com
-   **GitHub Issues:** For technical questions
-   **Discussions:** For general questions

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making Bhemu UNI Downloader better! 🚀
