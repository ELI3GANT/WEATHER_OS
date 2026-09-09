# WeatherOS Audit

_Last updated: 2026-09-08. This is a living audit; device conclusions are only marked verified when tested on the LG G7._

## Stack and startup

- Flutter/Dart (`sdk: ^3.13.1`), pinned with FVM to Flutter 3.47.2 / Dart 3.13.2.
- Material 3 Android app with platform-adaptive native iOS chrome, iOS watch and widget targets.
- Android application ID: `app.weatheros.app`; iOS bundle ID: `tech.onlytrueperspective.weatheros`.
- Startup: `lib/main.dart` → `WeatherOSApp` in `lib/app/weather_os_app.dart` → `WeatherHomeScreen` in `lib/features/weather/screens/weather_home_screen.dart`.

## Architecture

- `lib/app/`: application root, theme, routes.
- `lib/core/platform_ui/`: platform bridge, navigation, header, sheets, and system UI contracts.
- `lib/features/weather/models/`: weather, hourly, daily, condition, and atmosphere models.
- `lib/features/weather/providers/weather_provider.dart`: `ChangeNotifier` state, refresh lifecycle, cache hydration, location selection.
- `lib/features/weather/services/`: Open-Meteo client, repository, Geolocator location service, city search, RainViewer radar, preferences, cache, purchase entitlement, watch/widget export.
- `lib/features/weather/widgets/`: dashboard sections and tab UI.

## Navigation and data flow

`WeatherHomeScreen` owns the selected tab and forecast hour. It reads `WeatherProvider` via `WeatherScope`; the provider resolves location, calls `WeatherRepository`/`OpenMeteoWeatherService`, persists cache, and exports widget/watch telemetry. Main tabs are Today, Hourly, Daily, Radar (preference-controlled), and Alerts.

## Providers and storage

- Weather: Open-Meteo JSON HTTP API via `http`.
- Radar: RainViewer tiles.
- Location: `geolocator`, with location search for manual cities.
- Storage: `shared_preferences` cache/preferences.
- No application API key was found in the checked source/configuration.

## Current UI decision and backup

- History confirms `560ad25` is the first Flagship/HUD commit: it introduces
  `WeatherFlagshipDashboard`, `assets/weather_hud/`, and wires that component
  into Today. Its direct parent is `5de1cb8`.
- Therefore the preferred active UI is the committed weather-first dashboard
  at `5de1cb8`, the exact last pre-Flagship UI. `5de1cb8` itself has no UI
  changes; its Today composition is the same as `e356066`.
- The uncommitted Flagship redesign was preserved intact in local branch `backup/flagship-dashboard-20260908`, commit `560ad25`.
- The active worktree is now clean `main`; this was a branch/commit backup and checkout, not a reset or discarded change.
- Flagship-specific `weather_flagship_dashboard.dart`, HUD assets, golden updates, and related tests remain only in the backup branch.
- The confirmed pre-Flagship Today flow is: `CurrentConditionsHero` →
  `HourlyForecastRail` → `WeatherWeeklyOutlookCard` → metrics, risk, charts,
  celestial, and impact cards, with the existing platform navigation and
  location/search/radar entry points retained.

## Android configuration and status

- Android uses AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, compile/target SDK supplied by Flutter, and Java 17 source/target compatibility.
- Connected hardware: LG G7 (`LMG710ULM143754a3`), Android 9, 1440×3120 at 560 dpi; location permissions are granted and device location is enabled.
- Installed app: WeatherOS 1.0.6 (version code 20), updated 2026-09-06. It launches without a detected WeatherOS crash, but this installed build predates this audit's restored source verification and is Flagship-era UI.
- ARM64 Arch Linux build compatibility is now established without project changes: an official Arch x86_64 sysroot lives at `~/.local/x86_64-root`; `~/.local/bin/aapt2` runs AGP's x86_64 AAPT2 through `qemu-x86_64 -L`; and the user-level Gradle override is backed up before use. JDK 17 is required; Java 26 remains incompatible with this AGP workflow.
- `aapt2 version` succeeds through QEMU and both universal and arm64-only debug APKs build from `fbf06ef`. The arm64 APK is `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` (642 MB, SHA-256 `f7c3162a7028858416655adf73cdb44b38b5f28a421711f815aad5965bb47b16`).
- Installation is blocked only by the LG G7's 968 MB free internal storage (`Requested internal only, but not enough space`). No existing app was uninstalled or overwritten. Resume Android device testing after freeing approximately 2 GB, then use `adb install -r`; uninstall only if Android returns `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.

