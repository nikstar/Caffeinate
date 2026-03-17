#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: set-version.sh [options] [version]

Updates the app marketing version and/or build number in Info.plist.

Options:
  --plist PATH      Info.plist path. Default: ./Caffeinate/Info.plist
  --version VALUE   Set CFBundleShortVersionString explicitly.
  --build NUMBER    Set CFBundleVersion explicitly.
  --major           Increment the major version and reset the build number to 1.
  --minor           Increment the minor version and reset the build number to 1.
  --patch           Increment the patch version and reset the build number to 1.
  --bump-build      Increment the build number by 1.
  --reset-build     Reset the build number to 1 after changing the marketing version.
  --print           Print the current version/build and exit.
  -h, --help        Show this help.

Examples:
  ./scripts/set-version.sh --print
  ./scripts/set-version.sh 1.1.0 --build 1
  ./scripts/set-version.sh --patch
  ./scripts/set-version.sh --bump-build
EOF
}

fail() {
  echo "error: $*" >&2
  exit 1
}

PLIST_BUDDY="/usr/libexec/PlistBuddy"

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

plist_read() {
  "$PLIST_BUDDY" -c "Print :$1" "$PLIST_PATH" 2>/dev/null
}

plist_write() {
  local key="$1"
  local value="$2"

  if "$PLIST_BUDDY" -c "Print :${key}" "$PLIST_PATH" >/dev/null 2>&1; then
    "$PLIST_BUDDY" -c "Set :${key} ${value}" "$PLIST_PATH" >/dev/null
  else
    "$PLIST_BUDDY" -c "Add :${key} string ${value}" "$PLIST_PATH" >/dev/null
  fi
}

parse_version() {
  local version="$1"

  [[ "$version" =~ ^([0-9]+)(\.([0-9]+))?(\.([0-9]+))?$ ]] || fail "Unsupported version format: $version"

  VERSION_MAJOR="${BASH_REMATCH[1]}"
  VERSION_MINOR="${BASH_REMATCH[3]:-0}"
  VERSION_PATCH="${BASH_REMATCH[5]:-0}"
}

PLIST_PATH=""
EXPLICIT_VERSION=""
EXPLICIT_BUILD=""
VERSION_BUMP=""
BUMP_BUILD=0
RESET_BUILD=0
PRINT_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plist)
      PLIST_PATH="$2"
      shift 2
      ;;
    --version)
      EXPLICIT_VERSION="$2"
      shift 2
      ;;
    --build)
      EXPLICIT_BUILD="$2"
      shift 2
      ;;
    --major|--minor|--patch)
      [[ -z "$VERSION_BUMP" ]] || fail "Choose only one of --major, --minor, or --patch."
      VERSION_BUMP="${1#--}"
      shift
      ;;
    --bump-build)
      BUMP_BUILD=1
      shift
      ;;
    --reset-build)
      RESET_BUILD=1
      shift
      ;;
    --print)
      PRINT_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      fail "Unknown argument: $1"
      ;;
    *)
      [[ -z "$EXPLICIT_VERSION" ]] || fail "Version specified more than once."
      EXPLICIT_VERSION="$1"
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PLIST_PATH="${PLIST_PATH:-${REPO_ROOT}/Caffeinate/Info.plist}"

[[ -f "$PLIST_PATH" ]] || fail "Info.plist not found: $PLIST_PATH"
[[ -x "$PLIST_BUDDY" ]] || fail "Missing required tool: $PLIST_BUDDY"

CURRENT_VERSION="$(plist_read CFBundleShortVersionString)"
CURRENT_BUILD="$(plist_read CFBundleVersion)"

[[ "$CURRENT_VERSION" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || fail "Current CFBundleShortVersionString is not numeric: $CURRENT_VERSION"
[[ "$CURRENT_BUILD" =~ ^[0-9]+$ ]] || fail "Current CFBundleVersion is not numeric: $CURRENT_BUILD"

if [[ $PRINT_ONLY -eq 1 ]]; then
  if [[ -n "$EXPLICIT_VERSION" || -n "$EXPLICIT_BUILD" || -n "$VERSION_BUMP" || $BUMP_BUILD -eq 1 || $RESET_BUILD -eq 1 ]]; then
    fail "--print cannot be combined with version changes."
  fi

  cat <<EOF
Marketing version: $CURRENT_VERSION
Build number:      $CURRENT_BUILD
Plist:             $PLIST_PATH
EOF
  exit 0
fi

if [[ -n "$VERSION_BUMP" && -n "$EXPLICIT_VERSION" ]]; then
  fail "Use either an explicit version or a bump flag, not both."
fi

NEW_VERSION="$CURRENT_VERSION"
NEW_BUILD="$CURRENT_BUILD"

if [[ -n "$EXPLICIT_VERSION" ]]; then
  [[ "$EXPLICIT_VERSION" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || fail "Unsupported version format: $EXPLICIT_VERSION"
  NEW_VERSION="$EXPLICIT_VERSION"
fi

if [[ -n "$VERSION_BUMP" ]]; then
  parse_version "$CURRENT_VERSION"

  case "$VERSION_BUMP" in
    major)
      NEW_VERSION="$((VERSION_MAJOR + 1)).0.0"
      ;;
    minor)
      NEW_VERSION="${VERSION_MAJOR}.$((VERSION_MINOR + 1)).0"
      ;;
    patch)
      NEW_VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.$((VERSION_PATCH + 1))"
      ;;
  esac

  RESET_BUILD=1
fi

if [[ -n "$EXPLICIT_BUILD" && $BUMP_BUILD -eq 1 ]]; then
  fail "Use either --build or --bump-build, not both."
fi

if [[ -n "$EXPLICIT_BUILD" ]]; then
  [[ "$EXPLICIT_BUILD" =~ ^[1-9][0-9]*$ ]] || fail "Build number must be a positive integer."
  NEW_BUILD="$EXPLICIT_BUILD"
elif [[ $BUMP_BUILD -eq 1 ]]; then
  NEW_BUILD="$((CURRENT_BUILD + 1))"
elif [[ $RESET_BUILD -eq 1 && "$NEW_VERSION" != "$CURRENT_VERSION" ]]; then
  NEW_BUILD="1"
fi

if [[ "$NEW_VERSION" == "$CURRENT_VERSION" && "$NEW_BUILD" == "$CURRENT_BUILD" ]]; then
  fail "No version change requested."
fi

plist_write CFBundleShortVersionString "$NEW_VERSION"
plist_write CFBundleVersion "$NEW_BUILD"

cat <<EOF
Updated $PLIST_PATH
  Marketing version: $CURRENT_VERSION -> $NEW_VERSION
  Build number:      $CURRENT_BUILD -> $NEW_BUILD
EOF
