#!/usr/bin/env bash
set -euxo pipefail
export FLATPAK_DISABLE_SANDBOX=1
flatpak --system remote-add --if-not-exists \
flathub https://dl.flathub.org/repo/flathub.flatpakrepo||true
dnf5 copr enable copr.fedorainfracloud.org/ublue-os/packages
dnf5 install krunner-bazaar
dnf5 copr disable copr.fedorainfracloud.org/ublue-os/packages
dnf5 copr remove copr.fedorainfracloud.org/ublue-os/packages
mkdir -p /etc/flatpak/preinstall.d
if compgen -G "/ctx/custom/flatpaks/*.preinstall" >/dev/null;then
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/
fi
flatpak uninstall --unused --delete-data -y --noninteractive
flatpak repair