## iOS configuration and static audit

- The project is one `Runner` application target, automatically signed by the configured Apple team, with bundle ID `tech.onlytrueperspective.weatheros`, iOS 15.0 minimum deployment, and Flutter-provided marketing/build values.
- `Info.plist` provides when-in-use and legacy always-location usage strings. There are no background modes, ATS exceptions, push-notification entitlements, App Group entitlements, or project-configured widget/watch extension targets. HTTPS networking therefore uses standard ATS behavior; background location is not enabled.
- `WeatherOSNativeUI` is compiled into Runner and owns the SwiftUI overlay, Flutter method channels, native sheets, radar controls, and haptics. It is not the Dart Today dashboard and has not been redesigned in this phase.
- `ios/WeatherOSWidgets/` and `ios/WeatherOSWatch/` contain prototype WidgetKit/WatchConnectivity source, but neither is referenced by a native Xcode target. Their declared App Group is consequently unavailable to the active Runner target. No capability was enabled during this audit.
- Xcode Cloud is configured for the Runner target only. Its post-clone script now obtains the repository-pinned Flutter 3.47.2 rather than a moving `stable` branch.
- This ARM64 Linux host has no Xcode or `xcrun`; `libimobiledevice` cannot enumerate a paired iPhone (`Unable to retrieve device list`). It cannot build, inspect the installed app version, or run iPhone device tests. No action was taken on the App Store installation.

### TestFlight beta pipeline

- `ce2b60a` adds a release-mode **Beta** build configuration and shared **WeatherOS Beta** Xcode scheme. Its bundle ID is `tech.onlytrueperspective.weatheros.beta` and its home-screen display name is `WeatherOS Beta`; production Debug/Profile/Release configurations retain `tech.onlytrueperspective.weatheros` and `WeatherOS`.
- The Beta configuration is a second configuration of the existing Runner target, not a duplicate target. It uses the same Flutter source, assets, pre-Flagship UI, iOS 15 deployment target, and automatic signing team. It does not enable App Groups, widgets, watchOS, push, or background capabilities.
- Both repository-root and legacy `ios/` Xcode Cloud post-clone scripts pin Flutter 3.47.2. A beta workflow can set `WEATHEROS_BETA_BUILD=1`; the script then feeds Xcode Cloud's monotonically increasing `CI_BUILD_NUMBER` to Flutter so TestFlight builds do not reuse a build number. `pubspec.yaml` remains at the production baseline (`1.0.6+20`); only the Beta cloud archive receives the incremented build number.
- Apple Developer now has explicit Beta App ID `tech.onlytrueperspective.weatheros.beta` (`WeatherOS Beta`) under team `3MVY7ZJ9NN`. It was registered with no optional App Services enabled; the production WeatherOS identifier was verified unchanged.
- App Store Connect now has the separate **WeatherOS Beta** iOS app record (Apple app ID `6810007458`, SKU `weatheros-beta`, initial status **Prepare for Submission**). No build has been uploaded, no public App Store submission was made, and no credentials, provisioning profiles, certificates, or API keys are stored here.
- The dedicated `beta` branch is pushed at `aef8d07` (`fix(weather): scope cache and honor visibility units`) and is the intended Xcode Cloud start condition. The current App Store Connect Xcode Cloud page has no workflow and explicitly requires initial setup in Xcode; therefore no archive, upload, or TestFlight build can be truthfully claimed from this Linux host.

