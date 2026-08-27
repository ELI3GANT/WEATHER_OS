#!/bin/bash

# Trace commands for full visibility in Xcode Cloud logs
set -x
set -e

# Export full system paths including Homebrew & Flutter
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/flutter/bin"

echo "=== System Architecture: $(uname -m) ==="
echo "=== Current Working Directory: $(pwd) ==="
echo "=== Environment PATH: $PATH ==="

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

# 4. Fetch packages & configure iOS project environment
echo "=== Running flutter pub get ==="
flutter pub get

echo "=== Generating iOS Flutter Configuration for Cloud Environment ==="
flutter build ios --config-only --release --no-codesign || true

# Dynamic fallback path rewrites for Xcode Build Phases
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    sed -i '' "s|FLUTTER_ROOT=.*|FLUTTER_ROOT=$FLUTTER_ROOT|g" ios/Flutter/Generated.xcconfig || true
    sed -i '' "s|FLUTTER_APPLICATION_PATH=.*|FLUTTER_APPLICATION_PATH=$TARGET_DIR|g" ios/Flutter/Generated.xcconfig || true
fi

if [ -f "ios/Flutter/flutter_export_environment.sh" ]; then
    sed -i '' "s|export \"FLUTTER_ROOT=.*\"|export \"FLUTTER_ROOT=$FLUTTER_ROOT\"|g" ios/Flutter/flutter_export_environment.sh || true
    sed -i '' "s|export \"FLUTTER_APPLICATION_PATH=.*\"|export \"FLUTTER_APPLICATION_PATH=$TARGET_DIR\"|g" ios/Flutter/flutter_export_environment.sh || true
fi

# 5. Check and install CocoaPods
echo "=== Checking CocoaPods ==="
if ! command -v pod &> /dev/null; then
    echo "Installing CocoaPods..."
    if command -v brew &> /dev/null; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true
    else
        gem install cocoapods --user-install || true
    fi
fi

# 6. Run CocoaPods install
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
