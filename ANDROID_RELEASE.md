# WeatherOS Android release

The `Android Release` GitHub Actions workflow is the canonical Android release
path. It runs on x86_64 because Flutter does not currently ship all Android AOT
host artifacts required for release builds on Linux ARM64.

## Release guarantees

- Flutter `3.47.2` and Java `17` are pinned.
- Android API `36` and build tools `36.0.0` are installed explicitly.
- Static analysis and all Flutter tests must pass on the pinned x86_64 runner.
- The AAB must be signed with the registered WeatherOS upload key.
- The upload certificate SHA-256 must match the expected Play Console value.
- The generated AAB must target API `36` and use `app.weatheros.app`.
- Every successful build retains the AAB and its SHA-256 digest for 30 days.
- Automated publishing is limited to the `internal`, `alpha`, and `beta`
  tracks. Production promotion is intentionally not available in this workflow.

## Required GitHub Actions secrets

- `ANDROID_KEYSTORE_BASE64`: base64 of the existing WeatherOS upload keystore.
- `ANDROID_KEY_ALIAS`: alias of its upload key.
- `ANDROID_KEY_PASSWORD`: upload key password.
- `ANDROID_STORE_PASSWORD`: keystore password.
- `ANDROID_UPLOAD_CERT_SHA256`: SHA-256 shown in Play Console under app signing.
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: service-account JSON with release access.
  This is required only when `publish_to_play` is enabled.

The existing upload key must be used. Do not generate a replacement unless an
upload-key reset has first been completed in Google Play Console.

## Run a release

1. Increase `version` in `pubspec.yaml`; its build number must exceed the latest
   version code already uploaded to Google Play.
2. Push the reviewed commit to the repository.
3. Run `Android Release` from GitHub Actions.
4. Leave `publish_to_play` off for an artifact-only release candidate, or enable
   it and choose a non-production track.
5. Review Play Console's automated checks and pre-launch report before any
   separate production promotion.

iOS signing, building, submission, and version changes are outside this Android
workflow and remain frozen while the current App Store submission is in review.
