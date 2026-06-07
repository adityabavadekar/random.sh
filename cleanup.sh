#!/usr/bin/env bash

# Cache Cleanup

set -euo pipefail

GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
RESET="\e[0m"

log() {
  echo -e "${BLUE}[ INFO ]${RESET} $1"
}

ok() {
  echo -e "${GREEN}[  OK  ]${RESET} $1"
}

warn() {
  echo -e "${YELLOW}[ WARN ]${RESET} $1"
}

err() {
  echo -e "${RED}[ ERR ]${RESET} $1"
}

size_before=$(df -h ~ | awk 'NR==2 {print $4}')

echo
echo -e "${GREEN} System Cleanup${RESET}"
echo

# Browser caches

log "Cleaning browser caches..."

rm -rf ~/.cache/chromium 2>/dev/null || true
rm -rf ~/.cache/google-chrome* 2>/dev/null || true
rm -rf ~/.cache/Google 2>/dev/null || true
rm -rf ~/.cache/mozilla 2>/dev/null || true
rm -rf ~/.cache/BraveSoftware 2>/dev/null || true

ok "Browser caches cleaned"

# General caches
log "Cleaning general caches..."

rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
rm -rf ~/.cache/mesa_shader_cache* 2>/dev/null || true
rm -rf ~/.cache/typescript 2>/dev/null || true
rm -rf ~/.cache/tracker3 2>/dev/null || true
rm -rf ~/.cache/ms-playwright* 2>/dev/null || true
rm -rf ~/.cache/node-gyp 2>/dev/null || true
rm -rf ~/.cache/pre-commit 2>/dev/null || true
rm -rf ~/.cache/prisma* 2>/dev/null || true
rm -rf ~/.cache/gopls 2>/dev/null || true
rm -rf ~/.cache/goimports 2>/dev/null || true
rm -rf ~/.cache/huggingface 2>/dev/null || true

ok "General caches cleaned"

# Python
log "Cleaning Python caches..."

find ~ -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

if command -v pip >/dev/null 2>&1; then
  pip cache purge || true
fi

if command -v uv >/dev/null 2>&1; then
  uv cache clean || true
  rm -rf ~/.cache/uv
fi

ok "Python caches cleaned"

# Node.js
log "Cleaning Node.js caches..."

if command -v npm >/dev/null 2>&1; then
  npm cache clean --force || true
fi

if command -v pnpm >/dev/null 2>&1; then
  pnpm store prune || true
fi

log "Removing node_modules directories..."

find ~ \
  -path '*/.*' -prune -o \
  -type d -name node_modules -prune -exec rm -rf '{}' + \
  2>/dev/null || true

ok "node_modules removed"

ok "Node.js caches cleaned"

# Go
log "Cleaning Go caches..."

if command -v go >/dev/null 2>&1; then
  go clean -cache -modcache -testcache || true
fi

ok "Go caches cleaned"

# Rust
# see: cargo install cargo-cache
log "Cleaning Rust caches..."

rm -rf ~/.cargo/registry/cache/* 2>/dev/null || true

ok "Rust caches cleaned"

# Gradle
log "Cleaning Gradle caches..."

rm -rf ~/.gradle/caches/* 2>/dev/null || true

ok "Gradle caches cleaned"

# Package managers
warn "sudo required: To clean system package caches run -"
echo -e "${YELLOW}  sudo paccache -rk2${RESET}"

# Baloo
if [ -d ~/.local/share/baloo ]; then
  log "Removing Baloo index..."
  rm -rf ~/.local/share/baloo
  ok "Baloo index removed"
fi

echo
log "Largest remaining files (>500MB):"

(find ~ -type f -size +500M -exec ls -lh {} \; 2>/dev/null || true) |
  awk '{ print $9 " -> " $5 }'

echo
size_after=$(df -h ~ | awk 'NR==2 {print $4}')
echo -e "${GREEN}[+] Cleanup Complete${RESET}"
echo
echo -e "${BLUE}Free space before:${RESET} $size_before"
echo -e "${BLUE}Free space after :${RESET} $size_after"
echo
