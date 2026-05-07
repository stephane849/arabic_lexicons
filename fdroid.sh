#!/usr/bin/env bash

set -euo pipefail

BUILD_DIR="/tmp/build"
OUT_DIR="build-fdroid"

cleanup() {
    rm -rf "$BUILD_DIR"
}

trap cleanup EXIT

version=$(
    grep '^version:' pubspec.yaml \
    | head -n1 \
    | cut -d' ' -f2 \
    | cut -d'+' -f1
)

echo "Version: $version"

echo "Preparing temp build dir: $BUILD_DIR"

[ -d "$BUILD_DIR" ] && rm -rf "$BUILD_DIR"

cp -r . "$BUILD_DIR"

cd "$BUILD_DIR"

flutter clean

flutter pub get

flutter build apk \
    --release \
    --split-per-abi \
    --dart-define="APP_VERSION=$version" \
    --dart-define="APP_STORE=F-Droid"

[ -d "$OLDPWD/$OUT_DIR" ] && rm -rf "$OLDPWD/$OUT_DIR"
mkdir -p "$OLDPWD/$OUT_DIR"

cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
   "$OLDPWD/$OUT_DIR/"

cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
   "$OLDPWD/$OUT_DIR/"

cp build/app/outputs/flutter-apk/app-x86_64-release.apk \
   "$OLDPWD/$OUT_DIR/"

echo "Done: APKs copied to $OLDPWD/$OUT_DIR/"
