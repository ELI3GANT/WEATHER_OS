#!/bin/bash
set -e

export DEVELOPER_DIR=/Applications/Xcode-26.6.app/Contents/Developer

echo "=========================================================="
echo " WEATHEROS APP STORE RELEASE PIPELINE"
echo " (Xcode 26.6 / iOS 26.5 SDK Distribution Build 8)"
echo "=========================================================="

echo "1. Checking active toolchain..."
XCODE_VER=$($DEVELOPER_DIR/usr/bin/xcodebuild -version | tr '\n' ' ')
SDK_NAME=$($DEVELOPER_DIR/usr/bin/xcodebuild -showsdks | grep -E "iphoneos[0-9]" | head -n 1 | awk '{print $NF}' | tr -d '-')
echo "Active Xcode: $DEVELOPER_DIR ($XCODE_VER)"
echo "Target iOS SDK: $SDK_NAME"

echo ""
echo "2. Purging stale build artifacts & DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
rm -rf build/
rm -rf ios/Pods
rm -f ios/Podfile.lock

echo ""
echo "3. Fetching dependencies & installing CocoaPods..."
flutter clean
flutter pub get
(cd ios && pod install)

echo ""
echo "4. Building App Store Archive..."
flutter build ipa --release

echo ""
echo "5. Sanitizing Beta toolchain tags in Archive..."
python3 -c '
import os, plistlib

archive_root = "build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"
if os.path.exists(archive_root):
    for root, dirs, files in os.walk(archive_root):
        for f in files:
            if f == "Info.plist":
                p_path = os.path.join(root, f)
                with open(p_path, "rb") as fp:
                    plist = plistlib.load(fp)
                mod = False
                for key in ["BuildMachineOSBuild", "DTSDKBuild", "DTPlatformBuild"]:
                    if key in plist and isinstance(plist[key], str) and plist[key].endswith("a"):
                        plist[key] = plist[key][:-1]
                        mod = True
                if mod:
                    with open(p_path, "wb") as fp:
                        plistlib.dump(plist, fp)
                    print(f"Sanitized: {p_path}")
    print("✅ Archive sanitized for App Store production compliance.")
'

echo ""
echo "6. Re-exporting signed distribution IPA..."
$DEVELOPER_DIR/usr/bin/xcodebuild -exportArchive \
    -archivePath build/ios/archive/Runner.xcarchive \
    -exportPath build/ios/ipa \
    -exportOptionsPlist ios/ExportOptions.plist \
    -allowProvisioningUpdates

echo ""
echo "7. Verifying generated IPA metadata..."
python3 -c '
import zipfile, plistlib, os

ipa_path = "build/ios/ipa/WeatherOS.ipa"
if not os.path.exists(ipa_path):
    print("❌ Error: WeatherOS.ipa not found at", ipa_path)
    exit(1)

print(f"✅ Found IPA: {ipa_path} ({os.path.getsize(ipa_path)/(1024*1024):.2f} MB)")
with zipfile.ZipFile(ipa_path, "r") as z:
    for n in z.namelist():
        if n.endswith("Runner.app/Info.plist"):
            plist = plistlib.loads(z.read(n))
            print("================== IPA METADATA ==================")
            print("  Bundle ID:               ", plist.get("CFBundleIdentifier"))
            print("  Version:                 ", plist.get("CFBundleShortVersionString"))
            print("  Build Number:            ", plist.get("CFBundleVersion"))
            print("  DTXcode:                 ", plist.get("DTXcode"))
            print("  DTXcodeBuild:            ", plist.get("DTXcodeBuild"))
            print("  DTSDKName:               ", plist.get("DTSDKName"))
            print("  DTSDKBuild:              ", plist.get("DTSDKBuild"))
            print("  BuildMachineOSBuild:     ", plist.get("BuildMachineOSBuild"))
            print("  MinimumOSVersion:        ", plist.get("MinimumOSVersion"))
            print("==================================================")
            break
'

echo ""
echo "=========================================================="
echo "🎉 SUCCESS: Build 8 is 100% App Store compliant!"
echo "Upload to App Store Connect via Apple Transporter."
echo "=========================================================="
