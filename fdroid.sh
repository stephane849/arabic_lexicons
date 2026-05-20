#!/usr/bin/env bash

YELLOW='\033[1;33m'
RESET='\033[0m'

PS4="${YELLOW}+ ${RESET}"


set -euo pipefail

REQUIRED_FLUTTER_VERSION="3.44.0"

# Check if flutter exists
if ! command -v flutter &>/dev/null; then
    echo "Error: flutter not found in PATH" >&2
    exit 1
fi

# Get flutter version
FLUTTER_VERSION=$(flutter --version 2>/dev/null | awk 'NR==1 {print $2}')

if [[ "$FLUTTER_VERSION" != "$REQUIRED_FLUTTER_VERSION" ]]; then
    echo "Error: required Flutter $REQUIRED_FLUTTER_VERSION but found Flutter $FLUTTER_VERSION" >&2
    exit 1
fi

echo "Flutter $FLUTTER_VERSION found"


BUILD_DIR="/tmp/build"
OUT_DIR="build-fdroid"

cleanup() {
    set +x
    trap - INT TERM   # disable trap immediately
    echo "deleting $BUILD_DIR"
    rm -rf "$BUILD_DIR"
    kill 0
    exit 0
}

trap cleanup INT TERM

version=$(
    grep '^version:' pubspec.yaml \
    | head -n1 \
    | cut -d' ' -f2 \
    | cut -d'+' -f1
)

echo "Version: $version"

echo "Preparing temp build dir: $BUILD_DIR"

[ -d "$BUILD_DIR" ] && rm -rf "$BUILD_DIR"


set -x


mkdir "$BUILD_DIR"

cp -r android "$BUILD_DIR"
cp -r assets "$BUILD_DIR"
cp -r lib "$BUILD_DIR"
cp pubspec.lock "$BUILD_DIR"
cp pubspec.yaml "$BUILD_DIR"

# maybe not needed
cp analysis_options.yaml "$BUILD_DIR"
cp devtools_options.yaml "$BUILD_DIR"
cp flutter_launcher_icons.yaml "$BUILD_DIR"

cd "$BUILD_DIR"

export PUB_CACHE=$(pwd)/.pub-cache
export SOURCE_DATE_EPOCH=0

[ -d "$OLDPWD/$OUT_DIR" ] && rm -rf "$OLDPWD/$OUT_DIR"
mkdir -p "$OLDPWD/$OUT_DIR"

flutter clean
flutter pub get

sed -i -e 's/-Wl,/-Wl,--build-id=none,/' ${PUB_CACHE}/hosted/*/jni-*/src/CMakeLists.txt

# 1
flutter build apk \
    --release \
    --split-per-abi \
    --target-platform="android-arm" \
    --dart-define="APP_VERSION=$version" \
    --dart-define="APP_STORE=F-Droid"

cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
   "$OLDPWD/$OUT_DIR/"

# 2
flutter build apk \
    --release \
    --split-per-abi \
    --target-platform="android-arm64" \
    --dart-define="APP_VERSION=$version" \
    --dart-define="APP_STORE=F-Droid"


cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
   "$OLDPWD/$OUT_DIR/"

# 3
flutter build apk \
    --release \
    --split-per-abi \
    --target-platform="android-x64" \
    --dart-define="APP_VERSION=$version" \
    --dart-define="APP_STORE=F-Droid"

cp build/app/outputs/flutter-apk/app-x86_64-release.apk \
   "$OLDPWD/$OUT_DIR/"

echo "Done: APKs copied to $OLDPWD/$OUT_DIR/"
