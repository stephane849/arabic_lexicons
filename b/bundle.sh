#!/bin/sh

source ./b/common.sh
source ./b/confirm.sh

set -ex

flutter build apk --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s) \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GIT_COMMIT_MSG="$gcm" \
  --dart-define=GPlay=true

cp 'build/app/outputs/bundle/release/app-release.aab' "${pre}.aab"
