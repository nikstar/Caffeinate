#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: create-github-release.sh [options]

Creates a GitHub Release from a release directory produced by release-macos.sh.
If the Git tag does not exist on origin, the script creates an annotated tag from
the chosen target ref, pushes it, and then calls gh release create --verify-tag.

Options:
  --release-dir PATH       Specific dist/release/<timestamp> directory. Default: latest.
  --release-root PATH      Release directory root. Default: ./dist/release
  --repo OWNER/REPO        Repository override for gh release create.
  --tag NAME               Release tag override. Default: v<version>-<build>
  --title TITLE            Release title override. Default: <App> <version> (<build>)
  --target REF             Git ref/commit to tag. Default: HEAD
  --notes TEXT             Additional release notes text.
  --notes-file PATH        Release notes file. Disables generated notes unless explicitly re-enabled.
  --generate-notes         Enable generated release notes.
  --no-generate-notes      Disable generated release notes.
  --draft                  Create the release as a draft.
  --prerelease             Mark the release as a prerelease.
  --fail-on-no-commits     Pass through to gh release create.
  --dry-run                Print resolved inputs without creating a tag or release.
  -h, --help               Show this help.

Examples:
  ./scripts/create-github-release.sh
  ./scripts/create-github-release.sh --release-dir dist/release/20260317-140741
  ./scripts/create-github-release.sh --draft --notes "Manual release"
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

latest_release_dir() {
  local root="$1"

  find "$root" -mindepth 1 -maxdepth 1 -type d -print | sort | tail -n 1
}

find_final_zip() {
  local dir="$1"

  find "$dir" -maxdepth 1 -type f -name '*-macos.zip' ! -name '*-for-notarization.zip' -print | sort | head -n 1
}

read_app_info_value() {
  local app_path="$1"
  local key="$2"

  plutil -extract "$key" raw -o - "${app_path}/Contents/Info.plist" 2>/dev/null || true
}

parse_artifact_name() {
  local artifact_path="$1"
  local artifact_name

  artifact_name="$(basename "$artifact_path" .zip)"
  if [[ "$artifact_name" =~ ^(.+)-([0-9]+(\.[0-9]+){0,2})-([0-9]+)-macos$ ]]; then
    APP_NAME="${APP_NAME:-${BASH_REMATCH[1]}}"
    VERSION="${VERSION:-${BASH_REMATCH[2]}}"
    BUILD_NUMBER="${BUILD_NUMBER:-${BASH_REMATCH[4]}}"
  fi
}

RELEASE_DIR=""
RELEASE_ROOT=""
REPO=""
TAG=""
TITLE=""
TARGET_REF="HEAD"
NOTES=""
NOTES_FILE=""
GENERATE_NOTES=1
GENERATE_NOTES_SET=0
DRAFT=0
PRERELEASE=0
FAIL_ON_NO_COMMITS=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-dir)
      RELEASE_DIR="$2"
      shift 2
      ;;
    --release-root)
      RELEASE_ROOT="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --tag)
      TAG="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --target)
      TARGET_REF="$2"
      shift 2
      ;;
    --notes)
      NOTES="$2"
      shift 2
      ;;
    --notes-file)
      NOTES_FILE="$2"
      shift 2
      ;;
    --generate-notes)
      GENERATE_NOTES=1
      GENERATE_NOTES_SET=1
      shift
      ;;
    --no-generate-notes)
      GENERATE_NOTES=0
      GENERATE_NOTES_SET=1
      shift
      ;;
    --draft)
      DRAFT=1
      shift
      ;;
    --prerelease)
      PRERELEASE=1
      shift
      ;;
    --fail-on-no-commits)
      FAIL_ON_NO_COMMITS=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
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
RELEASE_ROOT="${RELEASE_ROOT:-${REPO_ROOT}/dist/release}"

[[ -d "$RELEASE_ROOT" ]] || fail "Release root not found: $RELEASE_ROOT"

if [[ -z "$RELEASE_DIR" ]]; then
  RELEASE_DIR="$(latest_release_dir "$RELEASE_ROOT")"
fi

[[ -n "$RELEASE_DIR" && -d "$RELEASE_DIR" ]] || fail "Could not find a release directory under $RELEASE_ROOT"

METADATA_PATH="${RELEASE_DIR}/release-metadata.env"
if [[ -f "$METADATA_PATH" ]]; then
  # shellcheck disable=SC1090
  source "$METADATA_PATH"
fi

APP_PATH="${APP_PATH:-}"
APP_NAME="${APP_NAME:-}"
VERSION="${VERSION:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
FINAL_ZIP="${FINAL_ZIP:-}"
CHECKSUM_PATH="${CHECKSUM_PATH:-}"
RELEASE_TAG="${RELEASE_TAG:-}"
RELEASE_TITLE="${RELEASE_TITLE:-}"

if [[ -z "$APP_PATH" ]]; then
  APP_PATH="$(find "${RELEASE_DIR}/export" -maxdepth 1 -type d -name '*.app' -print -quit 2>/dev/null || true)"
fi

if [[ -n "$APP_PATH" && -z "$APP_NAME" ]]; then
  APP_NAME="$(basename "$APP_PATH" .app)"
