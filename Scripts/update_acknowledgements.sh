#!/bin/sh
#
# Updates the list of third-party software licenses displayed in app settings.

set -euo pipefail

if [ "$CONFIGURATION" = "Debug" ]; then
    mint run LicensePlist license-plist \
        --output-path "$SRCROOT/$PRODUCT_NAME/Application/Support/Settings.bundle" \
        --prefix Acknowledgements
fi