#### Apple-side first-build checklist

1. On macOS, check out `fd214ca`, run `fvm install 3.47.2 && fvm flutter pub get`, run `cd ios && pod install`, then open `ios/Runner.xcworkspace` in Xcode. Do not run the production Runner scheme on the phone.
2. Select the shared **WeatherOS Beta** scheme and verify automatic signing resolves to team `3MVY7ZJ9NN` and bundle ID `tech.onlytrueperspective.weatheros.beta`.
3. In Xcode, start Xcode Cloud setup for that scheme. The App Store Connect Beta Xcode Cloud page confirms that this initial setup requires Xcode. Create an Archive workflow, restrict its start condition to the intended beta branch, set Deployment Preparation to **TestFlight (Internal Testing Only)**, and add `WEATHEROS_BETA_BUILD=1` to its environment.
4. Run the first build, inspect archive signing and bundle metadata in its logs, then wait for App Store Connect processing. Add the intended internal tester and install **WeatherOS Beta** beside—not over—the production App Store app.
5. Before every subsequent QA cycle, record the Git revision, TestFlight version/build, device model, iOS version, and test results in `BUGS.md` / this audit.

## Build and test commands

```bash
JAVA_HOME=/usr/lib/jvm/java-17-openjdk PATH=/usr/lib/jvm/java-17-openjdk/bin:$PATH ./.fvm/flutter_sdk/bin/flutter analyze
JAVA_HOME=/usr/lib/jvm/java-17-openjdk PATH=/usr/lib/jvm/java-17-openjdk/bin:$PATH ./.fvm/flutter_sdk/bin/flutter test
JAVA_HOME=/usr/lib/jvm/java-17-openjdk PATH=/usr/lib/jvm/java-17-openjdk/bin:$PATH ./.fvm/flutter_sdk/bin/flutter build apk --debug --split-per-abi --target-platform android-arm64
adb devices -l
```

### Compatible MacBook build route

Use a normal macOS Flutter/Android SDK installation rather than changing this
repository to accommodate the ARM64 Linux host. From the real WeatherOS clone:

```bash
cd ~/OTP/01_PRODUCTS/weather-os
git status --short
git rev-parse --verify HEAD
fvm install 3.47.2
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter devices
fvm flutter build apk --debug
adb devices -l
adb -s <LG_G7_SERIAL> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <LG_G7_SERIAL> shell am force-stop app.weatheros.app
adb -s <LG_G7_SERIAL> shell am start -n app.weatheros.app/.MainActivity
adb -s <LG_G7_SERIAL> shell dumpsys package app.weatheros.app | grep -E 'versionName|versionCode|lastUpdateTime'
adb -s <LG_G7_SERIAL> logcat -v brief
```

Record the checked-out Git revision and the installed version/code before
testing; do not treat the existing Flagship-era device installation as proof of
the restored source.

## Verified findings

- `flutter analyze` passes on `main`.
- Fixed and verified: Open-Meteo precipitation is requested in inches and is
  now retained as inches instead of being converted a second time. The focused
  Open-Meteo/provider test file passes (6 tests).
- Live Open-Meteo requests using the app's production query shape returned
  valid current, hourly, and daily payloads. The September 8 Boston sample
  returned Fahrenheit temperatures, mph wind, inch precipitation, hPa pressure,
  America/New_York timestamps, and `visibility=65944.884 ft`.
- The parser now reads Open-Meteo `current_units.visibility`: that Boston value
  correctly becomes 12.49 mi rather than 40.98 mi. Regression coverage handles
  both feet and metres.
- The restored app has passed all 56 current non-golden tests covering startup,
  current conditions, location switching and dialog entry, provider refresh,
  accessibility layout, UI polish, cache behavior, and Open-Meteo parsing.
