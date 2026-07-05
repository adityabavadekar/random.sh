#!/usr/bin/env bash
set -Eeuo pipefail

REPO="https://github.com/adityabavadekar/random.sh.git"
WORKDIR="${HOME}/.local/share/random.sh"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NUKE_OLD_NVIM=${NUKE:-false}

msg() {
  printf "\033[1;32m==>\033[0m %s\n" "$*"
}

die() {
  printf "\033[1;31mError:\033[0m %s\n" "$*" >&2
  exit 1
}

nuke_old_nvim() {
  rm -rf "$WORKDIR"
  rm -rf \
    ~/.config/nvim \
    ~/.local/share/nvim \
    ~/.local/state/nvim \
    ~/.cache/nvim
}

if [ "$NUKE_OLD_NVIM" = true ]; then
  msg "Nuking old Neovim configuration..."
  nuke_old_nvim
fi

command -v git >/dev/null 2>&1 || die "git is required"

msg "Installing dependencies..."

if command -v pacman >/dev/null 2>&1; then
  sudo pacman -Sy --needed --noconfirm \
    neovim \
    git \
    make \
    rust \
    go \
    python \
    unzip \
    nodejs \
    yarn \
    npm \
    ripgrep \
    tree-sitter \
    tree-sitter-cli \
    base-devel

elif command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y \
    neovim \
    git \
    make \
    rustc \
    cargo \
    golang-go \
    python3 \
    python3-pip \
    unzip \
    nodejs \
    npm \
    ripgrep \
    build-essential

  cargo install tree-sitter-cli
  sudo npm install -g yarn

else
  die "Unsupported package manager."
fi

msg "Downloading configuration..."

mkdir -p "$(dirname "$WORKDIR")"

if [ -d "$WORKDIR/.git" ]; then
  git -C "$WORKDIR" pull --ff-only
else
  rm -rf "$WORKDIR"
  git clone --depth=1 "$REPO" "$WORKDIR"
fi

msg "Installing Neovim configuration..."

mkdir -p "$(dirname "$NVIM_CONFIG")"
rm -rf "$NVIM_CONFIG"
cp -r "$WORKDIR/mini.nvim" "$NVIM_CONFIG"

msg "Deleting temporary files..."
rm -rf "$WORKDIR"

msg "Installing plugins..."

nvim --headless "+Lazy! sync" +qa || true

msg "Updating Mason..."
nvim --headless "+MasonUpdate" +qa || true

echo
echo "##"
echo " Neovim installed successfully!"
echo " Launch with: nvim"
echo "##"
