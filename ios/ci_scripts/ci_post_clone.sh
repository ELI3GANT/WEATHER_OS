#!/bin/sh

# Fail immediately on errors
set -e

# Ensure Homebrew and Flutter are in PATH for both Apple Silicon and Intel macOS
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/flutter/bin:$PATH"

# 1. Install Flutter (stable)
echo "=== Installing Flutter SDK ==="
if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

# 2. Pre-cache iOS engine artifacts
echo "=== Pre-caching iOS Artifacts ==="
"$HOME/flutter/bin/flutter" precache --ios

# 3. Locate root project directory
ROOT_DIR="${CI_WORKSPACE:-$CI_PRIMARY_REPOSITORY_PATH}"
if [ -z "$ROOT_DIR" ]; then
    ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
fi

echo "Root project directory: $ROOT_DIR"
cd "$ROOT_DIR"

# 4. Fetch Flutter packages
echo "=== Getting Flutter Packages ==="
"$HOME/flutter/bin/flutter" pub get

# 5. Verify/Install CocoaPods
echo "=== Checking CocoaPods ==="
if ! command -v pod >/dev/null 2>&1; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true
fi

# 6. Install Pods in ios directory
cd "$ROOT_DIR/ios"
pod install

echo "=== Xcode Cloud CI Setup Complete ==="
exit 0
