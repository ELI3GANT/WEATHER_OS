#!/bin/bash

# Trace commands for full visibility in Xcode Cloud logs
set -x
set -e

# Export full system paths including Homebrew & Flutter
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/flutter/bin"

echo "=== System Architecture: $(uname -m) ==="
echo "=== Current Working Directory: $(pwd) ==="

# 1. Install Flutter (stable)
if [ ! -d "$HOME/flutter" ]; then
    echo "=== Cloning Flutter SDK ==="
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

export FLUTTER_ROOT="$HOME/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"

which flutter || true
flutter --version

# 2. Precache iOS engine
echo "=== Precaching iOS Engine ==="
flutter precache --ios

# 3. Locate Root Workspace Directory
TARGET_DIR="${CI_WORKSPACE:-$CI_PRIMARY_REPOSITORY_PATH}"
if [ -z "$TARGET_DIR" ] || [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
    if [ -f "$(pwd)/../../pubspec.yaml" ]; then
        TARGET_DIR="$(cd "$(pwd)/../.." && pwd)"
    elif [ -f "$(pwd)/../pubspec.yaml" ]; then
        TARGET_DIR="$(cd "$(pwd)/.." && pwd)"
    elif [ -f "$(pwd)/pubspec.yaml" ]; then
        TARGET_DIR="$(pwd)"
    fi
fi

echo "=== Target Flutter Project: $TARGET_DIR ==="
cd "$TARGET_DIR"

# 4. Check and install CocoaPods
echo "=== Checking CocoaPods ==="
if ! command -v pod &> /dev/null; then
    echo "Installing CocoaPods..."
    if command -v brew &> /dev/null; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true
    else
        gem install cocoapods --user-install || true
    fi
fi

# 5. Build Flutter iOS Release Artifacts (creates App.framework, Flutter.framework, and dart assets)
echo "=== Building Flutter iOS Release Artifacts ==="
flutter pub get
flutter build ios --release --no-codesign

# 6. Ensure CocoaPods are installed
echo "=== Running Pod Install ==="
cd "$TARGET_DIR/ios"
if command -v pod &> /dev/null; then
    pod install
elif [ -x "/opt/homebrew/bin/pod" ]; then
    /opt/homebrew/bin/pod install
elif [ -x "/usr/local/bin/pod" ]; then
    /usr/local/bin/pod install
fi

echo "=== Xcode Cloud Post-Clone Finished Successfully ==="
exit 0
