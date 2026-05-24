#!/bin/sh

source ./common.sh

set -ex

flutter build linux --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s) \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GIT_COMMIT_MSG="$gcm"

dest="$HOME/.local/arabic_lexicons"

[ -d "$dest" ] && rm -r "$dest"

cp -r build/linux/x64/release/bundle "$dest"

cp assets/icons/icon.png "$dest"

sed "s/user/$(whoami)/" arabic_lexicons.desktop > ~/.local/share/applications/arabic_lexicons.desktop
