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

## Release Preparation & Production Ownership

- **Organization:** OnlyTruePerspective LLC
- **Bundle / Application ID:** `app.weatheros.app`
- **Official Privacy Policy:** `https://www.onlytrueperspective.tech/weatheros/privacy`
- **Release Signing:** Keystore configuration managed via `android/key.properties` (see `android/key.properties.example`).
- **Android Target:** Android App Bundle (`.aab`) ready for Google Play Console Internal Testing.


