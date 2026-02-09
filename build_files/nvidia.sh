#!/usr/bin/env bash
set -euxo pipefail
log_error(){ echo "ERROR: $1" >&2;}
if [ "$VARIANT" = "nvidia" ];then
FEDORA_VERSION="$(rpm -E %fedora)"
DNF_OPTS="--setopt=tsflags=nodocs --setopt=install_weak_deps=False"
if ! dnf5 -y install --refresh $DNF_OPTS "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VERSION.noarch.rpm";then
log_error "Failed to install RPM Fusion Free repository."
exit 1
fi
rpm -qa|grep -qi nvidia&&dnf5 remove -y '*nvidia*'||true
if ! dnf5 -y install --refresh $DNF_OPTS xorg-x11-drv-nouveau;then
log_error "Failed to install Nouveau driver."
exit 1
fi
rm -f /etc/modprobe.d/blacklist-nouveau.conf /etc/modprobe.d/blacklist-nvidia.conf
if ! dracut --force;then
log_error "Failed to update initramfs."
exit 1
fi
dnf5 clean all||true
fi
