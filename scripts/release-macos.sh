#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: release-macos.sh [options]

Builds a signed Release archive, exports a Developer ID app, notarizes it,
staples the notarization ticket, and produces a GitHub Releases-ready zip.

Options:
  --project PATH                 Xcode project path. Default: ./Caffeinate.xcodeproj
  --scheme NAME                 Xcode scheme. Default: Caffeinate
  --configuration NAME          Build configuration. Default: Release
  --team-id ID                  Apple Developer Team ID. Defaults to project setting.
  --notary-profile NAME         notarytool keychain profile name.
  --signing-style STYLE         Export signing style: automatic or manual. Default: automatic
  --signing-certificate NAME    Manual export signing certificate override.
  --output-root PATH            Output directory root. Default: ./dist/release
  --allow-provisioning-updates  Pass -allowProvisioningUpdates to xcodebuild.
  --skip-notarization           Build/export/package, but skip notary submission and stapling.
  -h, --help                    Show this help.

Environment:
  TEAM_ID, NOTARY_PROFILE, SIGNING_STYLE, SIGNING_CERTIFICATE, OUTPUT_ROOT

Examples:
  NOTARY_PROFILE=CaffeinateNotary ./scripts/release-macos.sh
  ./scripts/release-macos.sh --team-id 6RX8GEVB43 --notary-profile CaffeinateNotary
EOF
}

fail() {
  echo "error: $*" >&2
  exit 1
}

log() {
  echo "==> $*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

project_setting() {
  local key="$1"

  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -showBuildSettings 2>/dev/null \
    | sed -n "s/^[[:space:]]*${key} = //p" \
    | head -n 1 \
    | tr -d '\r'
}

write_export_options() {
  {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>${SIGNING_STYLE}</string>
  <key>stripSwiftSymbols</key>
  <true/>
EOF
    if [[ -n "$TEAM_ID" ]]; then
      cat <<EOF
  <key>teamID</key>
  <string>${TEAM_ID}</string>
EOF
    fi
    if [[ -n "$SIGNING_CERTIFICATE" ]]; then
      cat <<EOF
  <key>signingCertificate</key>
  <string>${SIGNING_CERTIFICATE}</string>
EOF
    fi
    cat <<'EOF'
</dict>
</plist>
EOF
  } >"$EXPORT_OPTIONS_PLIST"
}

write_release_metadata() {
  {
    printf 'RELEASE_DIR=%q\n' "$RELEASE_DIR"
    printf 'APP_NAME=%q\n' "$APP_NAME"
    printf 'APP_PATH=%q\n' "$APP_PATH"
    printf 'VERSION=%q\n' "$VERSION"
    printf 'BUILD_NUMBER=%q\n' "$BUILD_NUMBER"
    printf 'ARTIFACT_BASENAME=%q\n' "$ARTIFACT_BASENAME"
    printf 'PRE_NOTARY_ZIP=%q\n' "$PRE_NOTARY_ZIP"
    printf 'FINAL_ZIP=%q\n' "$FINAL_ZIP"
    printf 'CHECKSUM_PATH=%q\n' "$CHECKSUM_PATH"
    printf 'ARCHIVE_PATH=%q\n' "$ARCHIVE_PATH"
    printf 'EXPORT_DIR=%q\n' "$EXPORT_DIR"
    printf 'NOTARY_SUBMISSION_JSON=%q\n' "$NOTARY_SUBMISSION_JSON"
    printf 'NOTARY_LOG_JSON=%q\n' "$NOTARY_LOG_JSON"
    printf 'RELEASE_TAG=%q\n' "$RELEASE_TAG"
    printf 'RELEASE_TITLE=%q\n' "$RELEASE_TITLE"
  } >"$RELEASE_METADATA_PATH"
}

PROJECT_PATH=""
SCHEME="Caffeinate"
CONFIGURATION="Release"
TEAM_ID="${TEAM_ID:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
SIGNING_STYLE="${SIGNING_STYLE:-automatic}"
SIGNING_CERTIFICATE="${SIGNING_CERTIFICATE:-}"
OUTPUT_ROOT="${OUTPUT_ROOT:-}"
ALLOW_PROVISIONING_UPDATES=0
SKIP_NOTARIZATION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --scheme)
      SCHEME="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    --signing-style)
      SIGNING_STYLE="$2"
      shift 2
      ;;
    --signing-certificate)
      SIGNING_CERTIFICATE="$2"
      shift 2
      ;;
    --output-root)
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --allow-provisioning-updates)
      ALLOW_PROVISIONING_UPDATES=1
      shift
      ;;
    --skip-notarization)
      SKIP_NOTARIZATION=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/Caffeinate.xcodeproj}"
OUTPUT_ROOT="${OUTPUT_ROOT:-${REPO_ROOT}/dist/release}"

[[ -d "$PROJECT_PATH" ]] || fail "Project not found: $PROJECT_PATH"
[[ "$SIGNING_STYLE" == "automatic" || "$SIGNING_STYLE" == "manual" ]] || fail "Unsupported signing style: $SIGNING_STYLE"

require_command xcodebuild
require_command xcrun
require_command ditto
require_command codesign
require_command defaults
require_command shasum
require_command plutil

