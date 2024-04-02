#!/bin/sh
#
# Updates the list of third-party software licenses displayed in app settings.

set -euo pipefail

if [ "$CONFIGURATION" = "Debug" ]; then
    # Add the homebrew path for Apple silicon since it's not in Xcode's path.
    if [[ ! "$PATH" =~ "/opt/homebrew/bin" ]]; then
        PATH="/opt/homebrew/bin:$PATH"
    fi

    mint run LicensePlist license-plist \
        --config-path .license_plist.yml
fi
