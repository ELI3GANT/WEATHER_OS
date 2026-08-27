# WeatherOS Design System

## 0. Research Log

- Embedded refs: shortlisted Apple, Linear, and Runway; picked `soft-skill.md` + `apple.md` because WeatherOS needs cinematic atmosphere with Apple-like editorial restraint rather than dashboard density.
- Lazyweb: 3 mobile queries, 6 screens downloaded, 4 screens viewed; retained the proven hierarchy of current conditions first, high/low and feels-like second, one uninterrupted hourly rail third, and compact secondary metrics last. Rejected upsells, ads, news, bottom navigation, and card-stack density.
- Interaction reference: read beui.dev `shader-background` and `number`; retained a state-driven animated atmosphere that freezes under reduced motion and a one-time temperature reveal that resolves immediately under reduced motion.
- UI/UX database: checked a premium dark weather system plus Flutter layout/accessibility guidance; retained semantic color tokens, `LayoutBuilder`, `Semantics`, 44-48 dp targets, and a single dominant animation region. Rejected the suggested light palette and generic Inter typography because they conflict with the brief.
- Imagen drafts: `design/references/weatheros-concept-a.png`, `weatheros-concept-b.png`, and `weatheros-concept-c.png`; picked `weatheros-concept-b.png` as the art-direction contract for its asymmetrical hero, uninterrupted storm field, and single optical forecast lens. Concept C informs the centered compact-phone fallback.
- Distinctive direction: WeatherOS is a storm observatory cut from smoked optical glass. A living atmospheric field surrounds a monumental temperature, while one precisely machined forecast lens crosses the scene at the weather horizon.

## 1. Atmosphere & Identity

WeatherOS should feel like opening a quiet instrument pointed at the sky: immediate, calm, and cinematic. Current conditions are never placed inside a dashboard card; they inhabit the background itself. The signature is the **weather horizon**: moving atmospheric light and precipitation behind a very large temperature, terminating in one curved optical lens for the hourly forecast.

Design principles:

1. **Conditions before controls**: the user learns what it feels like outside before seeing secondary data.
2. **One weather field**: cards never fragment the hero atmosphere.
3. **Optical, not ornamental glass**: glass exists only to make forecast data readable over motion.
4. **Quiet precision**: typography and spacing carry hierarchy; accents remain rare.
5. **Adaptive calm**: text scaling, reduced motion, screen readers, and compact layouts retain the same information order.

## 2. Color

V1 is intentionally dark-only. Tokens map to `WeatherPalette`; raw component colors are not permitted.

| Role | Dart token | Hex | Usage |
|---|---|---:|---|
| Canvas/deep | `canvasDeep` | `#02070C` | OLED base and system chrome |
| Canvas/navy | `canvasNavy` | `#06111B` | Primary atmospheric field |
| Surface/lens | `lensCore` | `#0C1B29` | Forecast optical lens |
| Surface/lens bright | `lensLift` | `#173047` | Lens top sheen and cloud core |
| Surface/rim | `lensRim` | `#9DDBFF` | Sparse optical rim highlight |
| Text/primary | `textPrimary` | `#F6FAFF` | Temperature and primary data |
| Text/secondary | `textSecondary` | `#B7C5D3` | Condition, labels, units |
| Text/tertiary | `textTertiary` | `#7C91A4` | Supporting metadata |
| Accent/mist | `mistBlue` | `#67C9FF` | Active hour and weather light |
| Accent/amber | `horizonAmber` | `#E49A5D` | Distant warm horizon only |
| Accent/violet | `stormViolet` | `#6D5DAA` | Storm shadow and lightning fringe |
| Status/error | `error` | `#FF7979` | Error message and retry focus |
| Status/success | `success` | `#64DDAE` | Future success state |

Rules:

- `textPrimary` and `textSecondary` maintain readable contrast over the darkest lens stop; atmospheric glow never sits directly behind body copy without a tonal scrim.
- `mistBlue` indicates the current hour or focus, not generic decoration.
- `horizonAmber` occupies less than five percent of the visible scene.
- Condition-specific palettes are variants of this ramp: rain uses mist blue, sunny adds amber, storm adds violet, and cloudy reduces saturation.

## 3. Typography

Primary family is **Barlow**, bundled as static weights to avoid runtime font fetching and variable-font rasterization differences across Flutter targets. Its narrow, engineered forms reinforce the observatory identity without looking like a default system dashboard. Tabular figures are enabled for weather values. Platform font fallback is allowed only if the bundled font fails to load.

