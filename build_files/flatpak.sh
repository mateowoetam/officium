#!/usr/bin/env bash
set -euxo pipefail
export FLATPAK_DISABLE_SANDBOX=1
dnf -y install 'dnf5-command(config-manager)'
rm -rf /etc/yum.repos.d/_copr_ublue-os-akmods.repo
dnf5 copr enable ublue-os/akmods||true
dnf5 copr disable ublue-os/akmods||true
dnf5 copr enable ublue-os/packages||true
dnf5 copr disable ublue-os/packages||true
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install uupd ublue-os-udev-rules
dnf5 copr enable ublue-os/flatpak-test||true
dnf5 copr disable ublue-os/flatpak-test||true
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test flatpak-session-helper flatpak-session-helper
flatpak --system remote-add --if-not-exists \
flathub https://dl.flathub.org/repo/flathub.flatpakrepo||true
flatpak update --appstream
mkdir -p /etc/flatpak/preinstall.d
if compgen -G "/ctx/custom/flatpaks/*.preinstall" >/dev/null;then
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/
fi
flatpak uninstall --unused --delete-data -y --noninteractive
flatpak repair
