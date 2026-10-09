#!/bin/bash
#
# Simulates an agent fill approval request push notification on a booted iOS Simulator.
#
# Usage: Scripts/simulate-agent-fill-push.sh <approval-id> <user-id> [device] [bundle-id]
#
#   approval-id  The ID of the approval request (must exist on the server for the screen to load).
#   user-id      The ID of the user the approval belongs to.
#   device       The ID of a simulator (from `xcrun simctl list`) or "booted" (default: booted).
#   bundle-id    App bundle ID (default: com.8bit.bitwarden).

set -euo pipefail

if [ $# -lt 2 ]; then
    sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi

APPROVAL_ID="$1"
USER_ID="$2"
DEVICE="${3:-booted}"
BUNDLE_ID="${4:-com.8bit.bitwarden}"

PAYLOAD_FILE="$(mktemp -t agent-fill-push).json"
trap 'rm -f "$PAYLOAD_FILE"' EXIT

# The simulator doesn't reliably deliver silent pushes (`content-available` only) to the app, so an
# `alert` is included to route it through `willPresent`. The system banner is therefore shown in
# addition to the local notification the app creates itself.
# `data.payload` is a JSON *string*, `type` 28 is `NotificationType.agentFillApprovalRequest`, and
# `contextId` must differ from the app's own ID or the push is ignored as self-originated.
cat > "$PAYLOAD_FILE" <<EOF
{
  "aps": { "alert": { "title": "Simulated push", "body": "Agent fill approval request" }, "content-available": 1 },
  "data": {
    "type": 28,
    "contextId": "simulated-other-device",
    "payload": "{\"Id\":\"$APPROVAL_ID\",\"UserId\":\"$USER_ID\"}"
  }
}
EOF

xcrun simctl push "$DEVICE" "$BUNDLE_ID" "$PAYLOAD_FILE"
