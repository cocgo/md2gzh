#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="md2gzh"
VERSION=$(grep '^version:' "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | cut -d'+' -f1)
RELEASE_DIR="$PROJECT_DIR/release"

echo "=== $APP_NAME v$VERSION ==="

mkdir -p "$RELEASE_DIR"

# Android APK
echo "[1/3] Building Android APK..."
cd "$PROJECT_DIR"
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk "$RELEASE_DIR/${APP_NAME}-${VERSION}-android.apk"
echo "  -> ${APP_NAME}-${VERSION}-android.apk"

# macOS APP
echo "[2/3] Building macOS APP..."
flutter build macos --release
cd build/macos/Build/Products/Release
zip -r "$RELEASE_DIR/${APP_NAME}-${VERSION}-macos.zip" "MD公众号.app" -q
echo "  -> ${APP_NAME}-${VERSION}-macos.zip"

# Web
echo "[3/3] Building Web..."
cd "$PROJECT_DIR"
flutter build web --release
cd build/web
zip -r "$RELEASE_DIR/${APP_NAME}-${VERSION}-web.zip" . -q
echo "  -> ${APP_NAME}-${VERSION}-web.zip"

echo ""
echo "=== Done ==="
ls -lh "$RELEASE_DIR"/${APP_NAME}-${VERSION}-*
