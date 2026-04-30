#!/bin/sh

bd="build-release"
n="Arabic-Lexicons"
ver=$(grep 'version' pubspec.yaml | sed 's/version: //; s/+.*//')
# ver=$(grep 'version' pubspec.yaml | sed 's/version: //')
gc=$(git rev-parse --short HEAD)
gcm=$(git log -1 --pretty='%B' | tr '\n' ' ' | sed 's/^ *//; s/ *$//')

pre="$bd/$n"

[ -n "$ver" ] && pre="${pre}_v$ver"

if [ -d "$bd" ]; then
  printf "Delete $bd [Y/n] "
  read -r p
  if [ -z "$p" ] || [ "$p" = "y" ] || [ "$p" = "Y" ]; then
    printf "rm $bd\n\n"
    rm -r "$bd"
  else
    printf "Keeping $bd\n\n"
  fi
fi

[ ! -d "$bd" ] && mkdir "$bd"


set -ex

if [ "$1" = "b" ]; then
  flutter build appbundle --release \
    --dart-define=APP_VERSION="$ver" \
    --dart-define=BUILD_UNIX_TIME=$(date +%s) \
    --dart-define=GIT_COMMIT="$gc" \
    --dart-define=GIT_COMMIT_MSG="$gcm"

  cp 'build/app/outputs/bundle/release/app-release.aab' "${pre}.aab"
  [ "$2" != "c" ] && exit 0
fi

if [ "$1" = "s" ]; then
  flutter build apk --release --split-per-abi \
    --dart-define=APP_VERSION="$ver" \
    --dart-define=BUILD_UNIX_TIME=$(date +%s) \
    --dart-define=GIT_COMMIT="$gc" \
    --dart-define=GIT_COMMIT_MSG="$gcm" \
    --target-platform="android-arm64" \
    --no-tree-shake-icons

  cp 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' "${pre}_arm64-v8a.apk"
  exit 0
fi

if [ ! -z "$1" ] && [ "$1" != "b" ] && [ "$1" != "s" ] && [ "$1" != "x" ] ; then
  printf "Unknown command: $1\n"
  exit 1
fi

flutter build apk --release --split-per-abi \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s) \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GIT_COMMIT_MSG="$gcm"


cp 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' "${pre}_arm64-v8a.apk"
cp 'build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk' "${pre}_armeabi-v7a.apk"
cp 'build/app/outputs/flutter-apk/app-x86_64-release.apk' "${pre}_x86_64.apk"

flutter build apk --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s) \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GIT_COMMIT_MSG="$gcm"

cp 'build/app/outputs/flutter-apk/app-release.apk' "${pre}_universal.apk"
