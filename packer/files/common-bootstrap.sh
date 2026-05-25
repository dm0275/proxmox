#!/usr/bin/env bash
set -euo pipefail

echo "Installing base packages..."
packages=(
  software-properties-common
  git
  make
  zsh
  ca-certificates
  curl
)

sudo apt-get update
sudo apt-get install -y "${packages[@]}"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
fi

sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$HOME/.zshrc"

if [[ "$(basename "$SHELL")" != "zsh" ]]; then
  sudo chsh -s "$(which zsh)" "$(whoami)" || true
fi

echo "Common bootstrap complete."