fi

if [[ -n "$APP_PATH" && -z "$VERSION" ]]; then
  VERSION="$(read_app_info_value "$APP_PATH" CFBundleShortVersionString)"
fi

if [[ -n "$APP_PATH" && -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER="$(read_app_info_value "$APP_PATH" CFBundleVersion)"
fi

if [[ -z "$FINAL_ZIP" ]]; then
  FINAL_ZIP="$(find_final_zip "$RELEASE_DIR")"
fi

[[ -n "$FINAL_ZIP" && -f "$FINAL_ZIP" ]] || fail "Could not find final release zip in $RELEASE_DIR"

parse_artifact_name "$FINAL_ZIP"

if [[ -z "$CHECKSUM_PATH" ]]; then
  CHECKSUM_PATH="${FINAL_ZIP}.sha256"
fi

[[ -f "$CHECKSUM_PATH" ]] || fail "Missing checksum file: $CHECKSUM_PATH"
[[ -n "$VERSION" ]] || fail "Could not determine app version from $RELEASE_DIR"
[[ -n "$BUILD_NUMBER" ]] || fail "Could not determine app build number from $RELEASE_DIR"

APP_NAME="${APP_NAME:-Caffeinate}"
TAG="${TAG:-${RELEASE_TAG:-v${VERSION}-${BUILD_NUMBER}}}"
TITLE="${TITLE:-${RELEASE_TITLE:-${APP_NAME} ${VERSION} (${BUILD_NUMBER})}}"

if [[ -n "$NOTES" && -n "$NOTES_FILE" ]]; then
  fail "Use either --notes or --notes-file, not both."
fi

if [[ -n "$NOTES_FILE" && $GENERATE_NOTES_SET -eq 0 ]]; then
  GENERATE_NOTES=0
fi

[[ -n "$NOTES_FILE" ]] && [[ -f "$NOTES_FILE" ]] || [[ -z "$NOTES_FILE" ]] || fail "Notes file not found: $NOTES_FILE"

if [[ $DRY_RUN -eq 1 ]]; then
  cat <<EOF
Release directory: $RELEASE_DIR
Tag:               $TAG
Title:             $TITLE
Target ref:        $TARGET_REF
Artifact zip:      $FINAL_ZIP
Checksum:          $CHECKSUM_PATH
Generate notes:    $GENERATE_NOTES
Draft:             $DRAFT
Prerelease:        $PRERELEASE
Repo override:     ${REPO:-<default>}
EOF
  exit 0
fi

require_command gh
require_command git
require_command plutil

git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Not inside a git work tree: $REPO_ROOT"
TARGET_SHA="$(git -C "$REPO_ROOT" rev-parse "${TARGET_REF}^{commit}")"

REMOTE_TAG_EXISTS=0
if git -C "$REPO_ROOT" ls-remote --exit-code --tags origin "refs/tags/${TAG}" >/dev/null 2>&1; then
  REMOTE_TAG_EXISTS=1
fi

LOCAL_TAG_SHA=""
if git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/tags/${TAG}" >/dev/null; then
  LOCAL_TAG_SHA="$(git -C "$REPO_ROOT" rev-list -n 1 "$TAG")"
fi

if [[ $REMOTE_TAG_EXISTS -eq 0 ]]; then
  if [[ -n "$LOCAL_TAG_SHA" && "$LOCAL_TAG_SHA" != "$TARGET_SHA" ]]; then
    fail "Local tag ${TAG} already exists at ${LOCAL_TAG_SHA}, not ${TARGET_SHA}."
  fi

  if [[ -z "$LOCAL_TAG_SHA" ]]; then
    log "Creating annotated tag ${TAG} at ${TARGET_SHA}"
    git -C "$REPO_ROOT" tag -a "$TAG" "$TARGET_SHA" -m "$TITLE"
  else
    log "Using existing local tag ${TAG}"
  fi

  log "Pushing tag ${TAG} to origin"
  git -C "$REPO_ROOT" push origin "refs/tags/${TAG}"
else
  log "Using existing remote tag ${TAG}"
fi

GH_CMD=(
  gh
  release
  create
  "$TAG"
  "$FINAL_ZIP"
  "$CHECKSUM_PATH"
  --verify-tag
  --title "$TITLE"
)

if [[ -n "$REPO" ]]; then
  GH_CMD+=(-R "$REPO")
fi

if [[ $GENERATE_NOTES -eq 1 ]]; then
  GH_CMD+=(--generate-notes)
fi

if [[ -n "$NOTES" ]]; then
  GH_CMD+=(--notes "$NOTES")
fi

if [[ -n "$NOTES_FILE" ]]; then
  GH_CMD+=(--notes-file "$NOTES_FILE")
fi

if [[ $DRAFT -eq 1 ]]; then
  GH_CMD+=(--draft)
fi

if [[ $PRERELEASE -eq 1 ]]; then
  GH_CMD+=(--prerelease)
fi

if [[ $FAIL_ON_NO_COMMITS -eq 1 ]]; then
  GH_CMD+=(--fail-on-no-commits)
fi

log "Creating GitHub Release ${TAG}"
"${GH_CMD[@]}"
