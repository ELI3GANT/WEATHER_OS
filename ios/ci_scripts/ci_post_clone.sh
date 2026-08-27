#!/bin/sh
set -e

# 1. Install Flutter (stable branch)
echo "=== Installing Flutter SDK ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 2. Pre-cache iOS engine artifacts
echo "=== Pre-caching iOS Artifacts ==="
flutter precache --ios

# 3. Get pub dependencies
echo "=== Getting Flutter Packages ==="
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

# 4. Install CocoaPods dependencies
echo "=== Installing CocoaPods ==="
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"
pod install

echo "=== Xcode Cloud CI Setup Complete ==="
