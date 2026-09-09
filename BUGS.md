# WeatherOS Bugs

_Last updated: 2026-09-08. Only reproduced or source-proven issues are listed. A passing compile is never treated as device verification._

| ID | Severity | Area | Reproduction | Root Cause | Fix | Verification | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| WOS-001 | P2 | Android device install | Install the arm64 restored-source debug APK on LG G7. | LG G7 has only 968 MB free; Android cannot allocate the required internal install session for the 642 MB APK. | Free approximately 2 GB; retry `adb install -r`. Do not uninstall unless Android returns `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. | APK built and install failure captured. | Blocked — device storage |
| WOS-003 | P1 | Cache/location identity | Search another city, close app, then start without current location. | One global payload/key has no coordinate or location identity. | Add scoped cache identity after focused behavioral tests. | Source trace complete; device test pending source build. | Open |
| WOS-004 | P3 | Visual regression tests | Run compact showcase golden. | Expected palette predates later atmosphere-engine changes; card/text/icon geometry aligns but background differs by 98.51%. | Keep baseline unchanged pending visual review. | Diagnostic images compared. | Open — review |
| WOS-005 | P3 | Visual regression tests | Run all visual goldens. | Showcase baseline drift; home large-text has a 320-pixel delta. | Isolate each; never update images only to suppress tests. | Eight baseline failures. | Open |
| WOS-006 | P4 | Tooling | Run Android build. | SDK command-line tools warn on metadata XML v4. | Align tooling only if it affects compatible build host. | Warning observed; not blocker. | Open |
| WOS-011 | P2 | iOS widget/watch telemetry | Export telemetry on an iOS build without an entitled App Group. | Runner has no App Group entitlement; widget/watch sources are not Xcode extension targets, while the bridge previously treated a nil shared defaults suite as success. | Return an explicit platform-channel error; defer extension/capability work until deliberately scoped. | Static target/entitlement trace; Xcode device build pending. | Fixed — static verification |
| WOS-012 | P2 | watchOS prototype compile | Compile `WeatherOSWatch/WatchSessionReceiver.swift` after it becomes a real target. | Swift uses lowercase `int`, which is not the Swift integer type. | Use `Int`. | Static source verification; no watchOS target/Xcode host available. | Fixed — static verification |
| WOS-013 | P2 | Xcode Cloud reproducibility | Run the configured post-clone build at a later date. | Script cloned moving Flutter `stable`, diverging from FVM 3.47.2. | Pin post-clone Flutter checkout to 3.47.2. | Shell syntax check pending; cloud build not triggered from Linux. | Fixed — static verification |

## Android

- LG G7 (`LMG710ULM143754a3`) is connected, location is enabled, and the existing 1.0.6 installation has fine/coarse location permission.
- The installed APK is Flagship-era and is not valid verification for restored `main`.
- ARM64 Arch Linux can now build restored-source APKs with JDK 17 plus the user-level QEMU AAPT2 sysroot/wrapper. Device installation remains storage-blocked only.

## iOS

- This Linux host cannot build iOS or inspect the App Store copy: Xcode is absent and `libimobiledevice` cannot enumerate a paired device.
- Runner is the only configured Xcode target; WidgetKit/watch source directories are not active extensions and no App Group entitlement exists. The App Store installation must not be overwritten while choosing a signing/distribution strategy.

## Data/API

- The live Open-Meteo query shape returns current, hourly, and daily data successfully.
- Open-Meteo returns local wall-clock timestamps with `timezone=auto`. Hourly
  selection now uses response `current.time`; atmosphere timing still deserves
  real-device validation across searched timezones.
- The pre-Flagship UI does not implement a user unit-switch preference; do not claim °F/°C setting coverage until such a feature is deliberately introduced.

## Fixed

| ID | Severity | Area | Fix | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| WOS-000 | P1 | UI rollback | Preserved Flagship work on `backup/flagship-dashboard-20260908` (`560ad25`) and restored exact pre-Flagship `5de1cb8` UI without reset/discard. | Git ancestry and source wiring checked. | Fixed |
| WOS-007 | P1 | Daily precipitation | Removed second inch conversion from headline and daily-row precipitation. | Focused Open-Meteo suite passes. | Fixed |
| WOS-008 | P1 | Visibility | Request visibility in metres and convert once to miles at parser boundary. | Focused Open-Meteo suite passes. | Fixed |
| WOS-009 | P1 | Malformed API data | Reject incomplete Open-Meteo payloads instead of synthesizing weather from defaults. | Parser/provider tests pass. | Fixed |
| WOS-002 | P1 | Cache/data freshness | Apply the existing 15-minute TTL before cold-start cache hydration. | Fresh and expired offline-cache provider tests pass. | Fixed |
| WOS-010 | P1 | Hourly timezone | Anchor hourly selection to Open-Meteo `current.time`, not host-local time. | Cross-timezone regression test passes. | Fixed |
