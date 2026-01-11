#!/bin/bash

# Build and Package Script for Bhemu UNI Downloader
# This script builds the app, bundles dependencies, and creates a DMG installer

set -e

echo "🚀 Building Bhemu UNI Downloader..."
echo ""

# Configuration
APP_NAME="Bhemu UNI Downloader"
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/Release"
DMG_NAME="BhemuUNIDownloader-Installer"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Build the app using xcodebuild
echo ""
echo "🔨 Building app with Xcode..."
xcodebuild -project "BhemuUNIDownloader.xcodeproj" \
    -scheme "Bhemu UNI Downloader" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    clean build

# Find the built app
APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -n 1)

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Built app not found!"
    exit 1
fi

echo "✅ App built at: $APP_PATH"

# Note: Dependencies are NOT bundled - users install them via first-run setup
echo ""
echo "📝 Note: This app requires yt-dlp and ffmpeg to be installed"
echo "   The first-run wizard will install them automatically for users"

# Copy app to Release directory
echo ""
echo "📦 Preparing release package..."
cp -R "$APP_PATH" "$RELEASE_DIR/"
FINAL_APP_PATH="$RELEASE_DIR/$(basename "$APP_PATH")"

# CRITICAL: Remove quarantine flags and sign bundled binaries FIRST
# This prevents the 30-second Gatekeeper delay on first run
echo ""
echo "🔓 Preparing bundled binaries (prevents Gatekeeper delays)..."

if [ -f "$FINAL_APP_PATH/Contents/Resources/yt-dlp" ]; then
    # Remove any quarantine flags
    xattr -cr "$FINAL_APP_PATH/Contents/Resources/yt-dlp" 2>/dev/null || true
    # Sign the binary
    codesign --force --sign - "$FINAL_APP_PATH/Contents/Resources/yt-dlp" 2>/dev/null || true
    echo "  ✅ yt-dlp: quarantine removed & signed"
fi

if [ -f "$FINAL_APP_PATH/Contents/Resources/ffmpeg" ]; then
    # Remove any quarantine flags
    xattr -cr "$FINAL_APP_PATH/Contents/Resources/ffmpeg" 2>/dev/null || true
    # Sign the binary
    codesign --force --sign - "$FINAL_APP_PATH/Contents/Resources/ffmpeg" 2>/dev/null || true
    echo "  ✅ ffmpeg: quarantine removed & signed"
fi

# Ad-hoc code signing (helps with distribution)
echo ""
echo "✍️  Applying ad-hoc code signature to app bundle..."
if codesign --deep --force --sign - "$FINAL_APP_PATH" 2>/dev/null; then
    echo "✅ App bundle signed with ad-hoc signature"
    codesign -dv "$FINAL_APP_PATH" 2>&1 | grep "Signature" || true
else
    echo "⚠️  Warning: Could not apply ad-hoc signature (codesign not available)"
fi

# Get app size
APP_SIZE=$(du -sh "$FINAL_APP_PATH" | awk '{print $1}')
echo "✅ App size: $APP_SIZE"

# Create DMG
echo ""
echo "💿 Creating DMG installer..."

# Create temporary DMG directory
DMG_TEMP="$BUILD_DIR/dmg"
mkdir -p "$DMG_TEMP"

# Copy app to DMG directory
cp -R "$FINAL_APP_PATH" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG background (optional - we'll create a simple one)
mkdir -p "$DMG_TEMP/.background"

# Create a README for the DMG
cat > "$DMG_TEMP/README.txt" << 'EOF'
Bhemu UNI Downloader
====================

Installation:
1. Drag "Bhemu UNI Downloader.app" to the Applications folder
2. Launch the app - a welcome screen will appear
3. Click "Start Setup" to automatically install dependencies (3-5 minutes)
4. Done! Downloads will start instantly forever!

Note: The app will automatically install Homebrew, yt-dlp, and ffmpeg
for you. No terminal commands or technical knowledge required!

Features:
✅ One-click setup (installs everything automatically)
✅ Download from YouTube and 1000+ sites
✅ Multiple quality options (4K, 1440p, 1080p, 720p, 480p, Audio)
✅ Playlist support with concurrent downloads
✅ Subtitle support (download, embed, auto-translate)
✅ Browser cookie authentication
✅ Auto-retry on failure
✅ Beautiful native macOS UI

Author: Adarsh Suman
Email: adarsh3699@gmail.com
Website: https://bhemu.in

Copyright © 2026 Adarsh Suman. All rights reserved.
EOF

# Copy the fix script to DMG
if [ -f "$PROJECT_DIR/fix-app.sh" ]; then
    cp "$PROJECT_DIR/fix-app.sh" "$DMG_TEMP/"
    chmod +x "$DMG_TEMP/fix-app.sh"
    echo "✅ Added fix-app.sh to DMG"
fi

# Create the DMG
DMG_PATH="$RELEASE_DIR/$DMG_NAME.dmg"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

# Get DMG size
DMG_SIZE=$(du -sh "$DMG_PATH" | awk '{print $1}')

echo ""
echo "✅ DMG created: $DMG_PATH"
echo "📦 DMG size: $DMG_SIZE"

# Clean up temp directory
rm -rf "$DMG_TEMP"

echo ""
echo "🎉 Build complete!"
echo ""
echo "📦 Release artifacts:"
echo "  • App: $FINAL_APP_PATH"
echo "  • DMG: $DMG_PATH"
echo ""
echo "🚀 To distribute:"
echo "  1. Share the DMG file with users"
echo "  2. Users drag the app to Applications folder"
echo "  3. If 'damaged' error appears, run: bash fix-app.sh"
echo "     OR: xattr -cr '/Applications/Bhemu UNI Downloader.app'"
echo ""
echo "💡 For professional distribution (no warnings):"
echo "  • Get an Apple Developer account (\$99/year)"
echo "  • Sign with Developer ID certificate"
echo "  • Notarize with Apple"
echo "  • See DISTRIBUTION_GUIDE.md for details"
echo ""

# Optional: Code signing info
if command -v codesign &> /dev/null; then
    echo "📝 Code Signing Status:"
    codesign -dv "$FINAL_APP_PATH" 2>&1 | grep -E "(Signature|Authority)" || echo "  ✅ Ad-hoc signed (local use only)"
    echo ""
fi

echo "✅ Done!"
