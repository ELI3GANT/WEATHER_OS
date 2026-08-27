# Primitive Fidelity Gate 3 — Clone / Design-System Review

**Recommendation: REQUEST_CHANGES (FAIL)**  
**Confidence: HIGH**

## Scope and current evidence inspected

- Design contract: `DESIGN.md`, especially the selected `weatheros-concept-b.png` art-direction contract (lines 5-14), responsive contract (89-95), component definitions (99-147), and depth recipe (173-185).
- Reference image, opened directly: `design/references/weatheros-concept-b.png` (853x1844 RGB PNG).
- Current implementation, opened directly: `lib/app/theme/weather_tokens.dart`, `weather_theme.dart`, `weather_showcase_screen.dart`, and every production widget below `lib/features/weather/widgets/`.
- Current capture set, each opened directly and validated as a PNG at its declared viewport:
  - `test/visual/goldens/showcase_compact.png` (390x844 RGBA)
  - `test/visual/goldens/showcase_compact_lower.png` (390x844 RGBA)
  - `test/visual/goldens/showcase_medium.png` (768x1024 RGBA)
  - `test/visual/goldens/showcase_expanded.png` (1280x900 RGBA)
  - `test/visual/goldens/showcase_large_text.png` (390x844 RGBA, test scenario uses `TextScaler.linear(1.8)` at `test/visual/showcase_golden_test.dart:67-95`)
- Freshness: all five captures were modified at 2026-08-20 13:55:25-26, after the most recently reviewed rendering source (`atmospheric_clouds.dart`, 13:55:12).
- Anti-fake scan: production Dart does not reference `Image`, `AssetImage`, `DecorationImage`, `NetworkImage`, or the reference/golden images. The only PNG references are golden-match assertions in `test/visual/showcase_golden_test.dart:38,63,94`.

## Confirmed good

- **Real component tree, not a screenshot substitute.** `WeatherShowcaseScreen` composes a `WeatherAtmosphere`, `CurrentConditionsHero`, `HourlyForecastRail`, and `WeatherMetricsStrip` (`lib/features/weather/screens/weather_showcase_screen.dart:20-57`). Atmosphere and glyphs are live `CustomPainter` output (`weather_atmosphere.dart:51-57`, `weather_glyph.dart:21-27`, `metric_glyph.dart:22-28`).
- **Actual reusable primitives exist.** The atmosphere has four weather variants (`weather_atmosphere.dart:77-90`), the glyph has four variants (`weather_glyph.dart:47-80`), and the hourly rail chooses scroll versus fitted rendering from available width (`hourly_forecast_rail.dart:26-52`).
- **Palette and principal type are centralized.** Raw hex values are confined to `WeatherPalette` (`weather_tokens.dart:3-18`); components use that palette, and the Barlow type family/styles are centrally defined (`weather_tokens.dart:68-131`).
- **The required product hierarchy is substantially present.** The hero is live in the atmospheric field rather than inside a `GlassLens`; the forecast rail is the sole glass lens in the showcased composition (`weather_showcase_screen.dart:80-94`, `hourly_forecast_rail.dart:19-55`). The expanded capture follows the left-condition/right-instrument arrangement (`weather_showcase_screen.dart:105-124`).
- **1.8x text is not visibly clipped or overflowed in the supplied capture.** The large-text capture retains a legible title, glyph specimens, location, temperature, and condition; the source supports the lower content through the owning vertical `SingleChildScrollView` (`weather_showcase_screen.dart:30-63`).

## Findings

### CRITICAL

None. I found no raster/screenshot or background-image substitute for live Flutter UI.

### HIGH

1. **[product] The expanded atmosphere does not fill the expanded viewport.** `showcase_expanded.png` visibly stops the atmospheric/rain field at approximately y=607, leaving the lower roughly 293 px as near-solid canvas black. This directly fails the required full-height expanded atmosphere and the `Atmosphere Backdrop` viewport-fill contract in `DESIGN.md:99-106`. The rendered boundary is built from the default-fit `Stack` beginning at `lib/features/weather/screens/weather_showcase_screen.dart:20`, with the atmosphere only positioned relative to that stack (`:22-24`); the artifact, not an assumption about intent, proves the final result is not viewport-filling.

2. **[product] The storm field remains materially below the reference’s premium, procedural storm depth.** The selected reference has a highly layered, sharply varied cloud mass: bright turbulent cloud cores, dark foreground volume, depth planes, and a concentrated right-side storm focal point behind the temperature. Across `showcase_compact.png`, `showcase_compact_lower.png`, `showcase_medium.png`, `showcase_expanded.png`, and `showcase_large_text.png`, the current field instead resolves as a small set of soft, repeated bluish cloud bands over a smooth navy gradient with sparse rain. It is recognizably live and improved from a flat fill, but it does not carry the reference’s dimensional storm atmosphere required by `DESIGN.md:9-14` and `:173-185`.

   The code supports that visual reading: seven similarly constructed, low-alpha contours are reused from `_clusters` (`lib/features/weather/widgets/atmospheric_clouds.dart:5-14,24-84`); the painter’s bright-layer opacity derives from the same low alpha scale (`:34,51-58,73-82`). That is a legitimate procedural implementation, but it is not yet visually faithful to the target material.

3. **[system] Styling is not rigorously token-driven through all reusable primitive decisions.** Color identity and primary type are tokenized, but visual material, primitive geometry, and a type override still use undocumented component-local constants. This fails the stated requirement that tokens drive colors, spacing, and typography, rather than merely centralizing palette hex values.

   - `lib/features/weather/widgets/glass_lens.dart:21-25,35-36,48,56-58` sets rim/lift/material alpha values and the 1-dp optical gap locally.
   - `lib/features/weather/widgets/hourly_forecast_rail.dart:91,98,101-102` sets the forecast-glyph size, 20-dp forecast type override, and 22x2 current marker locally.
   - `lib/features/weather/widgets/weather_metrics_strip.dart:63-65` sets a 1-dp divider and its opacity locally.
   - `lib/features/weather/widgets/current_conditions_hero.dart:36-38` uses a component-local compact cap of 128 even though the documented compact temperature token is 112 (`DESIGN.md:55-64`).

   Vector path coordinates in a painter do not need to become global design tokens; these findings are limited to repeated primitive material, layout, and type decisions that define the system’s visible output.

### MEDIUM

None.

### LOW

None.

## Blocking changes before approval

1. Make the atmospheric painting verifiably cover the full 1280x900 expanded capture; it cannot terminate above the metrics with a black remainder.
2. Bring the rendered storm field much closer to the selected concept’s multi-plane, luminous cloud depth across compact, medium, expanded, and large-text states. It must remain live/procedural rather than becoming a pasted reference image.
3. Promote reusable material values, component dimensions, and typography variants listed above into documented WeatherOS tokens and consume those tokens from the primitives.

The source tree is genuine and the one-lens/hero/responsive structure is sound. Approval is withheld solely for the remaining artifact-backed HIGH issues above.
