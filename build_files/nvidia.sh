#!/usr/bin/env bash
set -eux
if [ "$VARIANT" = "nvidia" ];then
FEDORA_VERSION="$(rpm -E %fedora)"
DNF_OPTS="--setopt=tsflags=nodocs --setopt=install_weak_deps=False"
dnf5 -y install --refresh $DNF_OPTS --allowerasing \
"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VERSION.noarch.rpm" \
"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VERSION.noarch.rpm"
dnf5 remove -y '*nvidia*'||true
dnf5 -y install --refresh $DNF_OPTS --allowerasing --best \
kernel-devel-matched \
akmod-nvidia \
xorg-x11-drv-nvidia-cuda
akmods --force --kernels "$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')"
dnf5 remove -y rpmfusion-free-release rpmfusion-nonfree-release
dnf5 clean all
fi
