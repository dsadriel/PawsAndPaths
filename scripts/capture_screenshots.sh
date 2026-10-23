#!/usr/bin/env bash
set -euo pipefail

UDID="013AA52D-2F42-407F-98B3-B8AB847612FF" # iPhone 17 Pro Max (6.9")
BUNDLE_ID="br.com.dsadriel.PawsAndPaths"
RAW_DIR="./screenshots/raw"
FRAMED_DIR="./screenshots/framed"

mkdir -p "$RAW_DIR" "$FRAMED_DIR"

echo "==> Booting simulator ($UDID)..."
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b

echo "==> Building Nonogram app for simulator..."
xcodebuild \
  -project "Nonogram.xcodeproj" \
  -scheme "Nonogram" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath ".build/DerivedData" \
  build CODE_SIGNING_ALLOWED=NO > /dev/null

APP_PATH=".build/DerivedData/Build/Products/Debug-iphonesimulator/Nonogram.app"

echo "==> Installing app on simulator..."
xcrun simctl install "$UDID" "$APP_PATH"

capture_screen() {
  local name="$1"
  shift
  local args=("$@")

  echo "==> Capturing $name with args: ${args[*]}..."
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "${args[@]}"
  sleep 1.8
  xcrun simctl io "$UDID" screenshot "$RAW_DIR/${name}.png"
}

capture_screen "01_journey_map" -screen map
capture_screen "02_puzzle_grid" -screen game -level 3
capture_screen "03_mascot_victory" -screen victory -level 3
capture_screen "04_hints_system" -screen hintOverlay -level 3

echo "==> Raw screenshots captured successfully in $RAW_DIR:"
ls -lh "$RAW_DIR"

echo "==> Framing screenshots with asc screenshots frame..."
for raw in "$RAW_DIR"/*.png; do
  asc screenshots frame \
    --input "$raw" \
    --output-dir "$FRAMED_DIR" \
    --device "iphone-17-pro-max" \
    --output json || true
done

echo "==> Framing complete! Framed screenshots:"
ls -lh "$FRAMED_DIR"
