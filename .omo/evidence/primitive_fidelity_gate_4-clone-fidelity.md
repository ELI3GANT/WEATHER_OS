# WeatherOS primitive fidelity gate 4

## Recommendation: REQUEST_CHANGES

**Confidence:** high. This is a fresh, current-state review of the supplied
reference, all five current golden images, and every Dart file under
`lib/app/theme` and `lib/features/weather`. No prior report was used as
evidence.

## Evidence inspected

- Reference: `design/references/weatheros-concept-b.png` (853 x 1844).
- Goldens: `test/visual/goldens/showcase_compact.png` (390 x 844),
  `showcase_medium.png` (768 x 1024), `showcase_expanded.png` (1280 x 900),
  `showcase_compact_lower.png` (390 x 844), and `showcase_large_text.png`
  (390 x 844).
- Design contract: `DESIGN.md`, especially the source-selection record (line
  9), conditions-first hierarchy (lines 12-22), viewport atmosphere (lines
  107-115), and documented token contract (lines 72-95).
- Source: every current Dart file in `lib/app/theme` and
  `lib/features/weather`.
- Accessibility source: `test/weather_accessibility_test.dart`.
- Fresh verification command:
  `flutter test test/weather_accessibility_test.dart test/visual/showcase_golden_test.dart`
  — 10 tests passed.

## Confirmed resolved checks

- **Live composition, not a pasted image:** the source has no `Image`,
  `AssetImage`, `DecorationImage`, or background-image use in the reviewed
  UI. The route composes `WeatherAtmosphere`, `CurrentConditionsHero`,
  `HourlyForecastRail`, and `WeatherMetricsStrip` as live Flutter widgets;
  `WeatherAtmosphere` renders with `CustomPaint`.
