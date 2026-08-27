# Primitive Fidelity Gate 2 — Clone / Design-System Review

**Recommendation: REQUEST_CHANGES (FAIL)**  
**Confidence: HIGH**  
**Scope reviewed:** corrected WeatherOS primitive showcase before product composition.

## Evidence inspected

- Design contract: `DESIGN.md`, including Sections 1, 4, 5, 7, and 8.
- Reference art-direction target: `design/references/weatheros-concept-b.png` (853×1844).
- Fresh, valid RGBA PNG captures, all opened and visually inspected:
  - `test/visual/goldens/showcase_compact.png` (390×844, modified 2026-08-20 13:48:43)
  - `test/visual/goldens/showcase_compact_lower.png` (390×844, modified 2026-08-20 13:48:44)
  - `test/visual/goldens/showcase_medium.png` (768×1024, modified 2026-08-20 13:48:43)
  - `test/visual/goldens/showcase_expanded.png` (1280×900, modified 2026-08-20 13:48:44)
  - `test/visual/goldens/showcase_large_text.png` (390×844, modified 2026-08-20 13:48:44)
- Live implementation and primitive tree: `lib/app/theme/weather_tokens.dart`, `weather_theme.dart`, and every weather widget under `lib/features/weather/widgets/`, plus `weather_showcase_screen.dart`.
- Verification run on this checkout: `flutter test test/visual/showcase_golden_test.dart` (5/5 passed) and `flutter analyze` (no issues).
- Anti-fake scan: application code has no `Image.asset`, `AssetImage`, `DecorationImage`, or reference/golden PNG use. The only PNG references are golden assertions in the test.

## What is confirmed good

- This is a live Flutter widget/painter composition, not a pasted screen or a raster background: `WeatherShowcaseScreen` composes `WeatherAtmosphere`, `CurrentConditionsHero`, `HourlyForecastRail`, and `WeatherMetricsStrip`; the atmosphere and glyphs are `CustomPainter` implementations. No image-backed UI substitute was found.
- The hero directly inhabits the atmospheric field. It is not wrapped by `GlassLens`; the forecast rail alone instantiates `GlassLens` (`lib/features/weather/widgets/hourly_forecast_rail.dart:17`). Metrics remain a typographic strip, not a second glass card.
- The >=900 capture has the required left hero / right instrument arrangement, implemented by `_ExpandedShowcase` (`lib/features/weather/screens/weather_showcase_screen.dart:101-124`).
- The cloud implementation is not literally a row of ovals: it uses layered cubic contours, gradients, and blur (`lib/features/weather/widgets/atmospheric_clouds.dart:27-61`, `:65-114`).
- Large text does not show a Flutter overflow indicator or clipped glyph in `showcase_large_text.png`; the lower condition content continues in the owning vertical scroll view.

## Findings

### CRITICAL

None. There is no screenshot/raster substitution for the rendered UI.

### HIGH

1. **The rendered storm field is materially flatter than the selected cinematic reference, so the cloud fidelity gate fails.** The reference's defining visual mass is a deep, readable, multi-plane storm cloud formation behind the hero. In every rain capture the shipped field resolves chiefly as a smooth navy/gray gradient with sparse diagonal rain; cloud forms are either imperceptible or read as broad soft washes rather than cinematic cloud volume. This fails the requested “cinematic rather than flat ovals” outcome even though the underlying paths are technically non-oval.

   - `showcase_compact.png`: the hero has correct direct-atmosphere placement, but no discernible cloud volume behind the 71° focus.
   - `showcase_compact_lower.png`: the direct field remains shallow below the rail; the metric area has rain lines but no cloud-layer depth.
   - `showcase_medium.png`: the wide central hero makes the lack of readable cloud planes especially visible.
   - `showcase_expanded.png`: the left hero field is effectively a dark gradient/rain field rather than the target's storm observatory.
   - `showcase_large_text.png`: the enlarged type is legible, but the background still does not supply the target cloud material.

   Code origin: `lib/features/weather/widgets/atmospheric_clouds.dart:20-24, 40-60` applies very low-alpha cloud colors (`0.055` base alpha before multiplication) and broad blur; this is consistent with the low-contrast result seen in the captures. The atmospheric target in `DESIGN.md:10-14` and `:143-149` calls for a living, cinematic field, not merely rain over a gradient.

2. **The primitives are not fully token-driven; component-local typography and spatial values bypass the documented system.** `DESIGN.md` says raw component colors are prohibited and defines a token scale, while the review gate requires colors, spacing, and typography to trace to it. The following are one-off visual values in reusable primitives, without corresponding token definitions:

   - `lib/features/weather/widgets/hourly_forecast_rail.dart:23,26,44,94,97-98` — rail height `128`, fit threshold `82`, cell width `74`, hourly temperature `fontSize: 20`, and selected marker `22 × 2`.
   - `lib/features/weather/widgets/glass_lens.dart:40-41,46` — optical shadow blur/offset `20/10` and 1-dp rim gap.
   - `lib/features/weather/widgets/weather_metrics_strip.dart:63-64` — 1-dp divider and 72-dp divider height.
   - `lib/features/weather/widgets/current_conditions_hero.dart:36-38` — a compact temperature cap of `128` is used despite the documented compact temperature token being 112.

   Some raw geometry inside `CustomPainter` is appropriate for drawing a vector path; these findings concern reusable component size, type, spacing, elevation, and marker decisions. They need named tokens documented in `DESIGN.md` and exposed through `weather_tokens.dart` before this can be called a rigorous reusable design system.

### MEDIUM

1. **The expanded atmospheric field visibly ends around y≈607, leaving the lower ~293 px as a near-solid canvas black area.** `showcase_expanded.png` therefore breaks the `DESIGN.md` viewport-fill backdrop contract and weakens the intended observatory scene. The likely layout source is the loose default `Stack` at `lib/features/weather/screens/weather_showcase_screen.dart:18-25`, despite its positioned atmospheric child; confirm the stack's resolved size and make the atmospheric layer cover the full viewport.

### LOW

None.

## Blocking changes before approval

1. Increase the rendered cloud field's layered, readable volume so all rain captures visibly carry the selected cinematic storm material rather than a mostly flat gradient with rain.
2. Move reusable primitive dimensions, type sizes, elevation/rim, and selection-marker geometry into documented WeatherOS tokens; use those tokens in the widgets.

The expanded backdrop discontinuity should also be corrected before product composition, but it is not the reason for the gate failure by itself.