TEAM_ID="${TEAM_ID:-$(project_setting DEVELOPMENT_TEAM)}"
PRODUCT_NAME="$(project_setting PRODUCT_NAME)"
APP_NAME="${PRODUCT_NAME//\"/}"
APP_NAME="${APP_NAME//\$\(TARGET_NAME\)/$SCHEME}"

[[ -n "$TEAM_ID" ]] || fail "Could not determine DEVELOPMENT_TEAM. Pass --team-id."

if [[ $SKIP_NOTARIZATION -eq 0 && -z "$NOTARY_PROFILE" ]]; then
  fail "Set --notary-profile or NOTARY_PROFILE, or use --skip-notarization."
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RELEASE_DIR="${OUTPUT_ROOT}/${TIMESTAMP}"
ARCHIVE_PATH="${RELEASE_DIR}/${SCHEME}.xcarchive"
EXPORT_DIR="${RELEASE_DIR}/export"
EXPORT_OPTIONS_PLIST="${RELEASE_DIR}/ExportOptions.plist"
mkdir -p "$RELEASE_DIR"

write_export_options

log "Archiving ${SCHEME}"
ARCHIVE_CMD=(
  xcodebuild
  archive
  -project "$PROJECT_PATH"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "generic/platform=macOS"
  -archivePath "$ARCHIVE_PATH"
)
if [[ $ALLOW_PROVISIONING_UPDATES -eq 1 ]]; then
  ARCHIVE_CMD+=(-allowProvisioningUpdates)
fi
"${ARCHIVE_CMD[@]}"

log "Exporting Developer ID app"
EXPORT_CMD=(
  xcodebuild
  -exportArchive
  -archivePath "$ARCHIVE_PATH"
  -exportPath "$EXPORT_DIR"
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
)
if [[ $ALLOW_PROVISIONING_UPDATES -eq 1 ]]; then
  EXPORT_CMD+=(-allowProvisioningUpdates)
fi
"${EXPORT_CMD[@]}"

APP_PATH="$(find "$EXPORT_DIR" -maxdepth 1 -type d -name '*.app' -print -quit)"
[[ -n "$APP_PATH" ]] || fail "Export did not produce an .app in $EXPORT_DIR"

VERSION="$(defaults read "${APP_PATH}/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "0.0.0")"
BUILD_NUMBER="$(defaults read "${APP_PATH}/Contents/Info" CFBundleVersion 2>/dev/null || echo "0")"
ARTIFACT_BASENAME="${APP_NAME}-${VERSION}-${BUILD_NUMBER}-macos"
PRE_NOTARY_ZIP="${RELEASE_DIR}/${ARTIFACT_BASENAME}-for-notarization.zip"
FINAL_ZIP="${RELEASE_DIR}/${ARTIFACT_BASENAME}.zip"
CHECKSUM_PATH="${FINAL_ZIP}.sha256"
NOTARY_SUBMISSION_JSON="${RELEASE_DIR}/notary-submission.json"
NOTARY_LOG_JSON="${RELEASE_DIR}/notary-log.json"
RELEASE_TAG="v${VERSION}-${BUILD_NUMBER}"
RELEASE_TITLE="${APP_NAME} ${VERSION} (${BUILD_NUMBER})"
RELEASE_METADATA_PATH="${RELEASE_DIR}/release-metadata.env"

log "Verifying code signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

if [[ $SKIP_NOTARIZATION -eq 0 ]]; then
  log "Packaging app for notarization"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$PRE_NOTARY_ZIP"

  log "Submitting to Apple notarization service"
  xcrun notarytool submit \
    "$PRE_NOTARY_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait \
    --output-format json \
    >"$NOTARY_SUBMISSION_JSON"

  NOTARY_STATUS="$(plutil -extract status raw -o - "$NOTARY_SUBMISSION_JSON")"
  SUBMISSION_ID="$(plutil -extract id raw -o - "$NOTARY_SUBMISSION_JSON")"
  xcrun notarytool log \
    "$SUBMISSION_ID" \
    "$NOTARY_LOG_JSON" \
    --keychain-profile "$NOTARY_PROFILE" \
    >/dev/null

  [[ "$NOTARY_STATUS" == "Accepted" ]] || fail "Notarization status was ${NOTARY_STATUS}. See ${NOTARY_LOG_JSON}"

  log "Stapling notarization ticket"
  xcrun stapler staple -v "$APP_PATH"
  xcrun stapler validate -v "$APP_PATH"
else
  log "Skipping notarization and stapling"
fi

log "Creating release zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$FINAL_ZIP"
shasum -a 256 "$FINAL_ZIP" >"$CHECKSUM_PATH"
write_release_metadata

cat <<EOF

Release artifacts:
  App:      $APP_PATH
  Zip:      $FINAL_ZIP
  SHA-256:  $CHECKSUM_PATH
  Archive:  $ARCHIVE_PATH
  Metadata: $RELEASE_METADATA_PATH
EOF

if [[ $SKIP_NOTARIZATION -eq 0 ]]; then
  cat <<EOF
  Notary:   $NOTARY_SUBMISSION_JSON
  Log:      $NOTARY_LOG_JSON
EOF
fi

cat <<EOF

Upload ${FINAL_ZIP} and ${CHECKSUM_PATH} to your GitHub Release.
EOF
