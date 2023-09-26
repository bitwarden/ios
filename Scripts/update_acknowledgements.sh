#!/bin/sh
#
# Updates the list of third-party software licenses displayed in app settings.

set -euo pipefail

if [ "$CONFIGURATION" = "Debug" ]; then
    mint run LicensePlist license-plist \
        --config-path .license_plist.yml
fi
