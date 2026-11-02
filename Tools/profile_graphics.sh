#!/bin/bash
# Usage: Tools/profile_graphics.sh DEVICE_UDID OUTPUT_DIRECTORY
# Requires an unlocked physical device in Developer Mode, paired with this Mac.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
device_id="${1:?Provide physical device UDID}"
result_dir="${2:?Provide output directory}"
mkdir -p "$result_dir"
result_dir="$(cd "$result_dir" && pwd)"
derived_dir="$result_dir/build"
bundle_id=Gazza.SlingDuo.GraphicsProfile
xcodebuild -project "$repo_dir/Sling Duo.xcodeproj" -scheme 'Sling Duo' \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_dir" -allowProvisioningUpdates \
  PRODUCT_BUNDLE_IDENTIFIER="$bundle_id" SWIFT_ACTIVE_COMPILATION_CONDITIONS=GRAPHICS_PROFILE \
  CLANG_ENABLE_CODE_COVERAGE=NO build > "$result_dir/build.log" 2>&1
xcrun devicectl device install app --device "$device_id" \
  "$derived_dir/Build/Products/Release-iphoneos/Sling Duo.app" > "$result_dir/install.log" 2>&1
# Recording starts before app launch, preserving startup/upload spikes.
xcrun xctrace record --template 'Game Performance' --device "$device_id" \
  --all-processes --time-limit 110s --output "$result_dir/game-performance.trace" \
  > "$result_dir/instruments.log" 2>&1 &
trace_pid=$!
trap 'kill -INT "$trace_pid" 2>/dev/null || true' EXIT
for attempt in {1..30}; do
  if grep -qi 'recording started' "$result_dir/instruments.log"; then break; fi
  if ! kill -0 "$trace_pid" 2>/dev/null; then
    cat "$result_dir/instruments.log"
    exit 1
  fi
  sleep 1
done
if ! grep -qi 'recording started' "$result_dir/instruments.log"; then
  echo 'Instruments could not start; check device unlock, cable and trust status.' >&2
  exit 1
fi
xcrun devicectl device process launch --device "$device_id" --terminate-existing "$bundle_id" \
  > "$result_dir/launch.log" 2>&1
wait "$trace_pid"
trap - EXIT
xcrun devicectl device copy from --device "$device_id" \
  --domain-type appDataContainer --domain-identifier "$bundle_id" \
  --source Documents/graphics-profile.csv --destination "$result_dir/graphics-profile.csv"
xcrun xctrace export --input "$result_dir/game-performance.trace" --toc \
  --output "$result_dir/trace-toc.xml"
echo "Saved trace and CPU/footprint/frame samples in $result_dir"
