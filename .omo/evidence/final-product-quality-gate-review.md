# WeatherOS Final Product Quality Gate

recommendation: REJECT

## Original intent

Ship a production-ready WeatherOS home experience that is visually coherent
across compact, medium, expanded, short-scroll, and animated states, while also
providing real Safari runtime proof of the loading-to-loaded transition and the
intended accessibility reading order.

## Desired outcome

All seven production home goldens and both real Safari runtime captures should
jointly prove: no clipping or overlap; distinct compact and expanded
compositions; a discoverable horizontally scrollable hourly rail; reachable
metrics; exactly one optical lens; a full-viewport atmosphere; motion frames
that differ without moving layout; a real loading-to-loaded transition; and
Safari accessibility order of current conditions, hourly forecast, then
metrics.

## User outcome review

The production UI itself is visually strong and coherent. Direct inspection of
all seven requested home goldens found no accidental clipping or overlap. The
compact layouts use a centered vertical hierarchy, the expanded layout uses a
left hero and right instrument stack, the compact Android rail exposes a
partially visible next cell as a horizontal-scroll cue, the short lower capture
shows all four metrics after scrolling, and every composition contains only
the forecast lens. The atmosphere fills every frame. The two motion goldens
retain identical component geometry while rain/cloud positions differ.

The available real Safari artifacts do not, however, prove two outcomes that
the gate explicitly requires. Both JPEGs are post-load frames: one is fully
loaded and one catches the loaded hero during its reveal. Neither shows the
`WeatherLoadingView` or another discriminating loading state. In addition,
static JPEG pixels contain no accessibility-tree or VoiceOver traversal data,
so they cannot prove Safari accessibility text order. Flutter widget tests and
source ordering support the intended order, but they are not real Safari
accessibility evidence.

## Blockers

1. `violatedCriterion: loading-to-loaded-runtime-evidence`
   - Observation: Neither Safari JPEG captures a discriminating loading state;
     `weatheros-safari-expanded.jpeg` shows already-loaded forecast and metrics
     with the hero mid-reveal, while `weatheros-safari-accessible.jpeg` shows
     the complete loaded state. The widget test's initial `WEATHEROS` assertion
     is shared by loading and loaded views and therefore does not prove the
     loading half of the transition.
   - `evidencePointer:`
     `/Users/eli/weather_os/output/playwright/weatheros-safari-expanded.jpeg`,
     `/Users/eli/weather_os/output/playwright/weatheros-safari-accessible.jpeg`,
     `/Users/eli/weather_os/test/widget_test.dart:15`

2. `violatedCriterion: safari-accessibility-text-order`
   - Observation: No Safari accessibility-tree dump, VoiceOver transcript, or
     equivalent browser-runtime artifact exists. The JPEGs can prove visual
     order only. The Flutter test finds semantic labels but validates order via
     widget y-coordinates, not Safari semantic traversal.
   - `evidencePointer:`
     `/Users/eli/weather_os/output/playwright/weatheros-safari-accessible.jpeg`,
     `/Users/eli/weather_os/test/weather_accessibility_test.dart:48`

## Success criteria review

- `no-clipping-overlap`: PASS. All requested goldens are composed without
  overflow indicators, accidental crop, or component overlap; tests reproduce
  them without render exceptions.
- `compact-vs-expanded-composition`: PASS. Compact is centered and stacked;
  expanded is a left/right observatory layout.
- `hourly-scroll-affordance`: PASS. The compact Android capture exposes a
  clipped next forecast cell at the right edge, and production uses a
  horizontal `ListView` when cells do not fit.
- `metrics-reachability`: PASS. The 320x640 scroll test reaches PRESSURE and the
  lower golden visibly includes all four metrics.
- `one-lens`: PASS. Production has one `GlassLens` composition call, in
  `HourlyForecastRail`.
- `full-atmosphere`: PASS. The atmosphere paints every requested viewport,
  including the lower part of the expanded frame.
- `motion-difference-no-layout-motion`: PASS. Start and mid goldens differ in
  atmospheric detail while hero, rail, and metric geometry remain fixed. The
  hero reveal has completed by the 800 ms first frame; production does not
  animate layout properties.
- `loading-to-loaded-runtime-evidence`: FAIL. Required real runtime evidence is
  absent.
- `safari-accessibility-text-order`: FAIL. Required Safari runtime accessibility
  evidence is absent.

## Direct remove-ai-slops and programming pass

- No deletion-only tests, removal-verification tests, prompt/prose pins,
  expected-value self-derivation, unnecessary parsers, or normalization layers
  were found.
- Golden tests cover distinct viewport and animation outcomes and are not
  redundant.
- `widget_test.dart` gives false confidence specifically for loading evidence:
  `WEATHEROS` exists in both loading and loaded states, so its initial assertion
  does not distinguish the transition.
- NOTE: `atmospheric_clouds.dart` has 288 nonblank/non-comment lines, above the
  skill's preferred 250-line ceiling. This is maintenance debt but does not
  violate a stated product criterion.

## Checked artifact paths

- `/Users/eli/weather_os/DESIGN.md`
- all current source under `/Users/eli/weather_os/lib/`
- `/Users/eli/weather_os/test/visual/home_golden_test.dart`
- `/Users/eli/weather_os/test/weather_accessibility_test.dart`
- `/Users/eli/weather_os/test/weather_provider_test.dart`
- `/Users/eli/weather_os/test/widget_test.dart`
- `/Users/eli/weather_os/test/visual/goldens/home_compact_ios.png`
- `/Users/eli/weather_os/test/visual/goldens/home_compact_android.png`
- `/Users/eli/weather_os/test/visual/goldens/home_medium.png`
- `/Users/eli/weather_os/test/visual/goldens/home_expanded.png`
- `/Users/eli/weather_os/test/visual/goldens/home_short_lower.png`
- `/Users/eli/weather_os/test/visual/goldens/home_motion_start.png`
- `/Users/eli/weather_os/test/visual/goldens/home_motion_mid.png`
- `/Users/eli/weather_os/output/playwright/weatheros-safari-accessible.jpeg`
- `/Users/eli/weather_os/output/playwright/weatheros-safari-expanded.jpeg`
- available prior reports under `/Users/eli/weather_os/.omo/evidence/`

## Reproduced evidence

- `flutter analyze`: PASS, no issues.
- `flutter test --reporter expanded`: PASS, 21 tests, 0 failures.
- Direct visual inspection: seven requested PNGs and two Safari JPEGs.
- Direct source search: one production `GlassLens` call site.

## Exact evidence gaps

- Missing real Safari loading-state capture or video/trace that visibly proves
  loading followed by loaded content.
- Missing Safari accessibility-tree dump, VoiceOver transcript, or equivalent
  runtime artifact proving conditions -> hourly forecast -> metrics traversal.
- No Git metadata is present, so changed-file diff provenance is unavailable.
- No executor report, separate code-review report, manual-QA matrix, or notepad
  path was supplied. Prior evidence reports were inspected; direct review covers
  code/slop quality but cannot replace the two missing runtime artifacts above.
