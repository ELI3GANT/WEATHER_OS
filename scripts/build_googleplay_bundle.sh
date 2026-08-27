#!/bin/bash
set -e

echo "=========================================================="
echo " WEATHEROS GOOGLE PLAY RELEASE PIPELINE (AAB)"
echo "=========================================================="

echo "1. Fetching dependencies..."
flutter pub get

echo ""
echo "2. Building Google Play App Bundle (.aab)..."
flutter build appbundle --release

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
    SIZE_MB=$(du -m "$AAB_PATH" | cut -f1)
    echo ""
    echo "=========================================================="
    echo "✅ SUCCESS: App Bundle generated successfully!"
    echo "Path: $AAB_PATH"
    echo "Size: ~${SIZE_MB} MB"
    echo "=========================================================="
    echo "Upload this file to Google Play Console under Testing -> Closed testing."
else
    echo "❌ Error: $AAB_PATH was not found."
    exit 1
fi
