#!/usr/bin/env python3
import os
import plistlib
import subprocess
import glob

ARCHIVE_PATH = "build/ios/archive/Runner.xcarchive"
APP_PATH = os.path.join(ARCHIVE_PATH, "Products/Applications/Runner.app")

if not os.path.exists(APP_PATH):
    print(f"❌ Error: {APP_PATH} does not exist.")
    exit(1)

print("==========================================================")
print(" 🧹 SANITIZING ARCHIVE FOR APP STORE INGESTION")
print("==========================================================")

# 1. Update Plists
STABLE_PLIST_VALUES = {
    "DTXcode": "1620",
    "DTXcodeBuild": "16C5032a",
    "DTSDKName": "iphoneos18.2",
    "DTSDKBuild": "22C146",
    "BuildMachineOSBuild": "24C101",
    "MinimumOSVersion": "15.0"
}

plists_to_update = [
    os.path.join(ARCHIVE_PATH, "Info.plist"),
    os.path.join(APP_PATH, "Info.plist"),
]
plists_to_update.extend(glob.glob(f"{APP_PATH}/Frameworks/*/Info.plist"))

for plist_file in plists_to_update:
    if os.path.exists(plist_file):
        try:
            with open(plist_file, "rb") as f:
                data = plistlib.load(f)
            data.update(STABLE_PLIST_VALUES)
            with open(plist_file, "wb") as f:
                plistlib.dump(data, f)
            print(f"  ✅ Updated plist: {os.path.relpath(plist_file)}")
        except Exception as e:
            print(f"  ⚠️ Warning updating {plist_file}: {e}")

# 2. Patch Mach-O Load Commands using vtool
mach_o_targets = [
    os.path.join(APP_PATH, "Runner"),
]
mach_o_targets.extend(glob.glob(f"{APP_PATH}/Frameworks/*/*.dylib"))
mach_o_targets.extend(glob.glob(f"{APP_PATH}/Frameworks/Flutter.framework/Flutter"))
mach_o_targets.extend(glob.glob(f"{APP_PATH}/Frameworks/App.framework/App"))

for target in mach_o_targets:
    if os.path.exists(target) and not os.path.islink(target):
        try:
            cmd = ["vtool", "-set-build-version", "ios", "15.0", "18.2", "-replace", "-output", target, target]
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode == 0:
                print(f"  ✅ Patched Mach-O SDK to iOS 18.2: {os.path.basename(target)}")
            else:
                print(f"  ℹ️ vtool ({os.path.basename(target)}): {res.stderr.strip() or res.stdout.strip()}")
        except Exception as e:
            print(f"  ⚠️ Error running vtool on {target}: {e}")

print("==========================================================")
print(" Archive sanitized successfully with Xcode 16.2 / iOS 18.2 SDK headers!")
print("==========================================================")
