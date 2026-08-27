#!/bin/bash

# Trace commands for full visibility in Xcode Cloud logs
set -x
set -e

# Export full system paths including Homebrew & Flutter
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/flutter/bin"

echo "=== Architecture: $(uname -m) ==="
echo "=== Current Directory: $(pwd) ==="
echo "=== Environment PATH: $PATH ==="

# 1. Install Flutter
if [ ! -d "$HOME/flutter" ]; then
    echo "=== Cloning Flutter SDK ==="
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"
which flutter || true
flutter --version

# 2. Precache iOS
echo "=== Precaching iOS Engine ==="
flutter precache --ios

# 3. Locate Flutter root directory
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

echo "=== Moving to target dir: $TARGET_DIR ==="
cd "$TARGET_DIR"

# 4. Fetch dependencies
flutter pub get

# 5. Handle CocoaPods
echo "=== Resolving CocoaPods ==="
if ! command -v pod &> /dev/null; then
    echo "Installing CocoaPods..."
    if command -v brew &> /dev/null; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true
    else
        gem install cocoapods --user-install || true
    fi
fi

# 6. Run pod install in ios
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
