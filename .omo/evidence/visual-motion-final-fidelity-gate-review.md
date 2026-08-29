# WeatherOS final visual/motion fidelity gate

- recommendation: REJECT (REVISE)
- originalIntent: Ship final WeatherOS golden artifacts with complete, coherent layouts and deterministic motion-frame coverage.
- desiredOutcome: Both Home motion PNGs show the same complete foreground while only the atmospheric environment changes; motion tests are isolated and repeatable; storm fixture/rendering is coherent; prior compact and accessibility layout fixes remain intact.

## Blockers

1. `violatedCriterion`: `MOTION-FOREGROUND-COMPLETE-AND-ENVIRONMENT-ONLY`
   - Observation: `home_motion_mid.png` has the foreground translated left and clipped. The location/header, temperature, condition, summary copy, hourly labels, and several daily rows lose their left portions. `home_motion_start.png` contains the complete foreground. Therefore the pair changes foreground geometry/content in addition to the environment.
   - `evidencePointer`: `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_start.png`; `/Users/eli/OTP/weather_os/test/visual/goldens/home_motion_mid.png`; mid capture timing at `/Users/eli/OTP/weather_os/test/visual/home_motion_golden_test.dart:85`; golden assertion at `/Users/eli/OTP/weather_os/test/visual/home_motion_golden_test.dart:88`.

## User outcome review

The motion deliverable is not ready from the user's perspective. The start frame is visually complete, but the mid frame visibly damages the foreground rather than changing only rain/cloud atmosphere. This is a direct requested-outcome failure.

The tests are isolated at the file/test-run level and deterministic in fresh reproduction: the start test passed alone once, and the mid test passed alone twice. Those green results do not clear the blocker because the committed mid golden is a broken oracle. This is the direct remove-ai-slops/overfit finding: the image snapshot faithfully approves the defect it was meant to prevent, creating false confidence.

Storm data is coherent in the inspected fixture/render: the storm test requires the first six hourly conditions and first daily condition to be storm, verifies the storm semantics label, and `showcase_storm.png` consistently shows 65 F, Storm, 59 F feels-like, 68/57 high-low, lightning icons, severe-thunderstorm copy, and high risk.

Prior layout fixes appear intact in the inspected artifacts: compact Android's noon column remains inside the forecast rail; compact/medium/expanded Home and Showcase layouts are composed; short/lower and large-text/lower captures keep the intended lower content reachable. These are non-blocking confirmations and do not offset the motion blocker.

## Checked artifacts

- `/Users/eli/OTP/weather_os/test/visual/home_golden_test.dart`
- `/Users/eli/OTP/weather_os/test/visual/home_motion_golden_test.dart`
- `/Users/eli/OTP/weather_os/test/visual/showcase_golden_test.dart`
- `/Users/eli/OTP/weather_os/lib/features/weather/models/mock_weather.dart`
- Every PNG under `/Users/eli/OTP/weather_os/test/visual/goldens/` (16 files at review time)
- Direct programming and remove-ai-slops pass over the scoped test code and production fixture references

## Reproduced commands

- `flutter test test/visual/home_golden_test.dart --plain-name 'ambient weather renders the start motion frame'` -> PASS
- `flutter test test/visual/home_motion_golden_test.dart --plain-name 'ambient weather renders the mid motion frame in isolation'` -> PASS
- Repeated the isolated mid command -> PASS

## Evidence gaps and notes

- `omo ulw-loop status --json` was unavailable because `omo` is not installed/on PATH, so this report uses the required fallback evidence path.
- No executor report, code-review report, manual-QA matrix, or notepad path was supplied to this child gate. Direct artifact inspection and reproduction were sufficient to prove the blocker.
- Programming/slop note: duplicating the Home pump/provider setup across the two motion files is maintenance duplication, but it is not itself a stated-criterion blocker. The blocking false-confidence issue is the golden asserting a visibly incomplete mid foreground.
