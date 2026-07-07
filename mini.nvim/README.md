# Neovim Configuration

## Prerequisites

The following dependencies must be installed before setup:

_(of course after installing neovim)_

- git
- make
- rust
- go
- python3
- unzip
- nodejs (npm included)
- ripgrep
- build tools (required for native compilation)

## Install Dependencies

### Arch Linux

```bash
sudo pacman -S --needed curl git make rust go python unzip nodejs yarn npm ripgrep fzf tree-sitter tree-sitter-cli base-devel nvim
```

### Ubuntu

```bash
sudo apt update && sudo apt install -y curl git make rustc cargo golang-go yarn python3 python3-pip unzip nodejs npm ripgrep fzf tree-sitter-cli build-essential
```

## Verify Installation

```bash
git --version
rustc --version
go version
python3 --version
node --version
yarn --version
rg --version
```

## Good themes

- catppuccin (best dark theme)
- randomhue
- retrobox
- mini\* (for clear light themes)
- ayu

## Resources

- [img-to-ascii](https://www.asciiart.eu/image-to-ascii)
