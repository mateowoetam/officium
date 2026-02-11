#!/usr/bin/env bash
set -euxo pipefail
export FLATPAK_DISABLE_SANDBOX=1
dnf5 copr enable ublue-os/packages
dnf5 reinstall -y flatpak --allowerasing
dnf5 copr remove ublue-os/packages
flatpak --system remote-add --if-not-exists \
flathub https://dl.flathub.org/repo/flathub.flatpakrepo||true
mkdir -p /etc/flatpak/preinstall.d
if compgen -G "/ctx/custom/flatpaks/*.preinstall" >/dev/null;then
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/
fi
flatpak uninstall --unused --delete-data -y --noninteractive
flatpak repair
