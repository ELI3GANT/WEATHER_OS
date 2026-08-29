# WeatherOS Final Visual Fidelity Gate

recommendation: REJECT

## Original intent

Independently verify the current WeatherOS golden set after the final fixture changes, with complete visual coverage and special attention to motion start/mid foreground integrity, true storm forecast data, compact Android 12 PM visibility, large-text top/lower continuation, and deterministic fixed test inputs.

## Desired outcome

Every PNG under `test/visual/goldens` is a valid, fully composed artifact that proves the named state without clipped foreground content. The two golden harnesses use fixed date/hour/phase inputs, the storm capture renders storm-specific hourly and daily data, compact Android fully shows 12 PM, and large-text top/lower captures remain legible and reachable.

## User outcome review

The current set does not satisfy the requested outcome because `home_motion_start.png` visibly clips foreground content across the full screen. The top location reads only `Woon...`, the hero loses the left of `Feels like 69` and `Rain`, `DAY SUMMARY` and `HOURLY FORECAST` lose their leading characters, multiple daily rows lose their left portions, and the bottom navigation loses `Today`. This is not a subtle pixel-diff issue: the supplied golden itself records incomplete foreground content.

The remaining 15 PNGs were directly opened and inspected. The mid-motion frame is complete; the compact Android image fully displays `12 PM`; `showcase_storm.png` visibly renders a 65 degree Storm hero and storm icons/85-100% precipitation across the visible hourly rail; both home and showcase large-text top/lower pairs remain legible continuations without accidental crop. All files are valid RGBA PNGs at their intended dimensions.

## Blockers

1. `violatedCriterion: motion-start-no-clipped-foreground`
   - Observation: `home_motion_start.png` contains widespread foreground truncation while the corresponding mid frame is complete.
   - `evidencePointer: /Users/eli/OTP/weather_os/test/visual/goldens/home_motion_start.png` (SHA-256 `1d4544b30fd71955754ca400b9818405f9c4cec3d86eee542e00ab778562b39c`), contrasted with `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_mid.png`.

2. `violatedCriterion: motion-gate-must-detect-foreground-clipping`
   - Observation: the motion test only matches the stored PNG and makes no foreground-completeness or stable-geometry assertion, so the clipped baseline passes unchanged; the reproduced targeted suite reports all 16 tests passed despite the visible defect.
   - `evidencePointer: /Users/eli/OTP/weather_os/test/visual/home_golden_test.dart:170` and `/Users/eli/OTP/weather_os/test/visual/home_golden_test.dart:185`.

## Determinism and named-state review

- Home harness: PASS for deterministic inputs. Fixed `DateTime(2026, 8, 29, 12)` and explicit atmosphere phases 0.0/0.25 are supplied at `home_golden_test.dart:170-182` and `:233-235`; viewport, DPR, platform, reduced motion, static service, disabled cache, and discarded telemetry are controlled.
- Showcase harness: PASS for fixed hour and state. `atmosphereHour: 12` is supplied at `showcase_golden_test.dart:145`, with fixed weather fixtures, viewport, DPR, reduced motion, and text scale.
- Storm data: PASS. `newYorkStorm` is a distinct fixture with storm current condition, the first six hourly items storm, and the first daily item storm (`mock_weather.dart:177-286`); the harness asserts those facts at `showcase_golden_test.dart:99-107`.
- Compact Android 12 PM: PASS visually and behaviorally. `12 PM` is fully visible in the 360x800 PNG, and the harness asserts its right edge remains at least 16 px inside the rail.
- Large text: PASS for inspected top/lower pairs. Home and showcase 1.8x captures retain readable content and lower continuation.

## Direct remove-ai-slops and programming pass

- Blocking false confidence: the motion golden assertion mirrors an accepted baseline and therefore treats a requested visual failure as success. This is an overfit golden-only check for the named foreground-integrity criterion.
- The storm fixture assertions are narrow and useful: they prevent the earlier rain-alias fixture from masquerading as storm data.
- The compact Android geometry assertion is behavior-oriented and directly protects full `12 PM` visibility.
- The large-text lower captures exercise distinct scroll continuations and are not redundant deletion/removal tests.
- No unnecessary parser, normalization layer, speculative production extraction, deletion-only test, or requested-removal test was found in the reviewed visual harness diff.
- NOTE: `MockWeather.newYorkStorm` is a large inline fixture. That is maintenance weight, but it does not violate a named success criterion and is not a blocker.

## Checked artifact paths

- Both harnesses: `/Users/eli/OTP/weather_os/test/visual/home_golden_test.dart`, `/Users/eli/OTP/weather_os/test/visual/showcase_golden_test.dart`
- Fixture: `/Users/eli/OTP/weather_os/lib/features/weather/models/mock_weather.dart`
- All 16 files under `/Users/eli/OTP/weather_os/test/visual/goldens/`
- Prior reports under `/Users/eli/OTP/weather_os/.omo/evidence/`, including `final-product-quality-gate-review.md`, `final_product_fidelity-clone-fidelity.md`, and `primitive-quality-gate-5-gate-review.md`

## Reproduced evidence

- `file test/visual/goldens/*.png`: all 16 are valid non-interlaced 8-bit RGBA PNGs with expected dimensions.
- Direct original-resolution inspection: all 16 PNGs opened; one blocking artifact found (`home_motion_start.png`).
- `flutter test test/visual/home_golden_test.dart test/visual/showcase_golden_test.dart --reporter=compact`: PASS, 16/16. This confirms deterministic reproducibility but also demonstrates that the current suite accepts the clipped motion-start artifact.

## Exact evidence gaps

- No current executor report, code-review report, manual-QA matrix, or notepad path was supplied. Existing evidence reports were inspected but predate the current 16-image set and contain contradictory motion findings, so they cannot replace this direct pass.
- `omo ulw-loop status --json` is unavailable (`command not found`); this report uses the required fallback evidence path.
- No exact external reference image was supplied for pixel comparison. The rejection does not depend on reference taste; it is tied directly to the explicit no-clipped-foreground criterion.

## Required correction

Regenerate the start-motion frame so every foreground label and navigation item is fully composed, then add a foreground-integrity/stable-geometry assertion that fails when the start frame clips or shifts content. Re-run both golden harnesses and re-inspect the refreshed start/mid pair.
