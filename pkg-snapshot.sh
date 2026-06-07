#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles/docs"

PACMAN_OUT="$DOTFILES_DIR/installed_packages.txt"
YAY_OUT="$DOTFILES_DIR/installed_yay_packages.txt"

mkdir -p "$DOTFILES_DIR"

# Official repo packages
pacman -Qqe | sort >"$PACMAN_OUT"

# AUR packages
pacman -Qqem | sort >"$YAY_OUT"

echo "[ OK ] Saved official packages => $PACMAN_OUT"
echo "[ OK ] Saved AUR packages      => $YAY_OUT"
