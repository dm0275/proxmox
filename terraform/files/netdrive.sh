#!/usr/bin/env bash

# Exit script immediately if a command fails
set -e

# Default values for user and group ID
user_id=1000
group_id=1000
samba_dir="/etc/samba"

# Function to display usage
usage() {
    echo "Usage: $0 --source <smb_share> --target <mount_point> --username <smb_user> --password <smb_password> [--user_id <uid>] [--group_id <gid>]"
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            source="$2"
            shift 2
            ;;
        --target)
            target="$2"
            shift 2
            ;;
        --username)
            username="$2"
            shift 2
            ;;
        --password)
            password="$2"
            shift 2
            ;;
        --user_id)
            user_id="$2"
            shift 2
            ;;
        --group_id)
            group_id="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Ensure required arguments are provided
if [[ -z "$source" || -z "$target" || -z "$username" || -z "$password" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

# Install cifs-utils for mounting SMB shares
sudo apt install cifs-utils -y

# Create the target mount & samba directories if they doesn't exist
sudo mkdir -p "$target" "$samba_dir"

# Set ownership of the mount directory to the specified user and group
sudo chown -R "$user_id:$group_id" "$target"

# Create Samba credentials file
echo -e "username=$username\npassword=$password" | sudo tee $samba_dir/credentials > /dev/null

# Set correct permissions for the credentials file
sudo chmod 600 /etc/samba/credentials

# Add the SMB mount to /etc/fstab for automatic mounting
echo "$source $target cifs credentials=/etc/samba/credentials,uid=$user_id,gid=$group_id,iocharset=utf8,vers=3.0 0 0" | sudo tee -a /etc/fstab > /dev/null

# Reload systemd config
systemctl daemon-reload

# Mount all file systems listed in /etc/fstab
sudo mount -a

echo "SMB share successfully mounted at $target"
