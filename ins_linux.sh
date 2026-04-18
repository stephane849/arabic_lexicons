#!/bin/sh

set -ex

flutter build linux

dest="$HOME/.local/ara_dict"

[ -d "$dest" ] && rm -r "$dest"

# mkdir -p "$dest"

cp -r build/linux/x64/release/bundle "$dest"

cp assets/icons/icon.png "$dest"

sed "s/user/$(whoami)/" ara_dict.desktop > ~/.local/share/applications/ara_dict.desktop
