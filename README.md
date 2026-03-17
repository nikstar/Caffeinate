# Caffeinate
Caffeinate is a fresh take on a status bar app that prevents your computer from going to sleep

## Installation
You can download the latest stable version from [Releases](https://github.com/nikstar/Caffeinate/releases). 

For the app to launch at startup, you will need to add it to *System Preferences → Users & Groups → Login Items*. The app will preserve its state across launches.

## Building from source
1. Open `Caffeinate.xcodeproj` in Xcode 26 or newer.
2. Build the `Caffeinate` scheme.

## Manual Release
For a signed, notarized GitHub Release build you need:

1. An active Apple Developer Program membership.
2. A `Developer ID Application` certificate installed in your login keychain.
3. Xcode signed into the same team that will ship the app.
4. A notarytool keychain profile created once on your machine.

Apple references:
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

Recommended one-time setup with an Apple ID app-specific password:

```bash
xcrun notarytool store-credentials CaffeinateNotary \
  --apple-id "you@example.com" \
  --team-id "YOURTEAMID" \
  --password "app-specific-password"
```

You can also store an App Store Connect API key profile instead.

Release helper:

```bash
NOTARY_PROFILE=CaffeinateNotary ./scripts/release-macos.sh
```

The helper will:
1. Archive the app in `Release`.
2. Export a `developer-id` signed `.app`.
3. Submit a zip to Apple notarization.
4. Staple the accepted ticket.
5. Produce a final GitHub Releases-ready zip plus a SHA-256 file in `dist/release/`.
6. Write `release-metadata.env` so the GitHub release step can reuse the exact artifact paths and tag/title defaults.

## Versioning
Current version metadata lives in `Caffeinate/Info.plist`.

Inspect the current version:

```bash
./scripts/set-version.sh --print
```

Set a new marketing version and build number:

```bash
./scripts/set-version.sh 1.1.0 --build 1
```

Or bump them incrementally:

```bash
./scripts/set-version.sh --patch
./scripts/set-version.sh --bump-build
```

## GitHub Release
Authenticate the GitHub CLI once on your machine:

```bash
gh auth login
```

After `release-macos.sh` finishes, publish the newest notarized artifact as a GitHub Release:

```bash
./scripts/create-github-release.sh
```

By default this will:
1. Pick the latest directory under `dist/release/`.
2. Use tag `v<marketing-version>-<build-number>`.
3. Create and push that tag from your current `HEAD` if it does not already exist.
4. Run `gh release create --verify-tag` with the zip and `.sha256` file.

Useful overrides:

```bash
./scripts/create-github-release.sh --draft
./scripts/create-github-release.sh --release-dir dist/release/20260317-140741
./scripts/create-github-release.sh --notes "Manual release"
```
