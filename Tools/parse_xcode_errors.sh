#!/bin/bash
set -euo pipefail

LOG_FILE="${1:-Docs/BuildLogs/build.log}"
ERROR_FILE="Docs/BuildLogs/Errors.md"

if [ ! -f "$LOG_FILE" ]; then
  echo "No build log found at $LOG_FILE"
  exit 1
fi

echo "# Build Errors" > "$ERROR_FILE"
echo "" >> "$ERROR_FILE"
echo "Generated: $(date)" >> "$ERROR_FILE"
echo "" >> "$ERROR_FILE"

# Extract errors
ERRORS=$(grep -E ":\d+:\d+: error:" "$LOG_FILE" 2>/dev/null | sort -u || true)
WARNINGS=$(grep -E ":\d+:\d+: warning:" "$LOG_FILE" 2>/dev/null | sort -u || true)

if [ -n "$ERRORS" ]; then
  echo "## Errors" >> "$ERROR_FILE"
  echo '```' >> "$ERROR_FILE"
  echo "$ERRORS" >> "$ERROR_FILE"
  echo '```' >> "$ERROR_FILE"
  echo "" >> "$ERROR_FILE"

  ERROR_COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')
  echo "Found $ERROR_COUNT error(s):"
  echo "$ERRORS"
else
  echo "No errors found."
fi

if [ -n "$WARNINGS" ]; then
  echo "## Warnings" >> "$ERROR_FILE"
  echo '```' >> "$ERROR_FILE"
  echo "$WARNINGS" >> "$ERROR_FILE"
  echo '```' >> "$ERROR_FILE"

  WARNING_COUNT=$(echo "$WARNINGS" | wc -l | tr -d ' ')
  echo ""
  echo "Found $WARNING_COUNT warning(s)."
fi

echo ""
echo "Error report saved to: $ERROR_FILE"
