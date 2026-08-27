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

# 4. Fetch packages & build Flutter iOS release assets
echo "=== Running flutter pub get ==="
flutter pub get

echo "=== Building Flutter iOS Release Assets ==="
flutter build ios --release --no-codesign

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

# 7. Update Generated.xcconfig and flutter_export_environment.sh with cloud paths
sed -i '' "s|FLUTTER_ROOT=.*|FLUTTER_ROOT=$FLUTTER_ROOT|g" "$TARGET_DIR/ios/Flutter/Generated.xcconfig" || true
sed -i '' "s|FLUTTER_APPLICATION_PATH=.*|FLUTTER_APPLICATION_PATH=$TARGET_DIR|g" "$TARGET_DIR/ios/Flutter/Generated.xcconfig" || true
sed -i '' "s|export \"FLUTTER_ROOT=.*\"|export \"FLUTTER_ROOT=$FLUTTER_ROOT\"|g" "$TARGET_DIR/ios/Flutter/flutter_export_environment.sh" || true
sed -i '' "s|export \"FLUTTER_APPLICATION_PATH=.*\"|export \"FLUTTER_APPLICATION_PATH=$TARGET_DIR\"|g" "$TARGET_DIR/ios/Flutter/flutter_export_environment.sh" || true

echo "=== Xcode Cloud Post-Clone Finished Successfully ==="
exit 0
