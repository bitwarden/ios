#!/bin/bash

# Builds the Agent Access SDK (ap-uniffi) for iOS, generates the Swift bindings and packages
# AgentAccessSdk/Frameworks/ap_uniffiFFI.xcframework.
#
# Usage: Scripts/build-agent-access-sdk.sh [--sim-only] [--device-only] [--debug]
#   AGENT_ACCESS_REPO  Path to the agent-access checkout.
#   DEVELOPER_DIR      Xcode developer directory (defaults to /Applications/Xcode.app if present).

set -euo pipefail

AGENT_ACCESS_REPO="${AGENT_ACCESS_REPO:-/Users/demo/Documents/development/bitwarden/agent-access}"
TOOLCHAIN="1.93"
SIM_TARGET="aarch64-apple-ios-sim"
DEVICE_TARGET="aarch64-apple-ios"
MIN_IOS="15.0"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$REPO_ROOT/AgentAccessSdk"
SWIFT_DEST="$PACKAGE_DIR/Sources/AgentAccessSdk/ap_uniffi.swift"
XCFRAMEWORK="$PACKAGE_DIR/Frameworks/ap_uniffiFFI.xcframework"

BUILD_SIM=1
BUILD_DEVICE=1
PROFILE="release"

for arg in "$@"; do
    case "$arg" in
        --sim-only) BUILD_DEVICE=0 ;;
        --device-only) BUILD_SIM=0 ;;
        --debug) PROFILE="debug" ;;
        -h | --help)
            sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

if [ "$BUILD_SIM" = 0 ] && [ "$BUILD_DEVICE" = 0 ]; then
    echo "--sim-only and --device-only are mutually exclusive" >&2
    exit 1
fi

if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
export PATH="$HOME/.cargo/bin:$PATH"

if [ ! -d "$AGENT_ACCESS_REPO/crates/ap-uniffi" ]; then
    echo "AGENT_ACCESS_REPO does not contain crates/ap-uniffi: $AGENT_ACCESS_REPO" >&2
    exit 1
fi

for tool in cargo rustup nm ld ar xcrun; do
    command -v "$tool" > /dev/null || {
        echo "Missing required tool: $tool" >&2
        exit 1
    }
done

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

TARGETS=()
[ "$BUILD_SIM" = 1 ] && TARGETS+=("$SIM_TARGET")
[ "$BUILD_DEVICE" = 1 ] && TARGETS+=("$DEVICE_TARGET")

echo "==> Checking Rust targets for toolchain $TOOLCHAIN"
INSTALLED_TARGETS="$(rustup target list --installed --toolchain "$TOOLCHAIN")"
for target in "${TARGETS[@]}"; do
    if ! grep -qx "$target" <<< "$INSTALLED_TARGETS"; then
        echo "Installing $target"
        rustup target add --toolchain "$TOOLCHAIN" "$target"
    fi
done

cd "$AGENT_ACCESS_REPO"
export CARGO_TARGET_DIR="$AGENT_ACCESS_REPO/target"

echo "==> Generating Swift bindings from a host build"
cargo +"$TOOLCHAIN" build -p ap-uniffi
HOST_LIB="$CARGO_TARGET_DIR/debug/libap_uniffi.dylib"
BINDINGS_DIR="$WORK_DIR/bindings"
mkdir -p "$BINDINGS_DIR"
cargo +"$TOOLCHAIN" run -q --bin uniffi-bindgen -- generate \
    --library "$HOST_LIB" --language swift --out-dir "$BINDINGS_DIR"

HEADERS_DIR="$PACKAGE_DIR/Sources/ap_uniffiFFI/include"
mkdir -p "$HEADERS_DIR"
cp "$BINDINGS_DIR/ap_uniffiFFI.h" "$HEADERS_DIR/ap_uniffiFFI.h"
SMOKE_HEADERS="$WORK_DIR/smoke-headers"
mkdir -p "$SMOKE_HEADERS"
cp "$BINDINGS_DIR/ap_uniffiFFI.h" "$SMOKE_HEADERS/ap_uniffiFFI.h"
cp "$BINDINGS_DIR/ap_uniffiFFI.modulemap" "$SMOKE_HEADERS/module.modulemap"
mkdir -p "$(dirname "$SWIFT_DEST")"
cp "$BINDINGS_DIR/ap_uniffi.swift" "$SWIFT_DEST"

