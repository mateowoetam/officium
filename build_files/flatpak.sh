#!/usr/bin/env bash
set -euxo pipefail
export FLATPAK_DISABLE_SANDBOX=1
dnf -y install 'dnf5-command(config-manager)'
rm -rf /etc/yum.repos.d/_copr_ublue-os-akmods.repo
dnf5 copr enable -y ublue-os/akmods
dnf5 copr disable -y ublue-os/akmods||true
dnf5 copr enable -y ublue-os/packages
dnf5 copr disable -y ublue-os/packages||true
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install uupd ublue-os-udev-rules
dnf5 copr enable -y ublue-os/flatpak-test
dnf5 copr disable -y ublue-os/flatpak-test||true
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
flatpak --system remote-add --if-not-exists \
flathub https://dl.flathub.org/repo/flathub.flatpakrepo||true
flatpak update --appstream
flatpak uninstall --unused --delete-data -y --noninteractive
flatpak repair
