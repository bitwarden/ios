#!/usr/bin/env bash
#
# Builds the Password Manager app and runs the end-to-end UI tests against a test server.
#
# Usage:
#
#   $ ./Scripts/run-e2e-tests.sh [--prepare-simulator] [--simulator-id <id>]
#
# Where:
#   - --prepare-simulator builds, installs the app and grants the notification permission, then
#     stops. Run it once per simulator before running the tests from Xcode.
#   - --simulator-id uses that simulator instead of the one in the .test-simulator-* files.
#
# The server under test is never named in this repository. The tests need these variables:
#   BW_TEST_SERVER_URL, BW_SEEDER_URL, BW_SEEDER_SELF_HOSTED, BW_SEEDER_USERNAME, BW_SEEDER_PASSWORD
# They must be exported in the environment; .e2e.env.example explains each one. This script
# doesn't read .e2e.env: that file is only for tests started from Xcode.
#
# Examples:
#   $ ./Scripts/run-e2e-tests.sh
#   $ ./Scripts/run-e2e-tests.sh --prepare-simulator

set -euo pipefail

SCHEME="BitwardenE2ETests"
DERIVED_DATA_PATH="build/DerivedData"
RESULT_BUNDLE_PATH="build/E2E.xcresult"
CONFIGURATION_VARIABLES=(
  BW_TEST_SERVER_URL
  BW_SEEDER_URL
  BW_SEEDER_SELF_HOSTED
  BW_SEEDER_USERNAME
  BW_SEEDER_PASSWORD
)

prepare_only=false
simulator_id=""

usage() {
  sed -n '3,21p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prepare-simulator)
      prepare_only=true
      shift
      ;;
    --simulator-id)
      simulator_id="${2:?Missing value for $1}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo >&2 "❌ Unknown argument: $1"
      usage >&2
      exit 1
      ;;
  esac
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$(dirname "$script_dir")"

if ! command -v applesimutils > /dev/null; then
  echo >&2 "❌ applesimutils is required to grant the notification permission."
  echo >&2 "   Install it with: brew install wix/brew/applesimutils"
  exit 1
fi

if [ "$prepare_only" = false ]; then
  for name in "${CONFIGURATION_VARIABLES[@]}"; do
    if [ -z "${!name:-}" ]; then
      echo >&2 "❌ $name isn't set. Export it before running this script (see .e2e.env.example)."
      exit 1
    fi
    # xcodebuild forwards TEST_RUNNER_-prefixed variables to the test runner without the prefix.
    export "TEST_RUNNER_$name=${!name}"
  done
fi

if [ -z "$simulator_id" ]; then
  device_name=$(tr -d '\n' < .test-simulator-device-name)
  ios_version=$(tr -d '\n' < .test-simulator-ios-version | cut -d. -f1,2)
  simulator_id=$(xcrun simctl list devices "iOS $ios_version" available \
    | grep "$device_name (" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || true)
  if [ -z "$simulator_id" ]; then
    echo >&2 "❌ No available simulator named '$device_name' on iOS $ios_version."
    exit 1
  fi
fi

echo "📱 Booting simulator $simulator_id"
xcrun simctl bootstatus "$simulator_id" -b > /dev/null

echo "🔨 Building $SCHEME"
xcrun xcodebuild build-for-testing \
  -workspace Bitwarden.xcworkspace \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  -quiet

app_path="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/Bitwarden.app"
bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app_path/Info.plist")

echo "📦 Installing $bundle_id"
# Uninstalling first makes sure a stale install can't pass for a clean start.
xcrun simctl uninstall "$simulator_id" "$bundle_id"
xcrun simctl install "$simulator_id" "$app_path"

echo "🔔 Granting the notification permission"
# simctl privacy has no notifications service. This restarts SpringBoard, so it must run before
# the tests start, never during them.
applesimutils --byId "$simulator_id" --bundle "$bundle_id" --setPermissions "notifications=YES"

section_info="$HOME/Library/Developer/CoreSimulator/Devices/$simulator_id/data/Library/BulletinBoard/VersionedSectionInfo.plist"
granted=false
# The simulator writes the permission asynchronously.
for _ in $(seq 1 30); do
  status=$(python3 - "$section_info" "$bundle_id" << 'EOF' || true
import plistlib
import sys

with open(sys.argv[1], "rb") as file:
    sections = plistlib.load(file)["sectionInfo"]
for value in plistlib.loads(sections[sys.argv[2]])["$objects"]:
    if isinstance(value, dict) and "authorizationStatus" in value:
        print(value["authorizationStatus"])
        break
EOF
  )
  if [ "$status" = "2" ]; then
    granted=true
    break
  fi
  sleep 1
done
if [ "$granted" = false ]; then
  echo >&2 "❌ The notification permission wasn't granted on simulator $simulator_id."
  exit 1
fi
xcrun simctl bootstatus "$simulator_id" > /dev/null

if [ "$prepare_only" = true ]; then
  echo "✅ Simulator $simulator_id is ready to run $SCHEME from Xcode."
  exit 0
fi

echo "🧪 Running $SCHEME"
rm -rf "$RESULT_BUNDLE_PATH"
# -collect-test-diagnostics never: on Xcode 27 / iOS 27 simulators, xcodebuild hangs 600s
# collecting simulator diagnostics after the tests finish.
xcrun xcodebuild test-without-building \
  -workspace Bitwarden.xcworkspace \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -resultBundlePath "$RESULT_BUNDLE_PATH" \
  -collect-test-diagnostics never