build_slice() {
    local target="$1"
    local platform="$2"
    local slice_dir="$WORK_DIR/$target"
    mkdir -p "$slice_dir"

    echo "==> Building ap-uniffi for $target ($PROFILE)"
    local cargo_args=(+"$TOOLCHAIN" rustc -p ap-uniffi --lib --target "$target" --crate-type staticlib)
    if [ "$PROFILE" = "release" ]; then
        cargo_args+=(--release)
        CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo "${cargo_args[@]}"
    else
        cargo "${cargo_args[@]}"
    fi

    local lib="$CARGO_TARGET_DIR/$target/$PROFILE/libap_uniffi.a"
    [ -f "$lib" ] || {
        echo "Expected static library not found: $lib" >&2
        exit 1
    }

    echo "==> Hiding non-uniffi symbols for $target"
    nm -gU "$lib" > "$slice_dir/nm.txt" 2> /dev/null || true
    awk '$2=="T"||$2=="S"||$2=="D"||$2=="B"{print $3}' "$slice_dir/nm.txt" \
        | grep -E '^_(uniffi_|ffi_)' | sort -u > "$slice_dir/syms.txt" || true
    [ -s "$slice_dir/syms.txt" ] || {
        echo "No uniffi symbols found in $lib" >&2
        exit 1
    }

    ld -r -arch arm64 -platform_version "$platform" "$MIN_IOS" "$MIN_IOS" -all_load "$lib" \
        -exported_symbols_list "$slice_dir/syms.txt" -o "$slice_dir/merged.o"
    xcrun bitcode_strip -r "$slice_dir/merged.o" -o "$slice_dir/merged_nb.o" 2> /dev/null \
        || cp "$slice_dir/merged.o" "$slice_dir/merged_nb.o"

    local leaked
    nm -g "$slice_dir/merged_nb.o" > "$slice_dir/nm_merged.txt" 2> /dev/null || true
    leaked="$(grep -E ' [TDSB] ' "$slice_dir/nm_merged.txt" | grep -v -E '_(uniffi_|ffi_)' || true)"
    if [ -n "$leaked" ]; then
        echo "Symbol check failed for $target, non-uniffi symbols are still exported:" >&2
        echo "$leaked" | head -20 >&2
        exit 1
    fi
    nm "$slice_dir/merged_nb.o" > "$slice_dir/nm_all.txt" 2> /dev/null || true
    if grep rust_eh_personality "$slice_dir/nm_all.txt" | grep -qE ' [TDSB] '; then
        echo "Symbol check failed for $target, rust_eh_personality is exported" >&2
        exit 1
    fi

    rm -f "$slice_dir/libap_uniffi.a"
    ar rcs "$slice_dir/libap_uniffi.a" "$slice_dir/merged_nb.o"
    echo "    $target: $(du -h "$slice_dir/libap_uniffi.a" | cut -f1), $(wc -l < "$slice_dir/syms.txt" | tr -d ' ') exported symbols, symbol check passed"
}

XC_ARGS=()
if [ "$BUILD_SIM" = 1 ]; then
    build_slice "$SIM_TARGET" "ios-simulator"
    XC_ARGS+=(-library "$WORK_DIR/$SIM_TARGET/libap_uniffi.a")
fi
if [ "$BUILD_DEVICE" = 1 ]; then
    build_slice "$DEVICE_TARGET" "ios"
    XC_ARGS+=(-library "$WORK_DIR/$DEVICE_TARGET/libap_uniffi.a")
fi

if ! xcodebuild -version > /dev/null 2>&1; then
    echo "xcodebuild is unavailable, so the xcframework cannot be created. Install Xcode and set DEVELOPER_DIR." >&2
    echo "The static libraries were built and checked; rerun this script once Xcode is available." >&2
    exit 1
fi

echo "==> Creating xcframework"
rm -rf "$XCFRAMEWORK"
mkdir -p "$(dirname "$XCFRAMEWORK")"
xcodebuild -create-xcframework "${XC_ARGS[@]}" -output "$XCFRAMEWORK"

if [ "$BUILD_SIM" = 1 ] && xcrun --sdk iphonesimulator --show-sdk-path > /dev/null 2>&1; then
    echo "==> Smoke check against the simulator slice"
    SMOKE_DIR="$WORK_DIR/smoke"
    SLICE_DIR="$(find "$XCFRAMEWORK" -maxdepth 1 -type d -name 'ios-arm64*simulator' | head -1)"
    mkdir -p "$SMOKE_DIR"
    cp "$SWIFT_DEST" "$SMOKE_DIR/ap_uniffi.swift"
    echo 'print(type(of: UserClient.self))' > "$SMOKE_DIR/main.swift"
    xcrun --sdk iphonesimulator swiftc -swift-version 5 -target "arm64-apple-ios$MIN_IOS-simulator" \
        -I "$SMOKE_HEADERS" -Xcc -fmodule-map-file="$SMOKE_HEADERS/module.modulemap" \
        "$SMOKE_DIR/ap_uniffi.swift" "$SMOKE_DIR/main.swift" "$SLICE_DIR/libap_uniffi.a" \
        -framework Security -framework CoreFoundation -framework SystemConfiguration -lresolv \
        -o "$SMOKE_DIR/smoke"
    echo "    smoke binary linked"
else
    echo "==> Skipping smoke check (no iphonesimulator SDK or simulator slice not built)"
fi

echo "==> Done"
echo "    Swift bindings: $SWIFT_DEST"
echo "    XCFramework:    $XCFRAMEWORK"
echo "    Generated from agent-access commit $(git -C "$AGENT_ACCESS_REPO" rev-parse --short HEAD)"