| Level | Compact | Expanded | Weight | Line height | Tracking | Usage |
|---|---:|---:|---:|---:|---:|---|
| Temperature | 128 | 148 | 300 | 0.82 | -3.2 | Current temperature hero |
| Display | 40 | 52 | 500 | 1.02 | -1.2 | Empty/error statement |
| Title | 28 | 32 | 500 | 1.15 | -0.4 | Location and section focus |
| Condition | 24 | 28 | 500 | 1.2 | -0.2 | Weather condition |
| Metric value | 24 | 28 | 400 | 1.1 | -0.2 | Secondary weather values |
| Body | 16 | 18 | 400 | 1.45 | 0 | Feels-like and supporting text |
| Label | 13 | 14 | 500 | 1.25 | 0.6 | Forecast times and metric labels |
| Overline | 11 | 12 | 600 | 1.25 | 2.2 | WeatherOS and location metadata |

Rules:

- Body text never renders below 14 logical pixels after scaling.
- The temperature is allowed to scale down on short devices, never clip.
- Labels may wrap only where their component explicitly supports it; core weather values remain on one line.

## 4. Spacing & Layout

Base unit: **4 dp**.

| Token | Value | Intent |
|---|---:|---|
| `space1` | 4 | Optical micro-alignment |
| `space2` | 8 | Icon-to-label and compact gaps |
| `space3` | 12 | Forecast item rhythm |
| `space4` | 16 | Compact screen gutter |
| `space5` | 20 | Comfortable inset |
| `space6` | 24 | Default screen gutter and lens padding |
| `space8` | 32 | Section separation |
| `space10` | 40 | Hero internal rhythm |
| `space12` | 48 | Major compact break |
| `space16` | 64 | Expanded scene break |

Primitive geometry and optical material are also centralized in
`WeatherLayout` and `WeatherOptics`: the forecast rail is 128 dp tall with
32 dp glyphs and 20 dp values; its current marker is 22 x 2 dp; metric dividers
are 1 x 72 dp at 16 percent opacity; optical borders are 1 dp; the compact and
expanded temperature caps are 128 and 148 dp. Lens rim, lift, core, base,
highlight, shadow opacity, blur, and offset values are tokens rather than
component-local constants. Weather glyph sizes are named for default (44 dp),
hero (40 dp), forecast (32 dp), specimen (28 dp), and metric (28 dp) contexts.

Responsive contract:

- **Compact**: `< 600 dp`, single vertical scene, 20 dp gutters, centered temperature on very narrow devices and restrained asymmetry when width permits.
- **Medium**: `600-899 dp`, centered max-width 760 dp; hero and detail band gain wider internal gutters.
- **Expanded**: `>= 900 dp`, max content width 1080 dp; conditions occupy the left observatory field while forecast and metrics form a right-side instrument stack.
- Portrait and landscape both use `SafeArea`. Primary content never hides beneath system regions.
- Hourly forecasts own their horizontal scroll. The page owns vertical scroll. No other nested scroll regions exist.

## 5. Components

### Atmosphere Backdrop

- **Structure**: fixed `RepaintBoundary` + condition-aware `CustomPainter` behind the entire route.
- **Variants**: rain, sunny, storm, cloudy.
- **States**: animated; frozen reduced-motion; static screenshot/test frame.
- **Accessibility**: decorative and excluded from semantics; all weather meaning is repeated in text.
- **Motion**: slow cloud translation plus condition-specific precipitation, glow, or lightning. Motion never blocks input.
- **Layout**: viewport fill.

### Glass Lens

- **Structure**: outer rim shell, small optical gap, inner tinted core and top sheen.
- **Variants**: standard and quiet.
- **States**: default; current-hour selection; pressed/focused only when a future interactive variant exists.
- **Accessibility**: content contrast remains valid without transparency.
- **Motion**: none; it stabilizes moving content rather than adding motion.
- **Layout**: bounded stack surface, never nested inside another lens.

### Weather Glyph

- **Structure**: token-sized custom vector painter.
- **Variants**: rain, sunny, storm, cloudy.
- **States**: current and forecast; no standalone interaction.
- **Accessibility**: excluded from semantics when adjacent text already names the condition.
- **Motion**: none.

### Current Conditions Hero

- **Structure**: brand overline, location, monumental temperature, condition glyph, condition, feels-like, and high/low.
- **Variants**: compact centered and expanded asymmetrical.
- **States**: populated only; loading and error are owned by the route.
- **Accessibility**: one merged summary announces location, temperature, condition, feels-like, high, and low.
- **Motion**: one-time temperature reveal; resolves immediately when reduced motion is enabled.

### Hourly Forecast Rail

- **Structure**: one horizontal optical lens containing forecast cells.
- **Variants**: compact scroll and expanded fit.
- **States**: current hour highlighted by luminance, text weight, and a small baseline marker; future hours quiet.
- **Accessibility**: each cell announces time, temperature, and condition; 48 dp minimum hit/reading area.
- **Motion**: native horizontal scroll only.

### Weather Metric Strip

- **Structure**: one typographic strip with four equally weighted metrics and restrained vertical dividers.
- **Variants**: horizontal compact and 2x2 narrow fallback.
- **States**: populated only.
- **Accessibility**: each metric announces label, value, and unit; color does not carry meaning.
- **Motion**: none.

### Weather State View

