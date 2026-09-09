# WeatherOS Bugs

_Last updated: 2026-09-08. Only reproduced or source-proven issues are listed. A passing compile is never treated as device verification._

| ID | Severity | Area | Reproduction | Root Cause | Fix | Verification | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| WOS-001 | P2 | Android build host | Build debug APK on this ARM64 Linux host with JDK 17. | AGP supplies x86_64 AAPT2; the host lacks its x86_64 runtime loader. Java 26 also fails JDK-image transformation. | Use a native compatible Mac/x86_64 build host; do not change project files for this host limitation. | Reproduced twice. | Open — environment |
| WOS-003 | P1 | Cache/location identity | Search another city, close app, then start without current location. | One global payload/key has no coordinate or location identity. | Add scoped cache identity after focused behavioral tests. | Source trace complete; device test pending source build. | Open |
| WOS-004 | P3 | Visual regression tests | Run compact showcase golden. | Expected palette predates later atmosphere-engine changes; card/text/icon geometry aligns but background differs by 98.51%. | Keep baseline unchanged pending visual review. | Diagnostic images compared. | Open — review |
| WOS-005 | P3 | Visual regression tests | Run all visual goldens. | Showcase baseline drift; home large-text has a 320-pixel delta. | Isolate each; never update images only to suppress tests. | Eight baseline failures. | Open |
| WOS-006 | P4 | Tooling | Run Android build. | SDK command-line tools warn on metadata XML v4. | Align tooling only if it affects compatible build host. | Warning observed; not blocker. | Open |

## Android

- LG G7 (`LMG710ULM143754a3`) is connected, location is enabled, and the existing 1.0.6 installation has fine/coarse location permission.
- The installed APK is Flagship-era and is not valid verification for restored `main`.

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
