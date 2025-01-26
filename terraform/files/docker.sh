#!/usr/bin/env bash

set -e

# Check if a username argument is provided
if [ -z "$1" ]; then
    echo "No username provided. Defaulting to the current user: $USER."
    exit 1
else
    target_user="$1"
    echo "Adding user '$target_user' to the Docker group."
fi

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create the Docker group if it doesn't exist
sudo groupadd docker 2>/dev/null || true

# Add the specified user to the Docker group
sudo usermod -aG docker "$target_user"

echo "User '$target_user' has been added to the Docker group. Please log out and log back in for the changes to take effect."
