# WeatherOS Frontend Design State

## Current Objective

Build the complete V1 WeatherOS UI foundation in Flutter with realistic mock data and a real code-rendered animated weather environment.

## Locked Decisions

- Direction: dark storm observatory with current conditions as the atmospheric hero.
- References: `soft-skill.md`, `apple.md`, Lazyweb weather screens, and `design/references/weatheros-concept-b.png`.
- Product screen is a real Flutter widget/painter tree. Generated references must never ship as a screenshot background.
- V1 is dark-only and contains no ads, upsells, radar, bottom navigation, or live network dependency.
- Motion freezes under the platform reduce-motion preference.

## Source Inputs

- User brief in the active conversation.
- `DESIGN.md` is the visual and interaction contract.
- Research concepts in `design/references/`.
- Lazyweb research remained temporary under `/tmp/weatheros-lazyweb.IlNbng` and is not product content.

## Design Brief

- Primary task: understand current conditions within seconds, then scan the next several hours.
- Information order: location and current conditions, feels/high/low, hourly forecast, secondary metrics.
- Tone: precise, calm, premium, cinematic, minimal.
- Anti-references: generic weather dashboard grids, ad-supported weather apps, multi-tab chrome, neon gradient blobs, card stacks, tiny labels.

## Inclusive Personas

- Maya: one-handed commuter on a compact phone; needs glanceable current and hourly weather.
- Noah: low vision and larger type; needs durable hierarchy and high contrast.
- Rin: motion-sensitive; needs a fully useful static scene.
- Sam: screen-reader user; needs a concise summary and chronological semantics.

## Adaptive Preferences

- Safe areas, screen text scaling, reduced motion, compact/medium/expanded layouts, portrait and landscape.
- Dark surface contrast is independently verified; color never carries weather meaning alone.

## Verification Matrix

- `flutter analyze` and changed-file diagnostics.
- Flutter unit/widget tests at compact and expanded sizes.
- iOS and Android production builds where the local toolchain permits.
- Real running Flutter surface captured at compact, medium, and expanded viewport sizes.
- Visual QA reviews the home route and primitive showcase on fresh captures.
- Persona, accessibility, heuristic, and implementation reviews use the same final build.

## Design Debt Register

No accepted debt. Store/package identifiers remain a release-phase owner decision, not hidden UI debt.

## Evidence Index

- Concept references: `design/references/weatheros-concept-a.png`, `weatheros-concept-b.png`, `weatheros-concept-c.png`.
- Build, test, capture, and review evidence will be added after implementation.

## Handoff Notes

- Implement tokens before components.
- Primitive showcase must render successfully before composing the product route.
- Keep generated references as research only.
