#!/usr/bin/env bash

set -e

# Install necessary packages
echo "Installing required packages..."
sudo apt update && sudo apt install -y software-properties-common git make zsh

# Clone Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Cloning Oh My Zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
else
    echo "Oh My Zsh is already installed. Skipping clone..."
fi

# Copy the default zshrc template if .zshrc doesn't exist
if [ ! -f "$HOME/.zshrc" ]; then
    echo "Copying default .zshrc..."
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
else
    echo ".zshrc already exists. Skipping copy..."
fi

# Set ZSH theme to "agnoster"
echo "Setting ZSH_THEME to agnoster..."
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc

# Change the default shell to Zsh
if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    echo "Changing default shell to Zsh..."
    sudo chsh -s "$(which zsh)" "$(whoami)"
    echo "Please log out and log back in to apply the new shell."
else
    echo "Zsh is already set as the default shell."
fi

echo "Installation complete!"
