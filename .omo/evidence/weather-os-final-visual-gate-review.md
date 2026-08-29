# WeatherOS Final Visual Gate Review

recommendation: REJECT

## Original intent

Independently verify the current WeatherOS final golden packet, without edits, and return PASS only if all 16 PNG captures are visually valid, deterministic, and fixture-coherent. In particular, both Home motion frames must be fully composed with only the atmosphere changing; the clock/date must be pinned; Android must visibly include `12 PM`; large-text and lower-scroll frames must remain usable; and the Showcase storm hero, hourly forecast, and daily forecast fixture must agree.

## Desired outcome

A current, reproducible 16-image packet in which every frame is fully composited and legible, the two Home motion captures preserve identical foreground layout/content while varying only procedural atmosphere, and the storm capture is backed by coherent storm data.

## User outcome review

The packet is not approvable. Fifteen captures are visually composed and the responsive, large-text, lower-scroll, Android-noon, and storm-fixture checks are satisfactory. `home_motion_start.png`, however, contains extensive foreground-content loss: the location/date, hero labels, day-summary heading/text, hourly heading/threat labels, daily heading/rows, and bottom navigation are clipped or partially missing. `home_motion_mid.png` is fully composed. Therefore the two frames do not differ only in atmosphere and the start frame is not a valid final capture.

The focused golden suite reproduced all 16 stored images (`flutter test test/visual/home_golden_test.dart test/visual/showcase_golden_test.dart`: 16 tests, all passed). That establishes stable reproduction of the stored baselines, but it does not validate a baseline whose pixels visibly encode a compositor/content-loss defect. The start PNG also predates the final edit to `test/visual/home_golden_test.dart` (01:10:33 versus 01:11:04), so it is stale under the visual-QA freshness rule.

## Blockers

1. violatedCriterion: `VQ-MOTION-FULL-COMPOSITION`
   - observation: The Home start-motion capture is not fully composed; foreground text and controls are visibly cut away across the frame.
   - evidencePointer: `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_start.png`; compare `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_mid.png`.

2. violatedCriterion: `VQ-MOTION-ATMOSPHERE-ONLY`
   - observation: Start-to-mid changes include widespread foreground loss/restoration, not only atmosphere motion. The objective diff is 51,098 pixels (15.52%, similarity 84/100), with high-difference hotspots in the header, hero, hourly, daily, and navigation regions.
   - evidencePointer: `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_start.png`; `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_mid.png`; motion scenarios at `/Users/eli/OTP/weather_os/test/visual/home_golden_test.dart:170`.

3. violatedCriterion: `VQ-CURRENT-FINAL-CAPTURES`
   - observation: `home_motion_start.png` was generated before the last modification of its test source, so it is not fresh evidence of the final source state.
   - evidencePointer: filesystem mtimes: `home_motion_start.png` 2026-08-29T01:10:33-0400; `/Users/eli/OTP/weather_os/test/visual/home_golden_test.dart` 2026-08-29T01:11:04-0400.

## Criteria that pass

- `VQ-ALL-16-ENUMERATED`: exactly 16 PNGs were enumerated and directly opened.
- `VQ-PNG-HYGIENE`: every file has a PNG signature, alpha channel, and expected dimensions.
- `VQ-DETERMINISTIC-REPRODUCTION`: the focused suite re-rendered and matched all 16 stored baselines with no exceptions. This is not sufficient to override the invalid start baseline.
- `VQ-CLOCK-PINNED`: Home test injects `DateTime(2026, 8, 29, 12)` at `test/visual/home_golden_test.dart:234`; composed Home captures show `Today - Aug 29` consistently.
- `VQ-ANDROID-12PM`: `home_compact_android.png` visibly shows `12 PM`, and the geometry assertion keeps it within the hourly rail.
- `VQ-LARGE-TEXT-LOWER`: Home and Showcase 1.8x upper/lower captures are legible, unclipped at content boundaries, and demonstrate reachable continuation.
- `VQ-SHOWCASE-STORM-COHERENCE`: `showcase_storm.png` shows a 65-degree Storm hero, 59-degree feels-like value, 68/57 range, storm glyphs for 6 AM through 12 PM, 85/95/100/100 precipitation, 98% humidity, 28 MPH wind, UV 0, and pressure 29.55. These match `MockWeather.newYorkStorm`; the first six hourly entries are storm and the first two daily entries are storm before the forecast transitions to rain/cloud/sun.

## Direct remove-ai-slops and programming pass

- The motion golden tests are deterministic and fixture-driven, but `matchesGoldenFile` can canonize a broken capture; the green suite therefore gives false confidence for the visibly corrupted start baseline.
- The storm assertions are criterion-bearing rather than deletion-only or tautological: they check the fixture conditions that drive the visible hero/hourly/daily narrative. They are somewhat narrow (daily only asserts the first item), but direct inspection of `MockWeather.newYorkStorm.dailyForecasts` confirms a coherent storm-to-clearing progression.
- No deletion-only tests, tests that merely verify a requested removal, prompt/prose pins, implementation-derived expected values, or unnecessary parsing/normalization were found in the scoped test/fixture files.
- The prior current Showcase gate report explicitly contains a `Direct remove-ai-slops and programming pass` and covers golden overfit risk (`.omo/evidence/primitive-quality-gate-5-gate-review.md:78-90`). The older Home report also contains that perspective but refers to a different historical workspace path and cannot replace this direct current review (`.omo/evidence/final-product-quality-gate-review.md:81-139`).

## Checked artifact paths

- `/Users/eli/OTP/weather_os/test/visual/goldens/*.png` (all 16 files, directly opened)
- `/Users/eli/OTP/weather_os/test/visual/home_golden_test.dart`
- `/Users/eli/OTP/weather_os/test/visual/showcase_golden_test.dart`
- `/Users/eli/OTP/weather_os/lib/features/weather/models/mock_weather.dart`
- `/Users/eli/OTP/weather_os/lib/features/weather/screens/weather_home_screen.dart`
- `/Users/eli/OTP/weather_os/lib/features/weather/widgets/weather_atmosphere.dart`
- `/Users/eli/OTP/weather_os/.omo/evidence/primitive-quality-gate-5-gate-review.md`
- `/Users/eli/OTP/weather_os/.omo/evidence/final-product-quality-gate-review.md`

## Exact evidence gaps

- A fresh, fully composed `home_motion_start.png` generated after the final source/test edit.
- A matching fresh `home_motion_mid.png` from the same build/run context, with an objective comparison confirming foreground identity and atmosphere-only pixel changes.

## Required next gate

Repair the start-frame capture/compositing path, regenerate both Home motion captures from the same final revision, directly inspect both, and re-run the focused golden suite. Do not accept a green snapshot comparison until the refreshed start image is visibly complete.
