#!/usr/bin/env bash
set -euxo pipefail
export FLATPAK_DISABLE_SANDBOX=1
dnf5 copr enable ublue/os-akmods
dnf5 copr disable ublue/os-akmods
dnf5 copr enable ublue-os/flatpak-test
dnf5 copr disable ublue-os/flatpak-test
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
flatpak --system remote-add --if-not-exists \
flathub https://dl.flathub.org/repo/flathub.flatpakrepo||true
flatpak update --appstream
mkdir -p /etc/flatpak/preinstall.d
if compgen -G "/ctx/custom/flatpaks/*.preinstall" >/dev/null;then
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/
fi
flatpak uninstall --unused --delete-data -y --noninteractive
flatpak repair