- **Full atmosphere boundary:** the atmosphere uses an internal
  `RepaintBoundary` and `SizedBox.expand()`
  ([weather_atmosphere.dart](../../lib/features/weather/widgets/weather_atmosphere.dart#L45),
  [weather_atmosphere.dart](../../lib/features/weather/widgets/weather_atmosphere.dart#L57)),
  mounted in `Positioned.fill`
  ([weather_showcase_screen.dart](../../lib/features/weather/screens/weather_showcase_screen.dart#L23)).
  The fresh 1280 x 900 test explicitly verifies its size
  ([weather_accessibility_test.dart](../../test/weather_accessibility_test.dart#L38)).
  The expanded golden has a painted lower field (haze/strata), not an
  unpainted/dead rectangle.
- **Procedural atmosphere foundation:** clouds are live procedural paths:
  several drifting contour planes, a storm core, 26 irregular billows, and
  lower strata are painted in
  [atmospheric_clouds.dart](../../lib/features/weather/widgets/atmospheric_clouds.dart#L18),
  [atmospheric_clouds.dart](../../lib/features/weather/widgets/atmospheric_clouds.dart#L92),
  and
  [atmospheric_clouds.dart](../../lib/features/weather/widgets/atmospheric_clouds.dart#L134).
  The current goldens demonstrate the rain path; storm-variant visual proof is
  called out below as a remaining evidence gap.
- **Requested component topology:** the hero is direct (not wrapped in
  `GlassLens`); `GlassLens` has one production call site, the hourly rail
  ([hourly_forecast_rail.dart](../../lib/features/weather/widgets/hourly_forecast_rail.dart#L22)).
  Expanded uses a left hero/right forecast-and-metrics structure
  ([weather_showcase_screen.dart](../../lib/features/weather/screens/weather_showcase_screen.dart#L100)).
  The 1.8x text scenario is exercised by both the accessibility test
  ([weather_accessibility_test.dart](../../test/weather_accessibility_test.dart#L72))
  and the inspected golden.

## Findings

### HIGH — The rendered route does not preserve the reference’s conditions-first hierarchy.

The selected reference begins with the product identity, location, and
monumental current condition; its single optical forecast lens establishes the
weather horizon. The current compact and medium goldens instead spend their
upper region on `PRIMITIVE SHOWCASE`, `WeatherOS optical system`, and a weather
glyph specimen list before the condition hero appears. Those extra rows are
implemented at
[weather_showcase_screen.dart](../../lib/features/weather/screens/weather_showcase_screen.dart#L43)
through
[weather_showcase_screen.dart](../../lib/features/weather/screens/weather_showcase_screen.dart#L58).

This conflicts with the design contract’s explicit “conditions before
controls” rule (`DESIGN.md:16-22`) and materially changes the reference layer
hierarchy. The current design reads as a component catalog, not the WeatherOS
weather experience represented by `weatheros-concept-b.png`.

### HIGH — Reusable geometry remains component-local rather than fully token-driven.

`WeatherLayout` and `WeatherOptics` are a substantial improvement and are
documented in `DESIGN.md:89-95`, but current reusable glyph geometry bypasses
them:

- `WeatherGlyph` has an un-tokenized reusable default of `44`
  ([weather_glyph.dart](../../lib/features/weather/widgets/weather_glyph.dart#L8)).
- `MetricGlyph` has an un-tokenized reusable default of `28`
  ([metric_glyph.dart](../../lib/features/weather/widgets/metric_glyph.dart#L9)).
- The hero supplies another local glyph size, `40`
  ([current_conditions_hero.dart](../../lib/features/weather/widgets/current_conditions_hero.dart#L76)).
- The showcase specimen list supplies `28` directly
  ([weather_showcase_screen.dart](../../lib/features/weather/screens/weather_showcase_screen.dart#L149)).

These are reusable primitive geometry values, not per-instance weather data.
They have neither named design tokens nor documentation in the declared token
table. This fails the stated rigorous token-driven requirement even though no
raw component hex colors were found.

### MEDIUM — The visual atmosphere is procedurally real but still visibly less faithful to the reference’s irregular cloud massing.

The code does produce multiple path-based planes and billows, so it is not a
fake raster substitute. However, the inspected goldens, especially compact and
expanded, render much of that material as similarly soft circular blobs on the
right. The reference has sharper, overlapping, directionally varied storm
structures extending through the central composition. This reduces the
reference’s cinematic depth, though it is not the previous lower-dead-field
failure.

### MEDIUM — The supplied visual evidence does not exercise the storm variant itself.

All five showcase goldens mount rain directly
([weather_showcase_screen.dart](../../lib/features/weather/screens/weather_showcase_screen.dart#L23)).
The storm code path does call the same cloud routine at a greater density
([weather_atmosphere.dart](../../lib/features/weather/widgets/weather_atmosphere.dart#L85)),
but no current golden or test renders `WeatherCondition.storm`. Further, the
irregular billow loop is procedural but does not consume animation progress
([atmospheric_clouds.dart](../../lib/features/weather/widgets/atmospheric_clouds.dart#L92)).
Current artifacts therefore prove a live rain atmosphere and source-level storm
composition, not visual fidelity of the requested storm state.

### LOW — Golden tests prove regression consistency, not comparison with the art-direction contract.

The golden test compares the route to its own stored images
([showcase_golden_test.dart](../../test/visual/showcase_golden_test.dart#L36)),
and the fresh run passed. That is useful current-state evidence, but it cannot
by itself demonstrate that those images match `weatheros-concept-b.png`.

## Concrete blockers before approval

1. Make the actual rendered surface preserve the reference/`DESIGN.md`
   conditions-first hierarchy; the primitive-catalog header and glyph catalog
   cannot displace the current-conditions hero in the fidelity target.
2. Centralize and document the remaining reusable glyph-size geometry in the
   token system, then consume those tokens at the listed call sites.
3. Bring the visible procedural cloud massing closer to the reference’s
   irregular, layered storm field; retain the current live-painting approach.
4. Add current visual evidence that renders the storm variant before claiming
   its fidelity.

No CRITICAL finding was observed. The two HIGH findings require
`REQUEST_CHANGES` under the fidelity gate.
