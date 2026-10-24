#!/bin/bash
#
# Simulates an Agent Access request push notification on a booted iOS Simulator.
#
# Usage: Scripts/simulate-agent-access-push.sh <fingerprint> <user-id> [device] [bundle-id]
#
#   fingerprint  The 64 character hex identity fingerprint of the recipient (the one the relay saw).
#   user-id      The ID of the user that owns the identity.
#   device       The ID of a simulator (from `xcrun simctl list`) or "booted" (default: $DEVICE or booted).
#   bundle-id    App bundle ID (default: $BUNDLE_ID or com.8bit.bitwarden).

set -euo pipefail

if [ $# -lt 2 ]; then
    sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi

FINGERPRINT="$1"
USER_ID="$2"
DEVICE="${3:-${DEVICE:-booted}}"
BUNDLE_ID="${4:-${BUNDLE_ID:-com.8bit.bitwarden}}"

PAYLOAD_FILE="$(mktemp -t agent-access-push).json"
trap 'rm -f "$PAYLOAD_FILE"' EXIT

# The simulator doesn't reliably deliver silent pushes (`content-available` only) to the app, so an
# `alert` is included to route it through `willPresent`. `data.payload` is a JSON *string*, `type` 30
# is `NotificationType.agentAccessRequest`, and `contextId` must differ from the app's own ID or the
# push is ignored as self-originated.
cat > "$PAYLOAD_FILE" <<PAYLOAD
{
  "aps": { "alert": { "title": "Simulated push", "body": "Agent access request" }, "content-available": 1 },
  "data": {
    "type": 30,
    "contextId": "simulated-other-device",
    "payload": "{\"Fingerprint\":\"$FINGERPRINT\",\"UserId\":\"$USER_ID\"}"
  }
}
PAYLOAD

xcrun simctl push "$DEVICE" "$BUNDLE_ID" "$PAYLOAD_FILE"
