#!/usr/bin/env bash
set -e

# Create required directories for the bind mount
mkdir -p /var/nix
mkdir -p /nix

# Move the systemd unit file to the correct location
mv /tmp/nix.mount /etc/systemd/system/nix.mount

# Enable the native mount unit
systemctl enable nix.mount
