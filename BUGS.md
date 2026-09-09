# WeatherOS Bugs

_Last updated: 2026-09-09. Only reproduced or source-proven issues are listed. A passing compile is never treated as device verification._

| ID | Severity | Area | Reproduction | Root Cause | Fix | Verification | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| WOS-001 | P2 | Android device install | Install the arm64 restored-source debug APK on LG G7. | LG G7 has only 968 MB free; Android cannot allocate the required internal install session for the 642 MB APK. | Free approximately 2 GB; retry `adb install -r`. Do not uninstall unless Android returns `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. | APK built and install failure captured. | Blocked — device storage |
| WOS-004 | P3 | Visual regression tests | Run compact showcase golden. | Expected palette predates later atmosphere-engine changes; card/text/icon geometry aligns but background differs by 98.51%. | Keep baseline unchanged pending visual review. | Diagnostic images compared. | Open — review |
| WOS-005 | P3 | Visual regression tests | Run all visual goldens. | Showcase baseline drift; home large-text has a 320-pixel delta. | Isolate each; never update images only to suppress tests. | Eight baseline failures. | Open |
| WOS-006 | P4 | Tooling | Run Android build. | SDK command-line tools warn on metadata XML v4. | Align tooling only if it affects compatible build host. | Warning observed; not blocker. | Open |
| WOS-011 | P2 | iOS widget/watch telemetry | Export telemetry on an iOS build without an entitled App Group. | Runner has no App Group entitlement; widget/watch sources are not Xcode extension targets, while the bridge previously treated a nil shared defaults suite as success. | Return an explicit platform-channel error; defer extension/capability work until deliberately scoped. | Static target/entitlement trace; Xcode device build pending. | Fixed — static verification |
| WOS-012 | P2 | watchOS prototype compile | Compile `WeatherOSWatch/WatchSessionReceiver.swift` after it becomes a real target. | Swift uses lowercase `int`, which is not the Swift integer type. | Use `Int`. | Static source verification; no watchOS target/Xcode host available. | Fixed — static verification |
| WOS-013 | P2 | Xcode Cloud reproducibility | Run the configured post-clone build at a later date. | Script cloned moving Flutter `stable`, diverging from FVM 3.47.2. | Pin both post-clone scripts to 3.47.2. | Both scripts pass `bash -n`; cloud build not triggered from Linux. | Fixed — static verification |
| WOS-014 | P2 | iOS TestFlight beta pipeline | Start the first `WeatherOS Beta` cloud archive. | Initial Xcode Cloud setup is not available in App Store Connect; it requires macOS Xcode. | Beta App ID and separate App Store Connect record are created; configure the shared Beta scheme's Archive/Internal TestFlight workflow in Xcode. | Apple portal IDs and no-capability state verified; XML, shell, project-reference, and Dart analysis checks pass. | Blocked — macOS Xcode initial workflow |

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
| WOS-008 | P1 | Visibility | Read Open-Meteo `current_units.visibility` and convert feet or metres once to miles at the parser boundary. | Live Boston and Tokyo responses plus unit regressions pass. | Fixed |
| WOS-009 | P1 | Malformed API data | Reject incomplete, invalid, and mismatched Open-Meteo current/hourly/daily payloads instead of synthesizing weather from defaults. | Parser/provider tests pass. | Fixed |
| WOS-002 | P1 | Cache/data freshness | Apply the existing 15-minute TTL before cold-start cache hydration. | Fresh and expired offline-cache provider tests pass. | Fixed |
| WOS-010 | P1 | Hourly timezone | Anchor hourly selection to Open-Meteo `current.time`, not host-local time. | Cross-timezone regression test passes. | Fixed |
| WOS-003 | P1 | Cache/location identity | Cache current and searched cities, then restart offline at either location. | A single global payload could overwrite another location and surface incorrect weather. | Store independent four-decimal coordinate-keyed payload/timestamp pairs; hydrate only the resolved location. | Multi-location, TTL, cross-city, malformed-cache, and full non-golden regressions pass; device verification pending. | Fixed — source verified |
| WOS-015 | P1 | Open-Meteo visibility units | Load WeatherOS's imperial Open-Meteo query and compare visibility to `current_units.visibility`. | The request returns feet, but the parser treated every result as metres, overstating visibility by 3.28×. | Convert feet or metres according to response metadata, with metres as the backward-compatible fallback. | Live Boston response: 65,944.884 ft → 12.49 mi; feet/metres regression test and full non-golden suite pass. | Fixed — source/live verified |
| WOS-016 | P1 | Weather data integrity | Provide missing, malformed, or mismatched current/hourly/daily fields; open corrupt cached forecast data. | Parser and cache deserializers previously substituted plausible weather, dates, forecast rows, or host-time fallback. | Require all queried fields/finite values/valid timestamps and array lengths, validate cached forecast structure, and surface the existing unavailable state. | Metric/imperial, missing-visibility, malformed-timestamp/payload, mismatched-array, malformed-cache, and full non-golden regressions pass. | Fixed — source verified |
| WOS-017 | P2 | Timezone/atmosphere presentation | Search a city outside the host timezone or update partly-cloudy/overcast conditions. | Header/atmosphere used host time; WMO cloud codes 1/2/3 collapsed to a generic overcast visual; transitions could paint prior condition with new-state parameters. | Persist Open-Meteo UTC offset and raw WMO code, use location-local time, distinguish partly cloudy from overcast, and crossfade preserved prior state. | Live Tokyo UTC+09 metadata verified; deterministic parser/atmosphere regressions and full non-golden suite pass. Device visual QA pending. | Fixed — source/live verified |
| WOS-018 | P2 | Radar availability and labeling | Open Radar with invalid map coordinates or while RainViewer returns malformed/unavailable metadata. | The map request accepted invalid Web-Mercator coordinates, the UI could present an indefinite acquisition label after failure, and a static latest frame was described as a live sweep. | Reject invalid coordinates before requesting tiles; distinguish loading from an unavailable result with retry; label the static frame accurately. | RainViewer parser regressions pass; live public metadata endpoint returned a valid host; full 61-test non-golden suite and analysis pass. Device visual/network QA pending. | Fixed — source/live verified |
| WOS-019 | P1 | Today hourly-selection data | Select a future hour on Today and inspect the hero context and local-time presentation. | The selected-hour helper rebuilt a partial `WeatherModel`, which restored constructor defaults and labeled its forecast temperature as a measured “Feels like” value. It also lost the selected location’s UTC offset. | Preserve genuine shared fields and location offset; explicitly label the hero as an hourly forecast because the API payload does not request hourly apparent temperature. | Full 63-test non-golden suite and analysis pass; device verification pending. | Fixed — source verified |
| WOS-020 | P1 | Today unavailable-data wording | Start without usable cache while Open-Meteo fails or returns malformed data. | The error UI said “The atmosphere is quiet,” which could be mistaken for a genuine calm-weather report despite no validated payload. | Use an explicit unavailable-data message and plain retry label. | Full 63-test non-golden suite and analysis pass; device verification pending. | Fixed — source verified |
| WOS-021 | P3 | Today accessibility/motion | Enable the operating system reduce-motion setting, then load or refresh Today. | The hero’s glyph and text switchers used fixed animation durations even when motion reduction was requested. | Respect `MediaQuery.disableAnimationsOf(context)` for all hero transitions. | Full 64-test non-golden suite and analysis pass; device verification pending. | Fixed — source verified |
| WOS-022 | P1 | Today celestial timezone | Search a location outside the device timezone and inspect the Sun & Daylight indicator. | Solar progress used `DateTime.now()` from the host/device, so its indicator could show night or dawn while the forecast location was in daylight. | Convert the current UTC instant through the forecast location’s Open-Meteo offset before calculating solar progress. | Full 65-test non-golden suite and analysis pass; device verification pending. | Fixed — source verified |
