#!/bin/bash
set -euo pipefail

SCHEME="${1:-Qyra}"
DESTINATION="${2:-platform=iOS Simulator,name=iPhone 16 Pro,OS=latest}"
LOG_DIR="$(dirname "$0")/../Docs/BuildLogs"
LOG_FILE="$LOG_DIR/build.log"

mkdir -p "$LOG_DIR"

cd "$(dirname "$0")/.."

echo "=== Qyra Build ==="
echo "Scheme:      $SCHEME"
echo "Destination: $DESTINATION"
echo "Log:         $LOG_FILE"
echo ""

xcodebuild \
  -project MACRA.xcodeproj \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -configuration Debug \
  clean build 2>&1 | tee "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "=== BUILD FAILED ==="
  echo ""
  ./Tools/parse_xcode_errors.sh "$LOG_FILE"
  exit $EXIT_CODE
fi

echo ""
echo "=== BUILD SUCCEEDED ==="
