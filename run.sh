#!/usr/bin/env bash
# Builds DeliveryDriver and launches it in the iPhone 15 Pro simulator.
set -euo pipefail

DEVICE_ID="A5D54B2B-518B-4C43-A565-0028C3CA95A3"
BUNDLE_ID="com.deliverydriver.app"
PROJECT="DeliveryDriver.xcodeproj"
SCHEME="DeliveryDriver"
BUILD_DIR="$(pwd)/.build/simulator"

echo "▶  Booting simulator..."
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
open -a Simulator

echo "▶  Building..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$DEVICE_ID" \
  -configuration Debug \
  -derivedDataPath "$BUILD_DIR" \
  build | xcpretty 2>/dev/null || \
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$DEVICE_ID" \
  -configuration Debug \
  -derivedDataPath "$BUILD_DIR" \
  build

echo "▶  Installing..."
APP_PATH=$(find "$BUILD_DIR" -name "DeliveryDriver.app" -not -path "*/dSYM/*" | head -1)
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "▶  Launching..."
xcrun simctl launch --console "$DEVICE_ID" "$BUNDLE_ID"
