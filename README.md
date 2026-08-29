# WeatherOS

**Owner:** OnlyTruePerspective LLC  
**Product:** WeatherOS  
**Application ID:** `app.weatheros.app`  
**Purpose:** Premium cross-platform weather application.

WeatherOS is a cinematic Flutter weather experience for iOS and Android. It features a responsive observatory layout, animated rain and storm environments, an hourly forecast lens, live GPS location resolution, live Open-Meteo weather transport with caching, and compact weather metrics.

## Architecture

The app separates transport, domain access, state, and presentation:

```text
LocationService + WeatherService -> WeatherRepository -> WeatherProvider -> WeatherHomeScreen
```

- **Live Provider:** `OpenMeteoWeatherService` supplies real-time global forecast data.
- **Location:** `GeolocatorLocationService` resolves GPS coordinates with reverse geocoding.
- **Offline / Mock:** `MockWeatherService` and `MockLocationService` remain available for tests and visual showcase.
- **Showcase Route:** Primitive design route remains available at `/showcase` for visual regression work.

## Run and Verify

```sh
flutter run
flutter analyze
flutter test
flutter build appbundle --release
```

## Store & Platform Availability

### DOWNLOAD NOW
* **Google Play Store (Android):** **AVAILABLE NOW**
  Package ID: `app.weatheros.app`
  [Get it on Google Play](https://play.google.com/store/apps/details?id=app.weatheros.app)

### COMING SOON
* **Apple App Store (iOS & watchOS):** **IN APP STORE REVIEW / COMING SOON**
  *Native SwiftUI Liquid Glass chrome, Apple Watch companion app, and WidgetKit complications.*

### TRY ONLINE
* **Web:** [WeatherOS Online Preview](https://www.onlytrueperspective.tech/weatheros)

## Release Preparation & Production Ownership

- **Organization:** OnlyTruePerspective LLC
- **Bundle / Application ID:** `app.weatheros.app`
- **Official Privacy Policy:** `https://www.onlytrueperspective.tech/weatheros/privacy`
- **Release Signing:** Keystore configuration managed via `android/key.properties` (see `android/key.properties.example`).
- **Android Target:** Android App Bundle (`.aab`) production release for Google Play.
- **iOS Target:** Archive & IPA build via `scripts/build_appstore_ipa.sh`.


