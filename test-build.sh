#!/bin/bash
set -o pipefail

# Quick Test Build Script
# Tests the bundled binaries without creating full DMG

echo "🧪 Testing Bhemu UNI Downloader Build..."
echo ""

# Build configuration
APP_NAME="Bhemu UNI Downloader"
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Quick clean build
echo "🔨 Building app..."
xcodebuild -project "BhemuUNIDownloader.xcodeproj" \
    -scheme "Bhemu UNI Downloader" \
    -configuration Debug \
    build \
    | grep -E "^\*\*|error:|warning:|succeeded|failed"

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "*.app" -path "*/Debug/*" | grep "Bhemu UNI Downloader" | head -n 1)

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Built app not found!"
    exit 1
fi

echo "✅ App built at: $APP_PATH"

# Bundle dependencies
echo ""
echo "📦 Bundling dependencies..."
RESOURCES_PATH="$APP_PATH/Contents/Resources"
mkdir -p "$RESOURCES_PATH"

if [ -f "$PROJECT_DIR/Binaries/yt-dlp" ]; then
    cp "$PROJECT_DIR/Binaries/yt-dlp" "$RESOURCES_PATH/"
    chmod +x "$RESOURCES_PATH/yt-dlp"
    echo "✅ Bundled yt-dlp"
else
    echo "⚠️  Warning: yt-dlp not found. Run: cd Binaries && ./download-binaries.sh"
fi

if [ -f "$PROJECT_DIR/Binaries/ffmpeg" ]; then
    cp "$PROJECT_DIR/Binaries/ffmpeg" "$RESOURCES_PATH/"
    chmod +x "$RESOURCES_PATH/ffmpeg"
    echo "✅ Bundled ffmpeg"
else
    echo "⚠️  Warning: ffmpeg not found. Run: cd Binaries && ./download-binaries.sh"
fi

# Verify
echo ""
echo "🔍 Verifying bundle contents..."
if [ -x "$RESOURCES_PATH/yt-dlp" ] && [ -x "$RESOURCES_PATH/ffmpeg" ]; then
    echo "✅ All binaries present and executable"
    echo ""
    echo "📦 Bundle contents:"
    ls -lh "$RESOURCES_PATH/" | grep -E "yt-dlp|ffmpeg"
else
    echo "⚠️  Some binaries missing or not executable"
fi

echo ""
echo "🚀 Opening app..."
open "$APP_PATH"

echo ""
echo "✅ Test build complete!"
echo ""
echo "💡 To create release DMG, run: ./build-release.sh"
