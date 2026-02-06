#!/usr/bin/env bash
set -euxo pipefail
FEDORA_VERSION="$(rpm -E %fedora)"
DNF_OPTS="--setopt=tsflags=nodocs --setopt=install_weak_deps=False"
dnf5 -y --refresh upgrade
dnf5 -y remove \
firefox htop nvtop kfind krfb kcharselect kde-connect \
kwalletmanager kdebugsettings plasma-discover okular fcitx5||true
dnf5 -y install \
"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VERSION.noarch.rpm" \
"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VERSION.noarch.rpm"
dnf5 -y install $DNF_OPTS \
libavcodec-freeworld \
VK_hdr_layer \
opendoas dash fish fastfetch gamescope \
wine alacritty thunderbird libjxl
curl -fsSL https://repo.librewolf.net/librewolf.repo \
-o /etc/yum.repos.d/librewolf.repo
dnf5 -y install $DNF_OPTS librewolf
rm -f /etc/yum.repos.d/librewolf.repo
curl -fsSL https://packages.freedom.press/yum-tools-prod/dangerzone/dangerzone.repo \
-o /etc/yum.repos.d/dangerzone.repo
dnf5 -y install $DNF_OPTS dangerzone
rm -f /etc/yum.repos.d/dangerzone.repo
