#!/usr/bin/env bash
set -e

# Detect system architecture
ARCH=$(uname -m)

case "${ARCH}" in
    x86_64)
        NIX_RPM_URL="https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm"
        ;;
    aarch64|arm64)
        NIX_RPM_URL="https://nix-community.github.io/nix-installers/nix/aarch64/nix-multi-user-2.24.10.rpm"
        ;;
    *)
        echo "Error: Unsupported architecture '${ARCH}' for Nix installation." >&2
        exit 1
        ;;
esac

echo "Detected architecture: ${ARCH}. Installing Nix..."

# Install the Nix multi-user package
dnf5 install -y "${NIX_RPM_URL}"

# Move the default installation store into the persistent /var/nix tree
if [ -d /nix/store ]; then
    mkdir -p /var/nix
    mv /nix/* /var/nix/
fi
