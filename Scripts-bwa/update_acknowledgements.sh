#!/bin/sh
#
# Updates the list of third-party software licenses displayed in app settings.

set -euo pipefail

if [[ ! "$PATH" =~ "/opt/homebrew/bin" ]]; then
    PATH="/opt/homebrew/bin:$PATH"
fi

if [ "$CONFIGURATION" = "Debug" ]; then
    mint run LicensePlist license-plist \
        --config-path .license-plist-bwa.yml
fi
