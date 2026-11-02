#!/bin/bash
# Usage: Tools/profile_graphics.sh DEVICE_UDID OUTPUT_DIRECTORY
# Requires an unlocked physical device in Developer Mode, paired with this Mac.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
device_id="${1:?Provide physical device UDID}"
result_dir="${2:?Provide output directory}"
mkdir -p "$result_dir"
result_dir="$(cd "$result_dir" && pwd)"
# Keep signed build products out of Documents/iCloud metadata propagation.
derived_dir="${SLING_PROFILE_DERIVED_DATA:-$(mktemp -d /private/tmp/sling-graphics-build.XXXXXX)}"
printf '%s\n' "$derived_dir" > "$result_dir/build-directory.txt"
bundle_id=Gazza.SlingDuo.GraphicsProfile
xcodebuild -project "$repo_dir/Sling Duo.xcodeproj" -scheme 'Sling Duo' \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_dir" -allowProvisioningUpdates \
  PRODUCT_BUNDLE_IDENTIFIER="$bundle_id" SWIFT_ACTIVE_COMPILATION_CONDITIONS=GRAPHICS_PROFILE \
  CLANG_ENABLE_CODE_COVERAGE=NO build > "$result_dir/build.log" 2>&1
xcrun devicectl device install app --device "$device_id" \
  "$derived_dir/Build/Products/Release-iphoneos/Sling Duo.app" > "$result_dir/install.log" 2>&1
# Launch by bundle ID: the production and profiling apps share a display name.
# xctrace prepares its instruments before launching the measured process.
xcrun xctrace record --template 'Metal System Trace' --device "$device_id" \
  --window 130s --time-limit 115s --output "$result_dir/metal-system.trace" \
  --launch -- "$bundle_id" > "$result_dir/instruments.log" 2>&1
xcrun devicectl device copy from --device "$device_id" \
  --domain-type appDataContainer --domain-identifier "$bundle_id" \
  --source Documents/graphics-profile.csv --destination "$result_dir/graphics-profile.csv"
python3 - "$result_dir/graphics-profile.csv" <<'PYVALIDATE'
import csv
import sys
rows = list(csv.DictReader(open(sys.argv[1])))
if len(rows) != 55 or rows[-1]['phase'] != 'released':
    raise SystemExit('Incomplete profile: expected two rounds and final release checkpoint')
if any(int(row['frames']) < 10 for row in rows[:-1]):
    raise SystemExit('Invalid profile: at least one phase did not render enough frames')
PYVALIDATE
xcrun xctrace export --input "$result_dir/metal-system.trace" --toc \
  --output "$result_dir/trace-toc.xml"
xcrun xctrace export --input "$result_dir/metal-system.trace" \
  --xpath '/trace-toc/run[@number="1"]/data/table[@schema="metal-gpu-intervals"]' \
  --output "$result_dir/trace-gpu.xml"
python3 "$repo_dir/Tools/summarize_gpu_trace.py" "${SLING_PROFILE_VARIANT:-measured}" \
  "$result_dir/trace" "$result_dir/graphics-profile.csv" "$result_dir"
echo "Saved validated GPU phase summaries, trace and CPU/footprint samples in $result_dir"
