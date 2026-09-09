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
- Local source build is blocked on this ARM64 Linux host: JDK 17 fixes the JDK 26 incompatibility, but AGP's x86_64-only AAPT2 cannot run because no x86_64 runtime loader is available. No source APK has been installed from the restored `main` branch.

## Build and test commands

```bash
JAVA_HOME=/usr/lib/jvm/java-17-openjdk PATH=/usr/lib/jvm/java-17-openjdk/bin:$PATH ./.fvm/flutter_sdk/bin/flutter analyze
JAVA_HOME=/usr/lib/jvm/java-17-openjdk PATH=/usr/lib/jvm/java-17-openjdk/bin:$PATH ./.fvm/flutter_sdk/bin/flutter test
JAVA_HOME=/usr/lib/jvm/java-17-openjdk PATH=/usr/lib/jvm/java-17-openjdk/bin:$PATH ./.fvm/flutter_sdk/bin/flutter build apk --debug
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
- A live Open-Meteo request using the app's production query shape returned
  valid current, hourly, and daily payloads, including an inch-valued daily
  precipitation sum.
- The restored app has passed 30 focused non-golden tests covering startup,
  current conditions, location switching and dialog entry, provider refresh,
  accessibility layout, UI polish, and Open-Meteo parsing.
- Cache cold starts now honor the existing 15-minute TTL: a fresh cached
  forecast supports offline startup, while an expired cache enters the existing
  unavailable/error state. Focused parser/provider coverage is now 12 tests.
- Hourly selection now uses Open-Meteo's location-local `current.time`, rather
  than the host clock, so a searched city in another timezone does not skip
  upcoming hourly rows.
- The full test suite has reproducible golden failures: the showcase golden cases have large pixel diffs (roughly 95–99%) and `home_large_text_lower` has a 0.10% / 320-pixel diff. These were not updated or masked.
- Source-built primary-screen visual inspection on the LG G7 remains pending
  the Android AAPT2 host-environment fix. The currently installed app is not
  used as verification because it is Flagship-era.
- Dependencies report five newer versions outside current constraints; no upgrade has been performed.

## Technical debt and priorities

1. Establish an ARM64-capable Android AAPT2/build environment, then build and exercise the restored `main` APK on the LG G7.
2. Make golden rendering deterministic or re-baseline only after visual review.
3. Review backup-branch data/cache changes as small independently tested patches; do not reintroduce the Flagship UI.
4. Add focused real-device checks for location, refresh/offline, search, navigation/back, keyboard, and system bars once a source APK can be built.

## Subsystem map: input → transformation → state → UI

- **Startup:** `main.dart` builds `WeatherOSApp`, initializes preferences,
  wires `WeatherProvider`, then presents `WeatherHomeScreen`.
- **Location:** Geolocator checks service/permission, obtains a position, and
  reverse-geocodes it; `WeatherProvider.load` accepts the coordinates/name.
- **Search:** `LocationSearchService` calls Open-Meteo geocoding, validates the
  first result, then passes it to `WeatherProvider.setLocation`.
- **Open-Meteo:** the service requests imperial weather fields; the model
  converts pressure and visibility once and retains inch precipitation.
- **Cache:** one weather payload/timestamp is stored in SharedPreferences;
  freshness/location identity are missing (WOS-002/WOS-003).
- **State:** `WeatherProvider` owns generation-safe loads, error/offline state,
  coordinates, cache hydration, and optional widget/watch export.
- **Today/hourly/weekly:** `WeatherHomeScreen` composes the pre-Flagship hero,
  hourly rail, weekly card, and detail cards from the provider model.
- **Radar/preferences:** RainViewer is exposed through the Radar tab; a
  SharedPreferences preference controls its visibility.
