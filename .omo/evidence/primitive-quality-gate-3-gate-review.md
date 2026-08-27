# Primitive Quality Gate 3

recommendation: REJECT

## Original intent

Ship the regenerated WeatherOS primitive showcase as a responsive, accessible, token-driven cinematic weather surface across compact, medium, expanded, lower-scroll, and 1.8x-text states.

## Desired outcome

All five current goldens show one coherent full-height atmospheric field with exactly one glass lens, no clipping, a working narrow 2x2 metric fallback, and valid compact/medium/expanded composition. Tests must meaningfully cover reduced motion and semantics, not merely render without exceptions.

## User outcome review

Compact, medium, compact-lower, and large-text frames are composed without internal overflow. The large-text bottom edge is normal scroll continuation, and compact-lower demonstrates the 2x2 metric fallback. Source inspection confirms a single `GlassLens` use around the hourly rail and semantic labels for the hero, forecast cells, and metrics. However, the expanded frame has a materially dead lower third instead of coherent cinematic depth, and reduced-motion behavior is not meaningfully asserted.

## Blockers

1. violatedCriterion: `full-height-cinematic-atmospheric-depth`
   evidencePointer: `test/visual/goldens/showcase_expanded.png` (approximately y=607..899); `lib/features/weather/screens/weather_showcase_screen.dart:20`; `lib/features/weather/widgets/weather_atmosphere.dart:72`
   observation: Atmospheric detail and composition occupy the upper portion while roughly the bottom 293 px reads as an undifferentiated near-black field. The viewport is technically painted, but the requested coherent full-height cinematic depth is not achieved.

2. violatedCriterion: `reduced-motion-test-coverage`
   evidencePointer: `test/weather_accessibility_test.dart:11`
   observation: The test only enables `disableAnimations`, calls `pumpAndSettle`, and asserts no exception. It does not distinguish a frozen atmospheric controller or bypassed hero reveal from the animated implementation, so it is tautological false-confidence coverage for the named behavior.

## Direct remove-ai-slops and programming pass

- No deletion-only tests, requested-removal tests, prompt/prose pins, or unnecessary production extraction were found.
- Golden tests are legitimate visual regression coverage, but they can canonize a visual defect and do not independently establish intent.
- The reduced-motion test is over-broad and implementation-insensitive: it remains green without proving the observable reduced-motion outcome.
- No production abstraction, typing, or maintenance-burden issue independently blocks a stated criterion.

## Checked artifacts

- `DESIGN.md`
- `lib/app/theme/weather_theme.dart`
- `lib/app/theme/weather_tokens.dart`
- All files in `lib/features/weather/widgets/`
- `lib/features/weather/screens/weather_showcase_screen.dart`
- `test/weather_accessibility_test.dart`
- `test/widget_test.dart`
- `test/visual/showcase_golden_test.dart`
- `test/visual/goldens/showcase_compact.png`
- `test/visual/goldens/showcase_medium.png`
- `test/visual/goldens/showcase_expanded.png`
- `test/visual/goldens/showcase_compact_lower.png`
- `test/visual/goldens/showcase_large_text.png`
- `.omo/evidence/primitive_fidelity_gate_2-clone-fidelity.md`

## Reproduced evidence

- `flutter analyze`: PASS, no issues.
- `flutter test`: PASS, 10 tests.
- All five PNG signatures and dimensions are valid; each golden postdates the latest rendered source.
- Two independent visual passes disagreed on whether the expanded lower field was acceptably quiet. Direct gate judgment treats it as blocking because the explicit criterion is coherent full-height cinematic depth, not merely viewport paint coverage.

## Exact evidence gaps

- No behavioral assertion or frame comparison proves the atmosphere remains unchanged over elapsed time when reduced motion is enabled.
- No behavioral assertion proves the hero reveal is bypassed under reduced motion.
- The expanded golden itself is the evidence of the full-height depth failure; no additional artifact is missing for that criterion.

## Notes

- `omo ulw-loop status --json` was unavailable because `omo` is not installed in this environment, so the required fallback report path was used.
- The workspace is not a Git repository, so no branch diff or changed-file report was available.
