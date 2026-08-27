# Clone Fidelity Review — final_product_fidelity

**Recommendation: REQUEST_CHANGES**  
**Confidence: high**  
**Scope:** production WeatherOS home screen, read-only review on 2026-08-20.

## Artifacts inspected

- Reference: `design/references/weatheros-concept-b.png` (853 × 1844).
- Home render set (all seven):
  `test/visual/goldens/home_compact_android.png` (360 × 800),
  `home_compact_ios.png` (390 × 844), `home_medium.png` (768 × 1024),
  `home_expanded.png` (1280 × 900), `home_short_lower.png` (320 × 640),
  `home_motion_start.png` (390 × 844), and `home_motion_mid.png` (390 × 844).
- Runtime screenshots: `output/playwright/weatheros-safari-expanded.jpeg` and
  `output/playwright/weatheros-safari-accessible.jpeg` (both 969 × 768,
  browser chrome included).
- Design/source: `DESIGN.md`; `lib/app/theme/weather_tokens.dart`;
  `lib/features/weather/screens/weather_home_screen.dart`; widgets
  `weather_atmosphere.dart`, `atmospheric_clouds.dart`, `glass_lens.dart`,
  `current_conditions_hero.dart`, `hourly_forecast_rail.dart`,
  `weather_metrics_strip.dart`, `weather_glyph.dart`, and `metric_glyph.dart`;
  `test/visual/home_golden_test.dart`; `test/weather_accessibility_test.dart`.
- Validation: `flutter test test/visual/home_golden_test.dart
  test/weather_accessibility_test.dart` passed (12 tests). This does not
  override the visual findings below.

## Confirmed strengths

- This is not a screenshot-backed fake. Production code contains no home-surface
  image asset use; it renders a live Flutter tree. `WeatherHomeScreen` composes
  a `WeatherAtmosphere`, hero, `GlassLens` forecast rail, and metric strip
  (`weather_home_screen.dart:22-29`, `64-84`, `122-143`). Atmosphere, weather
  glyphs, and metric glyphs are Canvas `CustomPainter`s, not raster backgrounds
  (`weather_atmosphere.dart:44-63,72-91`; `weather_glyph.dart:20-27,37-80`;
  `metric_glyph.dart:21-28,38-116`).
- The main visual roles are tokenized: palette, spacing, breakpoints, optical
  material, motion, and typography are centralized in
  `weather_tokens.dart:3-154`, then consumed by the hero, lens, rail, and
  metrics. No component-local raw color was found in the inspected home UI.
- The normal compact, medium, expanded, and short-scroll captures preserve a
  conditions-first hierarchy, one forecast lens, live rain/cloud depth, a
  coherent Barlow type ramp, and an appropriate compact metrics fallback. The
  ordinary Safari expanded runtime capture also preserves the intended
  left-conditions/right-instrument arrangement.

## Findings

### CRITICAL

1. **Accessibility runtime loses the current-conditions hero.**
   In `output/playwright/weatheros-safari-accessible.jpeg`, the left field at
   approximately x=89–240, y=320–525 contains only fragments such as `NRK` and
   `L 62°`; the location, temperature, condition, and feels-like content are
   otherwise absent while the forecast/metrics remain. This is a current-source
   runtime capture (14:34:27) after the relevant hero/rail sources (14:26:17).
   It breaks the responsive/accessibility contract in `DESIGN.md:202-213` and
   means conditions-first is not usable with accessibility text settings.

### HIGH

1. **The supplied mid-motion frame has foreground-content loss.**
   Relative to `home_motion_start.png`,
   `test/visual/goldens/home_motion_mid.png` visibly loses/clips the left of
   `WEATHEROS`, the hero/supporting copy, the first forecast value, and
   lower-left metric content. The intended contract says ambient weather is the
   single signature animation region and must not animate layout
   (`DESIGN.md:177-180`; `current_conditions_hero.dart:109-126`). Motion
   evidence must establish that foreground content stays complete at start and
   mid motion; this supplied artifact does the opposite.

2. **Motion evidence is not fresh relative to the rendered source.**
   Both motion goldens are timestamped 14:25:58, before
   `current_conditions_hero.dart`, `hourly_forecast_rail.dart`, and
   `weather_metrics_strip.dart` at 14:26:17. Under the visual-QA evidence rule,
   these cannot prove the current build’s motion fidelity. The snapshot test
   only compares rendered pixels with the stored golden
   (`test/visual/home_golden_test.dart:65-82`), so its pass does not repair the
   stale-artifact gap.

### MEDIUM

1. **Large-text coverage is indirect and insufficient for the home screen.**
   The only large-text test drives `WeatherShowcaseScreen`, then checks that
   `PRESSURE` can be reached and no exception occurred
   (`test/weather_accessibility_test.dart:72-89`). It neither renders
   `WeatherHomeScreen` nor asserts that every hero field remains visible. The
   failed Safari accessibility screenshot confirms this gap.

### LOW

1. **The cloud field is softer and more bulbous than concept B’s sculpted,
   high-contrast storm mass.** In the goldens, especially the right half of
   `home_expanded.png`, the procedural billows read as rounded blurred forms
   rather than the reference’s sharply layered storm illumination. This is a
   fidelity refinement, not the cause of the rejection. The relevant painter is
   `atmospheric_clouds.dart:92-144`.

## Blockers before approval

1. Provide a fresh runtime capture demonstrating the whole current-conditions
   hero at the accessibility text setting, without clipping or loss.
2. Correct the foreground loss seen in the mid-motion scenario and provide
   fresh start/mid captures proving only the atmosphere changes.
3. Refresh the motion evidence after the last rendered-source change; do not
   rely only on a matching stale golden.

No CRITICAL/HIGH issue concerns a raster substitute or the existence of design
tokens: those checks pass. The request is denied solely because the delivered
runtime/evidence shows the product losing core weather information in required
states.
