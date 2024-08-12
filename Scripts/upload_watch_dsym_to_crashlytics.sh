#!/bin/bash

set -euo pipefail

if [ "$CONFIGURATION" != "Debug" ]; then
    find "${DWARF_DSYM_FOLDER_PATH}" -name "*.dSYM" \
        -exec "${BUILD_DIR%Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" \
        -gsp "${PROJECT_DIR}/BitwardenWatchApp/GoogleService-Info.plist" \
        -p ios -- {} +
fi
