# Final Visual QA Gate Review

recommendation: REJECT

## Original intent

Perform a fresh, independent, read-only final visual QA after the motion harness isolation fix. PASS only if every current WeatherOS golden is valid, with special emphasis on full foreground composition in both original-resolution Home motion frames, deterministic clock/hour inputs, Android `12 PM`, usable large-text/lower-scroll states, and a fixture-coherent Showcase storm.

## Desired outcome

All 16 PNGs under `test/visual/goldens` are valid and visually composed. `home_motion_start.png` and `home_motion_mid.png` must preserve the complete foreground hierarchy while only the atmospheric background changes. The generating suites must reproduce those artifacts from fixed inputs without accepting a visibly broken baseline.

## User outcome review

The final packet does not meet the requested outcome. `home_motion_start.png` is now fully composed, but `home_motion_mid.png` has widespread left-edge foreground loss at original resolution. The header loses the location, the hero loses the left side of the temperature and condition lines, the day-summary and hourly headings lose leading text, several forecast rows lose their left content, and the Today navigation item loses its icon/label. The two motion frames therefore do not both show full foreground.

The other 14 PNGs were inspected in a full contact sheet, with targeted original-resolution inspection of the storm frame. They are visually valid for their named states. Compact Android visibly includes `12 PM`; Home and Showcase large-text top/lower pairs are legible scroll continuations; `showcase_storm.png` shows a 65-degree Storm hero, storm glyphs across the visible hourly rail, 85-100% precipitation, and storm-specific metrics.

## Blockers

1. violatedCriterion: `motion-mid-full-foreground`
   - observation: `home_motion_mid.png` visibly clips foreground content down the left side across every major Home section.
   - evidencePointer: `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_mid.png` (SHA-256 `fdfea218bc9a284b7c006223096c564ab4b04cb5763c7d80660fba3d6ee6bd8a`), contrasted with complete `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_start.png` (SHA-256 `1d4544b30fd71955754ca400b9818405f9c4cec3d86eee542e00ab778562b39c`).

2. violatedCriterion: `every-current-golden-valid`
   - observation: The isolated mid-motion suite passes while reproducing the visibly invalid baseline; green pixel matching does not establish foreground validity.
   - evidencePointer: `/Users/eli/OTP/weather_os/test/visual/home_motion_golden_test.dart:43` and `:89`; reproduced command `flutter test test/visual/home_motion_golden_test.dart` reports 1/1 passed against the invalid PNG.

## Determinism and fixture checks

- Fixed Home wall clock: PASS. Both harnesses inject `DateTime(2026, 8, 29, 12)`.
- Fixed atmosphere phase: PASS. Start uses `0.0`; isolated mid uses `0.1`.
- Fixed Showcase hour: PASS. `_pumpShowcase` supplies `atmosphereHour: 12`.
- Android noon: PASS. `home_compact_android.png` visibly includes `12 PM`; the test also asserts its right edge remains within the hourly rail.
- Large text and lower views: PASS by direct inspection and reproduced golden matches.
- Storm fixture coherence: PASS. `MockWeather.newYorkStorm` is distinct; the first six hourly entries and first daily entry are storm, and the test asserts those facts before rendering.

## Direct remove-ai-slops and programming pass

- The isolated mid-motion test has a legitimate isolation seam and fixed inputs; it is not deletion-only or a requested-removal test.
- Blocking overfit/false confidence remains: the test asserts only equality to an accepted image, so it canonizes the compositor defect and cannot detect the stated full-foreground failure.
- No excessive parsing, normalization, speculative production abstraction, implementation-mirroring unit test, or unnecessary deletion test was found in the reviewed motion/fixture changes.
- The current evidence directory has prior gate reports with explicit slop/programming coverage, but those reports predate this newly swapped motion-frame failure and are contradictory. No current executor report, code-review report, manual-QA matrix, or notepad path was supplied; this direct pass provides the criterion-grounded evidence needed for rejection.

## Checked artifacts

- `/Users/eli/OTP/weather_os/test/visual/goldens/*.png` (all 16 files; dimensions/signatures checked and all inspected via contact sheet)
- `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_start.png` (original resolution)
- `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_mid.png` (original resolution)
- `/Users/eli/OTP/weather_os/test/visual/goldens/showcase_storm.png` (original resolution)
- `/Users/eli/OTP/weather_os/test/visual/home_golden_test.dart`
- `/Users/eli/OTP/weather_os/test/visual/home_motion_golden_test.dart`
- `/Users/eli/OTP/weather_os/test/visual/showcase_golden_test.dart`
- `/Users/eli/OTP/weather_os/lib/features/weather/models/mock_weather.dart`
- `/Users/eli/OTP/weather_os/lib/features/weather/screens/weather_home_screen.dart`
- `/Users/eli/OTP/weather_os/lib/features/weather/widgets/weather_atmosphere.dart`
- `/Users/eli/OTP/weather_os/.omo/evidence/*review.md`

## Reproduced evidence

- `flutter test test/visual/home_golden_test.dart`: PASS, 8/8.
- `flutter test test/visual/home_motion_golden_test.dart`: PASS, 1/1, but against a visibly invalid baseline.
- `flutter test test/visual/showcase_golden_test.dart`: PASS, 7/7.
- `file test/visual/goldens/*.png`: all 16 are valid non-interlaced 8-bit RGBA PNGs at their declared dimensions.

## Exact evidence gaps

- Missing: a freshly generated `home_motion_mid.png` with every foreground element fully composed.
- Missing: an independent foreground-integrity/stable-geometry assertion or comparison that fails when the mid frame loses foreground while the baseline is updated.
- Not blocking independently: no current executor report, code-review report, manual-QA matrix, or notepad path was supplied; direct artifact inspection already proves the stated visual criterion fails.