- Cache cold starts now honor the existing 15-minute TTL: a fresh cached
  forecast supports offline startup, while an expired cache enters the existing
  unavailable/error state. Focused parser/provider coverage is now 12 tests.
- The cache now stores a rounded coordinate identity with its payload. An
  offline cold start only shows it when the resolved location matches, preventing
  a previous searched city from masquerading as the current city. Legacy cache
  entries without an identity are safely ignored.
- Parser integrity is strict at the live-data boundary: every requested
  current/daily/hourly field must exist, timestamps and array lengths must be
  coherent, and malformed input reaches the existing error state instead of
  fabricated weather. Cache hydration similarly rejects corrupt nested forecast
  entries.
- Hourly selection now uses Open-Meteo's location-local `current.time`, rather
  than the host clock, so a searched city in another timezone does not skip
  upcoming hourly rows.
- Weather models retain Open-Meteo's `utc_offset_seconds` and raw WMO code.
  The header and atmosphere use location-local time for searched cities; WMO 2
  keeps a partly-cloudy scene while WMO 3 uses overcast. Live Tokyo verification
  returned `Asia/Tokyo`, UTC+09:00, and aligned 168-hour/7-day response arrays.
- Atmosphere updates crossfade the prior visual state, including overcast/heavy
  precipitation changes. Selecting an hourly forecast derives a background from
  that selected condition rather than reusing the current-condition state.
- The full test suite has reproducible golden failures: the showcase golden cases have large pixel diffs (roughly 95–99%) and `home_large_text_lower` has a 0.10% / 320-pixel diff. These were not updated or masked.
- Source-built primary-screen visual inspection on the LG G7 remains pending
  the Android AAPT2 host-environment fix. The currently installed app is not
  used as verification because it is Flagship-era.
- Dependencies report five newer versions outside current constraints; no upgrade has been performed.

## Technical debt and priorities

1. Free LG G7 internal storage, install the already built arm64 restored-source APK, and exercise it before claiming Android runtime fixes.
2. Make golden rendering deterministic or re-baseline only after visual review.
3. Decide whether WidgetKit/watchOS are product requirements. If so, create and sign real extension targets, entitlements, App Group provisioning, and focused tests as a deliberate capability project—not as an incidental fix.
4. Use macOS/Xcode to build the exact restored revision and test iPhone lifecycle, permission, cache, layout, and live data without replacing the App Store installation prematurely.
5. Complete the explicit Apple-side beta identifier/app/workflow setup, then use TestFlight as the recurrent iPhone QA channel.
6. Run the source-built beta on iPhone and LG G7 to inspect the corrected
   location-local header/atmosphere transitions, motion cost, and text contrast;
   static/widget tests cannot replace hardware evidence.

## Subsystem map: input → transformation → state → UI

- **Startup:** `main.dart` builds `WeatherOSApp`, initializes preferences,
  wires `WeatherProvider`, then presents `WeatherHomeScreen`.
- **Location:** Geolocator checks service/permission, obtains a position, and
  reverse-geocodes it; `WeatherProvider.load` accepts the coordinates/name.
- **Search:** `LocationSearchService` calls Open-Meteo geocoding, validates the
  first result, then passes it to `WeatherProvider.setLocation`.
- **Open-Meteo:** the service requests imperial weather fields; the model
  validates queried arrays and normalizes response-labelled metric or imperial
  temperature, wind, precipitation, pressure, and visibility once.
- **Cache:** SharedPreferences stores one payload with a timestamp and rounded
  coordinate identity; it is used for up to 15 minutes only when it matches the
  resolved request.
- **State:** `WeatherProvider` owns generation-safe loads, error/offline state,
  coordinates, cache hydration, and optional widget/watch export.
- **Today/hourly/weekly:** `WeatherHomeScreen` composes the pre-Flagship hero,
  hourly rail, weekly card, and detail cards from the provider model.
- **Radar/preferences:** RainViewer is exposed through the Radar tab; a
  SharedPreferences preference controls its visibility.