- **Structure**: centered label and optional retry action.
- **Variants**: loading, error, empty.
- **States**: retry has default, focused, pressed, disabled, and loading states.
- **Accessibility**: live status announcement and explicit retry label.
- **Motion**: loading uses an opacity pulse; reduced motion uses a static progress indicator.

## 6. Motion & Interaction

| Token | Value | Usage |
|---|---|---|
| `micro` | 140 ms | Press and focus feedback |
| `standard` | 260 ms | Content crossfade |
| `emphasis` | 720 ms | Temperature reveal |
| `weatherCycle` | 18 s | Ambient cloud/rain loop |
| `enterCurve` | `easeOutCubic` | Content arrival |
| `pressCurve` | `easeOutBack` | Future interactive lens press |

- The beui.dev shader-background mechanism maps to one variant-driven painter and one speed value. Reduced motion freezes the controller at a stable frame.
- The beui.dev number mechanism maps to a one-time, interruptible temperature tween from 94 percent scale and 0 opacity to rest. The value itself never counts from zero because weather is not a scoreboard.
- Ambient rain, cloud, sun, and lightning indicate the current weather state and are the one signature animation region.
- No layout properties animate. Repaint work is isolated behind `RepaintBoundary`.

## 7. Depth & Surface

Strategy: **mixed tonal shift plus optical rim**.

| Level | Recipe | Usage |
|---|---|---|
| Field | multi-stop vertical/radial atmospheric gradient | Full viewport |
| Mist | irregular luminous billows over blurred contour planes | Clouds and rain depth |
| Lens shell | 1 dp luminous rim at low opacity + outer navy tint | Forecast boundary |
| Lens core | navy gradient + inset top sheen + faint lower shadow | Forecast and metrics readability |
| Focus | mist-blue luminance + 2 dp baseline marker | Current hour |

The surface must still read correctly if transparency is reduced. No generic gray border or heavy black shadow is permitted.

## 8. Accessibility Constraints & Accepted Debt

### Constraints

- Target WCAG 2.2 AA-equivalent contrast: 4.5:1 body text, 3:1 large text and glyphs.
- Minimum touch target: 48 dp on Android and at least 44 pt on iOS.
- Supports system text scaling without clipping core conditions or metrics.
- `MediaQuery.disableAnimations` freezes ambient weather and removes the temperature reveal.
- Screen-reader order follows the visual narrative: location and conditions, hourly forecast, metrics.
- Weather meaning is always present as text; visuals and color are supplemental.
- Compact width, tablet, expanded desktop, portrait, and landscape must remain operable without primary horizontal overflow.

### Inclusive Personas

- **Maya, one-handed commuter**: reads the current condition and next three hours quickly on a compact phone in rain.
- **Noah, low-vision planner**: uses larger text and high screen brightness; core temperature and metrics must not clip or rely on low-contrast glass.
- **Rin, motion-sensitive user**: has reduced motion enabled; receives a static but equally atmospheric scene.
- **Sam, screen-reader user**: hears a concise weather summary followed by chronological forecast cells and explicit metric units.

### Accepted Debt

| Item | Location | Why accepted | Owner / Exit |
|---|---|---|---|
| None | - | V1 foundation carries no accepted accessibility debt. | - |

## 9. App Icon & Store Identity System

### 9.1 Concept: The Weather Core

The WeatherOS app icon is a dark atmospheric smoked glass sphere set against an obsidian black field. Inside the translucent sphere lives a living weather core:
- **Electric cyan lightning filament**: `mistBlue` (`#67C9FF`)
- **Ambient storm mist and volumetric depth**: `canvasNavy` (`#06111B`)
- **Warm solar horizon amber rim accent**: `horizonAmber` (`#E49A5D`)
- **Smoked optical glass rim highlight**: `lensRim` (`#9DDBFF`)

### 9.2 Icon Asset Matrix

- **iOS App Icon**: 1024x1024 master, 180x180 (iPhone 3x), 120x120 (iPhone 2x), 167x167 (iPad Pro), 152x152 (iPad 2x), 76x76 (iPad 1x), 87x87, 58x58, 40x40, 20x20.
- **Android Mipmaps**: `mipmap-mdpi` (48x48), `mipmap-hdpi` (72x72), `mipmap-xhdpi` (96x96), `mipmap-xxhdpi` (144x144), `mipmap-xxxhdpi` (192x192).
- **Web & Desktop**: `favicon.png` (32x32), `Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`, macOS AppIcon set (16 to 1024 px).

### 9.3 Launch Screen Contract

- **OLED Black Splash**: Eliminates white flashes on app launch. The native window background is pinned to OLED canvas `#02070C` on iOS (`LaunchScreen.storyboard`), Android (`launch_background.xml` & `styles.xml`), and Web.
- **Centered Observatory Mark**: Optical weather glyph appears centered at rest, cross-fading seamlessly into the interactive `WeatherHomeScreen`.
