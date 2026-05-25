#!/bin/sh

source ./b/common.sh
source ./b/confirm.sh

echo "Starting build..."

set -ex

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

# linux
flutter build linux --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s) \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GIT_COMMIT_MSG="$gcm"


linux_zip="${n}_${ver}_linux.zip"
linux_dest="build/linux/x64/release/$linux_zip"

cp assets/icons/icon.png build/linux/x64/release/bundle/
cp arabic_lexicons.desktop build/linux/x64/release/bundle/

cd build/linux/x64/release/
  [ -d "arabic_lexicons" ] && rm -r "arabic_lexicons"
  mv bundle arabic_lexicons
  zip -r "$linux_zip" arabic_lexicons
cd -

mv "$linux_dest" "$bd"
